"""Harvest candidate shaders from Shadertoy and classify them.

Usage (from pipeline/):
    python shadertoy/harvest.py --query webcam --sort popular --num 50
    python shadertoy/harvest.py --query postprocessing --query filter --num 30 --tags postprocessing
    python shadertoy/harvest.py --from-cache            # re-classify everything already cached (offline)

Writes output/harvest_<ts>/harvest_report.md and candidates.json. Every shader
is cached in rag/shadertoy_cache/, so an interrupted harvest can simply be
re-run: already fetched shaders are not downloaded again.
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from config import OUTPUT_DIR, SHADERTOY_CACHE_DIR
from shadertoy.client import SORTS, MissingApiKeyError, ShadertoyClient, ShadertoyError, iter_cached
from shadertoy.license import classify_shader
from shadertoy.model import Shader
from shadertoy.portability import CATEGORY_PRIORITY, classify

RECOMMENDED_QUERIES = (
    "webcam",
    "postprocessing",
    "filter",
    "image",
    "cartoon",
    "pixel",
    "halftone",
    "kaleidoscope",
    "vhs",
    "thermal",
    "sketch",
)


def candidate_record(shader: Shader) -> dict:
    lic = classify_shader(shader)
    port = classify(shader)
    return {
        "id": shader.id,
        "name": shader.info.name,
        "author": shader.info.username,
        "url": shader.url,
        "tags": shader.info.tags,
        "likes": shader.info.likes,
        "viewed": shader.info.viewed,
        "license": lic.license,
        "permissive": lic.permissive,
        "license_evidence": lic.evidence,
        "license_reason": lic.reason,
        "category": port.category,
        "score": port.score,
        "issues": port.issues,
        "unsupported_reasons": port.unsupported_reasons,
        "uses_time": port.uses_time,
        "uses_mouse": port.uses_mouse,
    }


def sort_key(rec: dict) -> tuple:
    """Portable first: permissive, best category, highest score, most likes."""
    return (not rec["permissive"], CATEGORY_PRIORITY.get(rec["category"], 9), -rec["score"], -rec["likes"])


def _md_escape(text: str) -> str:
    return str(text).replace("|", "\\|").replace("\n", " ")


def render_report(records: list[dict], meta: dict) -> str:
    lic_counts = Counter(r["license"] for r in records)
    cat_counts = Counter(r["category"] for r in records)
    portable = [r for r in records if r["permissive"] and r["category"] != "unsupported"]

    lines = [
        "# Shadertoy harvest report",
        "",
        f"- Generated: {meta['generated']}",
        f"- Queries: {', '.join(meta['queries']) or '(cache)'} — sort `{meta['sort']}`, num {meta['num']}",
        f"- Shaders classified: **{len(records)}**, portable (permissive + supported): **{len(portable)}**",
    ]
    if meta.get("errors"):
        lines.append(f"- Errors: {len(meta['errors'])} (see candidates.json → `errors`)")
    lines += ["", "## Licenses", "", "| License | Count |", "|---|---|"]
    lines += [f"| {_md_escape(k)} | {v} |" for k, v in lic_counts.most_common()]
    lines += ["", "## Categories", "", "| Category | Count |", "|---|---|"]
    lines += [f"| {k} | {v} |" for k, v in cat_counts.most_common()]
    lines += [
        "",
        "## Shaders",
        "",
        "Only rows with **port = yes** may be used in port mode (`run.py --from-shadertoy <id>`). "
        "Everything else is RAG inspiration only (technique, not code).",
        "",
        "| id | name | author | license | port | category | score | issues | URL |",
        "|---|---|---|---|---|---|---|---|---|",
    ]
    for r in records:
        can_port = r["permissive"] and r["category"] != "unsupported"
        issues = "; ".join(r["unsupported_reasons"] or r["issues"])
        lines.append(
            f"| `{r['id']}` | {_md_escape(r['name'])} | {_md_escape(r['author'])} | {_md_escape(r['license'])} "
            f"| {'yes' if can_port else 'no'} | {r['category']} | {r['score']} | {_md_escape(issues)} | {r['url']} |"
        )
    return "\n".join(lines) + "\n"


def harvest(
    client: ShadertoyClient | None,
    queries: list[str],
    sort: str = "popular",
    num: int = 50,
    tags: list[str] | None = None,
    filters: list[str] | None = None,
    from_cache: bool = False,
    out_root: Path = OUTPUT_DIR,
    cache_dir: Path = SHADERTOY_CACHE_DIR,
) -> Path:
    errors: list[dict] = []
    shaders: dict[str, Shader] = {}

    if from_cache:
        for shader in iter_cached(cache_dir):
            shaders[shader.id] = shader
    else:
        assert client is not None
        ids: list[str] = []
        for query in queries:
            try:
                found = client.search(query, sort=sort, filter=filters, num=num)
            except MissingApiKeyError:
                raise
            except ShadertoyError as exc:
                errors.append({"query": query, "error": str(exc)})
                print(f"[harvest] query {query!r} failed: {exc}")
                continue
            print(f"[harvest] {query!r}: {len(found)} ids")
            ids += [i for i in found if i not in ids]
        for n, shader_id in enumerate(ids, 1):
            try:
                shaders[shader_id] = client.get(shader_id)
            except ShadertoyError as exc:
                errors.append({"id": shader_id, "error": str(exc)})
                print(f"[harvest] {shader_id} failed: {exc}")
                continue
            except KeyboardInterrupt:
                print(f"\n[harvest] interrupted after {n - 1}/{len(ids)} — re-run to continue (cache is kept)")
                break
            if n % 10 == 0:
                print(f"[harvest] fetched {n}/{len(ids)}")

    wanted_tags = {t.lower() for t in tags or []}
    records = []
    for shader in shaders.values():
        if wanted_tags and not wanted_tags & {t.lower() for t in shader.info.tags}:
            continue
        records.append(candidate_record(shader))
    records.sort(key=sort_key)

    run_dir = out_root / f"harvest_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    run_dir.mkdir(parents=True, exist_ok=True)
    meta = {
        "generated": datetime.now().isoformat(timespec="seconds"),
        "queries": queries,
        "sort": sort,
        "num": num,
        "tags": sorted(wanted_tags),
        "filters": filters or [],
        "errors": errors,
    }
    (run_dir / "candidates.json").write_text(
        json.dumps({**meta, "candidates": records}, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    (run_dir / "harvest_report.md").write_text(render_report(records, meta), encoding="utf-8")
    return run_dir


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Harvest + classify Shadertoy shaders")
    parser.add_argument(
        "--query",
        action="append",
        default=[],
        help=f"search term (repeatable); suggested: {', '.join(RECOMMENDED_QUERIES)}",
    )
    parser.add_argument("--sort", default="popular", choices=SORTS)
    parser.add_argument("--num", type=int, default=50, help="results per query")
    parser.add_argument("--tags", action="append", default=[], help="keep only shaders having one of these tags")
    parser.add_argument("--filter", action="append", default=[], help="Shadertoy API filter (e.g. webcam, multipass)")
    parser.add_argument("--from-cache", action="store_true", help="classify the local cache only (no network)")
    args = parser.parse_args(argv)

    if not args.query and not args.from_cache:
        parser.error("give at least one --query (or --from-cache)")

    try:
        client = None if args.from_cache else ShadertoyClient()
        run_dir = harvest(
            client,
            args.query,
            sort=args.sort,
            num=args.num,
            tags=args.tags,
            filters=args.filter,
            from_cache=args.from_cache,
        )
    except ShadertoyError as exc:
        print(f"[harvest] ERROR: {exc}")
        return 2

    data = json.loads((run_dir / "candidates.json").read_text(encoding="utf-8"))
    cands = data["candidates"]
    portable = sum(1 for c in cands if c["permissive"] and c["category"] != "unsupported")
    print(f"\n[harvest] {len(cands)} shaders classified, {portable} portable")
    if data["errors"]:
        print(f"[harvest] {len(data['errors'])} error(s) — see candidates.json")
    print(f"[harvest] report: {run_dir / 'harvest_report.md'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
