"""Batch port mode: run the best harvest candidates, rank them, write a report.

    python run.py --batch output/harvest_<ts>/candidates.json --top 10

Only permissive, supported candidates are considered (harvest order = priority).
At most ``settings.batch_parallelism`` (default 2, local LLM) runs at a time.
Results land in output/batch_<ts>/ — one run directory per candidate plus
README.md (ranked table + previews) and results.json.
"""

from __future__ import annotations

import json
import threading
import traceback
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from pathlib import Path

from config import OUTPUT_DIR, settings


def select_candidates(candidates_path: Path, top: int) -> tuple[list[dict], list[dict]]:
    data = json.loads(candidates_path.read_text(encoding="utf-8"))
    candidates = data["candidates"] if isinstance(data, dict) else data
    portable, skipped = [], []
    for c in candidates:
        if not c.get("permissive"):
            skipped.append({**c, "status": "SKIPPED", "reason": f"license {c.get('license')}"})
        elif c.get("category") == "unsupported":
            skipped.append(
                {**c, "status": "SKIPPED", "reason": "unsupported: " + "; ".join(c.get("unsupported_reasons", []))}
            )
        else:
            portable.append(c)
    return portable[:top], skipped


_print_lock = threading.Lock()


def _log(msg: str) -> None:
    with _print_lock:
        print(msg, flush=True)


def run_candidate(candidate: dict, batch_dir: Path, blend: str | None) -> dict:
    """One port run; never raises (errors become a row in the report)."""
    from graph import build_graph
    from run import _preflight_port, port_state, save_outputs, slugify

    shader_id = candidate["id"]
    row = {
        "id": shader_id,
        "name": candidate.get("name", ""),
        "author": candidate.get("author", ""),
        "license": candidate.get("license", ""),
        "category": candidate.get("category", ""),
        "url": candidate.get("url", f"https://www.shadertoy.com/view/{shader_id}"),
    }
    error, st_name = _preflight_port(shader_id, blend, False)
    if error:
        return {**row, "status": "REJECTED", "reason": error}
    shader_name = slugify(st_name or shader_id)
    run_dir = batch_dir / f"filter_{shader_name}_{shader_id}"
    run_dir.mkdir(parents=True, exist_ok=True)
    state = port_state(shader_id, blend)
    state["output_path"] = str(run_dir)
    _log(f"[batch] start {shader_id} ({st_name})")
    try:
        final = build_graph().invoke(state)
        frag_path, passed = save_outputs(final, run_dir, shader_name)
    except Exception as exc:  # noqa: BLE001 - one bad shader must not stop the batch
        (run_dir / "ERROR.txt").write_text(traceback.format_exc(), encoding="utf-8")
        _log(f"[batch] {shader_id} crashed: {exc}")
        return {**row, "status": "ERROR", "reason": str(exc)[:300], "run_dir": run_dir.name}
    rank = final.get("rank_report", {})
    _log(f"[batch] done  {shader_id}: {'PASSED' if passed else 'FAILED'} overall={rank.get('overall', 'n/a')}")
    return {
        **row,
        "status": "PASSED" if passed else "FAILED",
        "overall": rank.get("overall"),
        "scores": rank.get("scores", {}),
        "reason": "; ".join(final.get("validation_errors", []))[:300],
        "run_dir": run_dir.name,
        "frag": frag_path.name,
        "previews": [Path(p).name for p in final.get("preview_paths", [])],
        "needs_time": final.get("needs_time", False),
        "needs_face": final.get("needs_face", False),
    }


def _sort_key(r: dict) -> tuple:
    status_rank = {"PASSED": 0, "FAILED": 1, "ERROR": 2, "REJECTED": 3, "SKIPPED": 4}
    overall = r.get("overall") if isinstance(r.get("overall"), (int, float)) else -1
    return (status_rank.get(r["status"], 9), -overall)


def _md(text) -> str:
    return str(text).replace("|", "\\|").replace("\n", " ")


def render_readme(results: list[dict], skipped: list[dict], meta: dict) -> str:
    passed = [r for r in results if r["status"] == "PASSED"]
    lines = [
        "# ShaderGen batch report",
        "",
        f"- Candidates file: `{meta['candidates']}`",
        f"- Generated: {meta['generated']}, top {meta['top']}, parallelism {meta['parallelism']}",
        f"- Runs: **{len(results)}**, passed: **{len(passed)}**",
        "",
        "Integrate a passed shader with the command in its row (choose label, icon and collection), then QA on a device.",
        "",
        "| # | Shader | Status | Overall | Category | License | Preview |",
        "|---|---|---|---|---|---|---|",
    ]
    for i, r in enumerate(results, 1):
        previews = (
            " ".join(f"![{r['id']} {p}]({r['run_dir']}/{p})" for p in r.get("previews", [])[:3])
            if r.get("run_dir")
            else ""
        )
        title = f"[{_md(r['name'])}]({r['url']}) by {_md(r['author'])}"
        status = (
            r["status"]
            if not r.get("reason") or r["status"] == "PASSED"
            else f"{r['status']}: {_md(r['reason'][:120])}"
        )
        lines.append(
            f"| {i} | {title} | {status} | {r.get('overall', '–')} | {r['category']} | {_md(r['license'])} | {previews} |"
        )
    if passed:
        lines += ["", "## Integrate", ""]
        for r in passed:
            lines.append(
                f"- `{r['id']}`: `python integrate.py --run-dir output/{meta['batch_dir']}/{r['run_dir']} "
                "--enum-name <camelCase> --label <Label> --icon <glyph> --collection art`"
            )
    if skipped:
        lines += ["", f"## Not run ({len(skipped)})", "", "| id | name | reason |", "|---|---|---|"]
        lines += [f"| `{s['id']}` | {_md(s.get('name', ''))} | {_md(s['reason'])} |" for s in skipped]
    return "\n".join(lines) + "\n"


def run_batch(candidates_path: Path, top: int = 10, blend: str | None = None, out_root: Path = OUTPUT_DIR) -> int:
    if not candidates_path.exists():
        print(f"[batch] {candidates_path} not found — run shadertoy/harvest.py first")
        return 2
    selected, skipped = select_candidates(candidates_path, top)
    if not selected:
        print("[batch] no portable candidates (permissive license + supported category) in that file")
        return 1
    batch_dir = out_root / f"batch_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    batch_dir.mkdir(parents=True, exist_ok=True)
    workers = max(1, settings.batch_parallelism)
    print(f"[batch] {len(selected)} candidate(s), {workers} at a time -> {batch_dir}")

    with ThreadPoolExecutor(max_workers=workers) as pool:
        results = list(pool.map(lambda c: run_candidate(c, batch_dir, blend), selected))
    results.sort(key=_sort_key)

    meta = {
        "candidates": str(candidates_path),
        "generated": datetime.now().isoformat(timespec="seconds"),
        "top": top,
        "parallelism": workers,
        "batch_dir": batch_dir.name,
    }
    (batch_dir / "results.json").write_text(
        json.dumps({**meta, "results": results, "skipped": skipped}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (batch_dir / "README.md").write_text(render_readme(results, skipped, meta), encoding="utf-8")
    passed = sum(1 for r in results if r["status"] == "PASSED")
    print(f"\n[batch] {passed}/{len(results)} passed — report: {batch_dir / 'README.md'}")
    return 0 if passed else 1
