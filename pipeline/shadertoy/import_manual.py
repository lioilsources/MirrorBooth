"""Promote manually-collected shaders into the harvest cache — no network.

Shadertoy rarely issues new API app keys in practice (``shadertoy/client.py``
docstring + decision A of the plan), and scraping the site is out of scope
(it sits behind a Cloudflare bot challenge; automating past that is a
security-control bypass, not a ToS nuance, so this tool never talks to
shadertoy.com). Instead, you browse shadertoy.com normally in your own
browser and save a shader two ways:

1. **Raw copy** — browser dev tools -> Network tab -> reload the page ->
   find the request whose response is the shader JSON -> "Copy response" ->
   paste into a file. That JSON is already the exact shape this pipeline's
   API client returns (``{"Shader": {...}}``); this tool just validates and
   relocates it.
2. **Template** — copy ``_TEMPLATE.json``, fill in the fields by hand from
   what you see on the page (id from the URL, author, the code from the
   editor, the license text from the description). Less effort than finding
   the right network request, slightly more typing.

Usage (from pipeline/):
    python shadertoy/import_manual.py shadertoy_manual/
    python shadertoy/import_manual.py shadertoy_manual/my_pick.json
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from config import PIPELINE_DIR, SHADERTOY_CACHE_DIR
from shadertoy.license import classify_shader
from shadertoy.model import Shader, parse_shader
from shadertoy.portability import classify

MANUAL_DIR = PIPELINE_DIR / "shadertoy_manual"
SKIP_NAMES = {"_TEMPLATE.json", "README.md"}


class ManualImportError(ValueError):
    pass


def _as_image_input(ctype: str, channel: int = 0) -> dict:
    return {"id": channel, "src": "", "ctype": ctype, "channel": channel, "sampler": {}}


def build_shader_payload(template: dict) -> dict:
    """Convert the minimal ``_TEMPLATE.json`` shape into Shadertoy's own API shape.

    Required: ``id``, ``code``. Everything else defaults to empty/zero, which
    is fine — ``license.py``/``portability.py`` only read ``code``,
    ``description`` and (for a channel-0 input) ``ctype``.
    """
    shader_id = str(template.get("id") or "").strip()
    code = template.get("code") or ""
    if not shader_id:
        raise ManualImportError('template is missing "id" (the part after /view/ in the Shadertoy URL)')
    if not code.strip():
        raise ManualImportError(f'template {shader_id!r} is missing "code"')

    inputs = []
    ctype = template.get("channel0_ctype") or template.get("ctype")
    if ctype:
        inputs.append(_as_image_input(ctype))

    passes = []
    if template.get("common"):
        passes.append({"type": "common", "name": "Common", "code": template["common"], "inputs": [], "outputs": []})
    passes.append({"type": "image", "name": "Image", "code": code, "inputs": inputs, "outputs": []})

    return {
        "ver": "0.1",
        "info": {
            "id": shader_id,
            "name": template.get("name", ""),
            "username": template.get("author", ""),
            # License text can go here verbatim (e.g. "MIT" or a pasted header) —
            # classify_shader() scans description + code comments the same way.
            "description": template.get("description") or template.get("license", ""),
            "tags": template.get("tags") or [],
            "likes": 0,
            "viewed": 0,
            "date": "",
        },
        "renderpass": passes,
    }


def load_shader(path: Path) -> Shader:
    """A raw ``{"Shader": {...}}`` file validates as-is; anything else is a template."""
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, dict) and "Shader" in data:
        return parse_shader(data)
    try:
        return parse_shader({"Shader": build_shader_payload(data)})
    except ManualImportError:
        raise
    except Exception as exc:  # malformed JSON shape, wrong types, ...
        raise ManualImportError(f"{path.name}: could not parse as a Shadertoy shader or template ({exc})") from exc


def write_to_cache(shader: Shader, cache_dir: Path = SHADERTOY_CACHE_DIR) -> Path:
    cache_dir.mkdir(parents=True, exist_ok=True)
    dest = cache_dir / f"{shader.id}.json"
    tmp = dest.with_suffix(".json.tmp")
    tmp.write_text(json.dumps({"Shader": shader.model_dump(mode="json")}, ensure_ascii=False), encoding="utf-8")
    tmp.replace(dest)  # same atomic-write pattern as shadertoy.client.ShadertoyClient.get_raw
    return dest


def import_one(path: Path, cache_dir: Path = SHADERTOY_CACHE_DIR) -> tuple[Shader, Path]:
    shader = load_shader(path)
    return shader, write_to_cache(shader, cache_dir)


def import_path(path: Path, cache_dir: Path = SHADERTOY_CACHE_DIR) -> list[tuple[Path, Shader | None, str | None]]:
    """Import one file or every ``*.json`` file in a directory (skipping the template/README).

    Returns ``(source_path, shader_or_None, error_or_None)`` per file so the
    CLI can report successes and failures without stopping at the first bad one.
    """
    files = [path] if path.is_file() else sorted(p for p in path.glob("*.json") if p.name not in SKIP_NAMES)
    results = []
    for file in files:
        try:
            shader, _dest = import_one(file, cache_dir)
            results.append((file, shader, None))
        except (ManualImportError, OSError, ValueError) as exc:
            results.append((file, None, str(exc)))
    return results


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "path", type=Path, nargs="?", default=MANUAL_DIR, help=f"file or directory (default: {MANUAL_DIR})"
    )
    parser.add_argument(
        "--cache-dir", type=Path, default=SHADERTOY_CACHE_DIR, help="where to write (default: the harvest cache)"
    )
    args = parser.parse_args(argv)

    if not args.path.exists():
        print(f"[import_manual] {args.path} does not exist")
        return 2

    results = import_path(args.path, cache_dir=args.cache_dir)
    if not results:
        print(f"[import_manual] no *.json files found in {args.path} (besides _TEMPLATE.json/README.md)")
        return 1

    ok = 0
    for source, shader, error in results:
        if error:
            print(f"[import_manual] FAILED  {source.name}: {error}")
            continue
        lic = classify_shader(shader)
        port = classify(shader)
        can_port = lic.permissive and port.category != "unsupported"
        print(
            f"[import_manual] cached  {source.name} -> {shader.id} "
            f"({shader.info.name!r} by {shader.info.username or 'unknown'}) "
            f"license={lic.license} category={port.category} port={'yes' if can_port else 'no'}"
        )
        ok += 1
    print(f"\n[import_manual] {ok}/{len(results)} imported into {args.cache_dir}")
    print("[import_manual] next: python shadertoy/harvest.py --from-cache")
    return 0 if ok == len(results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
