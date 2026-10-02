"""
Register a generated shader in the MirrorBooth app.

Usage:
    python integrate.py --run-dir output/filter_hologram_<ts> \
        --enum-name hologram --label Holo --icon "◇" --collection art [--dry-run]

Steps:
  1. refuse runs with license_ok=false (no override), validation_passed=false or
     without impellerc verification (--force overrides only these two, loudly)
  2. copy the .frag to mirrorbooth/shaders/filter_<snake>.frag
  3. insert lines at the // @shadergen:* markers in mirror_filter.dart and
     # @shadergen:shaders in pubspec.yaml (idempotent: a second run changes nothing)
  4. flutter pub get && flutter analyze && flutter test — on failure every touched
     file is restored to its exact previous content (never git reset)
"""

from __future__ import annotations

import argparse
import difflib
import json
import re
import shutil
import subprocess
import sys
from collections.abc import Callable
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

from config import PROJECT_ROOT

APP_DIR = PROJECT_ROOT / "mirrorbooth"
COLLECTIONS = ("pretty", "ugly", "art", "fantasy")
FLUTTER_STEPS = (["flutter", "pub", "get"], ["flutter", "analyze"], ["flutter", "test"])


class IntegrationError(RuntimeError):
    pass


@dataclass
class Plan:
    """Planned file contents: path -> (old content or None if new, new content)."""

    files: dict[Path, tuple[str | None, str]] = field(default_factory=dict)

    @property
    def changed(self) -> dict[Path, tuple[str | None, str]]:
        return {p: (old, new) for p, (old, new) in self.files.items() if old != new}

    def diff(self, root: Path) -> str:
        out = []
        for path, (old, new) in self.changed.items():
            rel = path.relative_to(root) if path.is_relative_to(root) else path
            if path.suffix == ".frag":
                out.append(f"+++ {rel} (new shader, {len(new.splitlines())} lines)\n")
                continue
            out += difflib.unified_diff(
                (old or "").splitlines(keepends=True), new.splitlines(keepends=True), f"a/{rel}", f"b/{rel}"
            )
        return "".join(out)


# ---------------------------------------------------------------------------
# validation of inputs
# ---------------------------------------------------------------------------


def camel_to_snake(name: str) -> str:
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()


def check_names(enum_name: str, label: str, icon: str) -> None:
    if not re.fullmatch(r"[a-z][a-zA-Z0-9]*", enum_name):
        raise IntegrationError(f"--enum-name must be lowerCamelCase (e.g. hologram, neonEdge), got {enum_name!r}")
    if enum_name in {"none", "values", "index", "name"}:
        raise IntegrationError(f"--enum-name {enum_name!r} is reserved")
    if not label.strip() or len(label) > 8:
        raise IntegrationError("--label must be 1-8 characters (it sits under a small filter chip)")
    if not icon.strip() or len(icon) > 2:
        raise IntegrationError("--icon must be a single character/glyph")


def load_run(run_dir: Path) -> tuple[dict, dict, Path]:
    prov_path, val_path = run_dir / "provenance.json", run_dir / "validation.json"
    if not prov_path.exists() or not val_path.exists():
        raise IntegrationError(f"{run_dir} is not a ShaderGen run directory (provenance.json/validation.json missing)")
    provenance = json.loads(prov_path.read_text(encoding="utf-8"))
    validation = json.loads(val_path.read_text(encoding="utf-8"))
    frag = run_dir / provenance.get("frag", "")
    if not provenance.get("frag") or not frag.exists():
        frags = sorted(run_dir.glob("filter_*.frag"))
        if len(frags) != 1:
            raise IntegrationError(f"cannot find the generated .frag in {run_dir}")
        frag = frags[0]
    return provenance, validation, frag


def gate(provenance: dict, validation: dict, force: bool) -> list[str]:
    """Refusals and (with --force) warnings. License problems can never be forced."""
    if provenance.get("license_ok") is not True:
        raise IntegrationError(
            f"license_ok is not true (license: {provenance.get('license', 'unknown')}). Only permissively licensed "
            "ports or original generated shaders can ship — this check has no override."
        )
    problems = []
    if not validation.get("validation_passed"):
        problems.append("validation_passed=false (see validation.json)")
    if not (validation.get("compile") or provenance.get("compile") or {}).get("impeller_verified"):
        problems.append("shader was not compiled by impellerc (set FLUTTER_ROOT and re-run run.py)")
    if problems and not force:
        raise IntegrationError("refusing to integrate: " + "; ".join(problems) + " (--force overrides, not advised)")
    return [f"WARNING (--force): {p}" for p in problems]


# ---------------------------------------------------------------------------
# marker insertion
# ---------------------------------------------------------------------------


def _dart_str(text: str) -> str:
    return "'" + text.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$") + "'"


def _marker_index(lines: list[str], marker: str) -> int:
    hits = [i for i, ln in enumerate(lines) if ln.strip() == marker]
    if len(hits) != 1:
        raise IntegrationError(f"expected exactly one marker {marker!r}, found {len(hits)}")
    return hits[0]


def _region_start(lines: list[str], idx: int) -> int:
    """Start of the declaration that contains line ``idx`` (getter/enum header)."""
    for i in range(idx, -1, -1):
        if re.search(r"\b(?:get|enum)\b", lines[i]) and "@shadergen" not in lines[i]:
            return i
    return 0


def insert_before(lines: list[str], marker: str, new_line: str) -> list[str]:
    idx = _marker_index(lines, marker)
    region = lines[_region_start(lines, idx) : idx]
    if any(ln.strip() == new_line for ln in region):
        return lines  # already integrated
    indent = re.match(r"\s*", lines[idx]).group(0)
    out = lines[:idx] + [indent + new_line] + lines[idx:]
    return out


def insert_after(lines: list[str], marker: str, new_line: str) -> list[str]:
    idx = _marker_index(lines, marker)
    j = idx + 1
    while j < len(lines) and "=>" not in lines[j]:
        if lines[j].strip() == new_line:
            return lines
        j += 1
    indent = re.match(r"\s*", lines[idx]).group(0)
    return lines[: idx + 1] + [indent + new_line] + lines[idx + 1 :]


def insert_enum_member(lines: list[str], collection: str, enum_name: str) -> list[str]:
    marker = f"// @shadergen:enum:{collection}"
    idx = _marker_index(lines, marker)
    enum_start = _region_start(lines, idx)
    if any(ln.strip() == f"{enum_name}," for ln in lines[enum_start:idx]):
        return lines
    lines = list(lines)
    # `dart format` drops the trailing comma before a comment+`;`; make sure the previous member has one
    prev = idx - 1
    while prev > enum_start and (not lines[prev].strip() or lines[prev].strip().startswith("//")):
        prev -= 1
    if re.fullmatch(r"\s*\w+", lines[prev]):
        lines[prev] = lines[prev] + ","
    return insert_before(lines, marker, f"{enum_name},")


def plan_dart(
    source: str, enum_name: str, label: str, icon: str, collection: str, asset: str, needs_time: bool, needs_face: bool
) -> str:
    lines = source.split("\n")
    existing = re.search(rf"MirrorFilter\.{enum_name} => '([^']*\.frag)'", source)
    if existing and existing.group(1) != asset:
        raise IntegrationError(f"MirrorFilter.{enum_name} is already registered with {existing.group(1)}")
    member = f"MirrorFilter.{enum_name}"
    lines = insert_enum_member(lines, collection, enum_name)
    lines = insert_before(lines, "// @shadergen:label", f"{member} => {_dart_str(label)},")
    lines = insert_before(lines, "// @shadergen:icon", f"{member} => {_dart_str(icon)},")
    if needs_time:
        lines = insert_before(lines, "// @shadergen:needsTime", f"{member} => true,")
    if needs_face:
        lines = insert_before(lines, "// @shadergen:needsFace", f"{member} => true,")
    lines = insert_after(lines, f"// @shadergen:collection:{collection}", f"{member} ||")
    lines = insert_before(lines, "// @shadergen:shaderAsset", f"{member} => {_dart_str(asset)},")
    return "\n".join(lines)


def plan_pubspec(source: str, asset: str) -> str:
    lines = source.split("\n")
    marker = next((ln.strip() for ln in lines if ln.strip().startswith("# @shadergen:shaders")), None)
    if marker is None:
        raise IntegrationError("pubspec.yaml has no '# @shadergen:shaders' marker")
    if f"- {asset}" in (ln.strip() for ln in lines):
        return source
    idx = _marker_index(lines, marker)
    indent = re.match(r"\s*", lines[idx]).group(0)
    return "\n".join(lines[:idx] + [f"{indent}- {asset}"] + lines[idx:])


def build_plan(
    app_dir: Path, frag: Path, enum_name: str, label: str, icon: str, collection: str, provenance: dict
) -> Plan:
    snake = camel_to_snake(enum_name)
    asset = f"shaders/filter_{snake}.frag"
    dart_path = app_dir / "lib" / "core" / "mirror_filter.dart"
    pubspec_path = app_dir / "pubspec.yaml"
    target = app_dir / asset

    dart_src = dart_path.read_text(encoding="utf-8")
    check_names(enum_name, label, icon)
    shader = frag.read_text(encoding="utf-8")
    old_shader = target.read_text(encoding="utf-8") if target.exists() else None
    if old_shader is not None and old_shader != shader:
        raise IntegrationError(f"{asset} already exists with different content — pick another --enum-name")

    plan = Plan()
    plan.files[target] = (old_shader, shader)
    plan.files[dart_path] = (
        dart_src,
        plan_dart(
            dart_src,
            enum_name,
            label,
            icon,
            collection,
            asset,
            bool(provenance.get("needs_time")),
            bool(provenance.get("needs_face")),
        ),
    )
    pub_src = pubspec_path.read_text(encoding="utf-8")
    plan.files[pubspec_path] = (pub_src, plan_pubspec(pub_src, asset))
    return plan


# ---------------------------------------------------------------------------
# apply + verify
# ---------------------------------------------------------------------------


def run_flutter(app_dir: Path) -> tuple[bool, str]:
    if not shutil.which("flutter"):
        return False, "flutter not found on PATH"
    for cmd in FLUTTER_STEPS:
        print(f"[integrate] $ {' '.join(cmd)}")
        proc = subprocess.run(cmd, cwd=app_dir, capture_output=True, text=True)
        if proc.returncode != 0:
            return False, f"`{' '.join(cmd)}` failed:\n{(proc.stdout + proc.stderr)[-4000:]}"
    return True, ""


def apply_plan(plan: Plan) -> None:
    for path, (_old, new) in plan.changed.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(new, encoding="utf-8")


def restore(plan: Plan) -> None:
    for path, (old, _new) in plan.changed.items():
        if old is None:
            path.unlink(missing_ok=True)
        else:
            path.write_text(old, encoding="utf-8")


def integrate(
    run_dir: Path,
    enum_name: str,
    label: str,
    icon: str,
    collection: str,
    dry_run: bool = False,
    force: bool = False,
    app_dir: Path = APP_DIR,
    verify: Callable[[Path], tuple[bool, str]] = run_flutter,
) -> int:
    provenance, validation, frag = load_run(run_dir)
    for warning in gate(provenance, validation, force):
        print(warning)
    plan = build_plan(app_dir, frag, enum_name, label, icon, collection, provenance)

    if not plan.changed:
        print(f"[integrate] MirrorFilter.{enum_name} is already integrated — nothing to do.")
        return 0
    if dry_run:
        print(plan.diff(app_dir.parent) or "(no changes)")
        print("[integrate] dry run — nothing written")
        return 0

    apply_plan(plan)
    ok, log = verify(app_dir)
    if not ok:
        restore(plan)
        print(log)
        print("[integrate] FAILED — all touched files restored to their previous content.")
        return 1

    (run_dir / "integrated.json").write_text(
        json.dumps(
            {
                "enum_name": enum_name,
                "label": label,
                "icon": icon,
                "collection": collection,
                "asset": f"shaders/filter_{camel_to_snake(enum_name)}.frag",
                "integrated": datetime.now().isoformat(timespec="seconds"),
            },
            indent=2,
            ensure_ascii=False,
        )
        + "\n",
        encoding="utf-8",
    )
    print("\n" + "=" * 60)
    print(f"  Integrated MirrorFilter.{enum_name} ({label} {icon}) into collection '{collection}'")
    for path in plan.changed:
        print(f"  changed:  {path.relative_to(app_dir.parent)}")
    print("  flutter analyze + flutter test: green")
    print("=" * 60)
    print("\nReminder: a changed .frag needs a FULL RESTART of the app (hot reload does not recompile shaders).")
    print("Verify on a real device (FPS, orientation, face readability) before committing.")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Register a ShaderGen shader in the MirrorBooth app")
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--enum-name", required=True, help="lowerCamelCase MirrorFilter member, e.g. hologram")
    parser.add_argument("--label", required=True, help="chip label (<= 8 chars)")
    parser.add_argument("--icon", required=True, help="single glyph shown in the chip")
    parser.add_argument("--collection", required=True, choices=COLLECTIONS)
    parser.add_argument("--dry-run", action="store_true", help="show the diff, write nothing")
    parser.add_argument(
        "--force", action="store_true", help="integrate despite failed validation/impellerc (never license)"
    )
    args = parser.parse_args(argv)
    try:
        return integrate(args.run_dir, args.enum_name, args.label, args.icon, args.collection, args.dry_run, args.force)
    except IntegrationError as exc:
        print(f"[integrate] ERROR: {exc}")
        return 2


if __name__ == "__main__":
    sys.exit(main())
