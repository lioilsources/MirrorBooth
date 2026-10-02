"""run.py --batch over harvest candidates (fixtures, fake LLM, no network)."""

import json
import threading
import time

import pytest

import agents.transpiler as transpiler
import batch
import run
from config import settings
from shadertoy import harvest as harvest_mod
from shadertoy.model import parse_shader
from tests.shadertoy_factory import FIXTURES, load_fixture


@pytest.fixture
def candidates(tmp_path, monkeypatch):
    by_id = {json.loads(p.read_text())["Shader"]["info"]["id"]: p.stem for p in FIXTURES.glob("*.json")}
    monkeypatch.setattr(transpiler, "load_source_shader", lambda sid: parse_shader(load_fixture(by_id[sid])))
    records = [harvest_mod.candidate_record(parse_shader(load_fixture(stem))) for stem in by_id.values()]
    records.sort(key=harvest_mod.sort_key)
    path = tmp_path / "candidates.json"
    path.write_text(json.dumps({"candidates": records}))
    return path


def test_select_candidates_filters_license_and_category(candidates):
    selected, skipped = batch.select_candidates(candidates, top=50)
    assert selected and all(c["permissive"] and c["category"] != "unsupported" for c in selected)
    reasons = {s["id"]: s["reason"] for s in skipped}
    assert reasons["stNoLic"].startswith("license") and reasons["stMulti"].startswith("unsupported")
    assert len(batch.select_candidates(candidates, top=2)[0]) == 2


def test_batch_runs_ranks_and_reports(offline_graph, fake_llm, candidates, tmp_path):
    fake_llm.responses["fixer"] = "// UNFIXABLE: derivatives are the effect"
    out = tmp_path / "out"
    rc = batch.run_batch(candidates, top=10, out_root=out)
    assert rc == 0
    (batch_dir,) = list(out.iterdir())
    data = json.loads((batch_dir / "results.json").read_text())
    results = data["results"]
    statuses = {r["id"]: r["status"] for r in results}
    assert statuses["stWebInv"] == "PASSED"
    assert statuses["stFwidth"] == "FAILED"  # fixer gave up
    assert [r["status"] for r in results] == sorted(
        (r["status"] for r in results), key=lambda s: ["PASSED", "FAILED", "ERROR", "REJECTED"].index(s)
    )
    for r in results:
        if r["status"] == "PASSED":
            assert (batch_dir / r["run_dir"] / r["frag"]).exists()
    readme = (batch_dir / "README.md").read_text()
    assert "# ShaderGen batch report" in readme and "## Integrate" in readme and "## Not run" in readme
    assert f"output/{batch_dir.name}/filter_webcam_invert_wave_stWebInv" in readme


def test_batch_parallelism_is_capped(offline_graph, fake_llm, candidates, tmp_path, monkeypatch):
    active, peak, lock = [0], [0], threading.Lock()
    real = batch.run_candidate

    def tracked(*a, **k):
        with lock:
            active[0] += 1
            peak[0] = max(peak[0], active[0])
        time.sleep(0.05)
        try:
            return real(*a, **k)
        finally:
            with lock:
                active[0] -= 1

    monkeypatch.setattr(batch, "run_candidate", tracked)
    monkeypatch.setattr(settings, "batch_parallelism", 2)
    batch.run_batch(candidates, top=10, out_root=tmp_path / "out")
    assert peak[0] == 2


def test_crash_in_one_run_does_not_stop_batch(offline_graph, fake_llm, candidates, tmp_path, monkeypatch):
    import graph as graph_mod

    real_build = graph_mod.build_graph

    class Exploding:
        def invoke(self, state):
            if state["source"]["id"] == "stPlasma":
                raise RuntimeError("boom")
            return real_build().invoke(state)

    monkeypatch.setattr(graph_mod, "build_graph", lambda: Exploding())
    batch.run_batch(candidates, top=10, out_root=tmp_path / "out")
    (batch_dir,) = list((tmp_path / "out").iterdir())
    results = {r["id"]: r for r in json.loads((batch_dir / "results.json").read_text())["results"]}
    assert results["stPlasma"]["status"] == "ERROR" and "boom" in results["stPlasma"]["reason"]
    assert (batch_dir / results["stPlasma"]["run_dir"] / "ERROR.txt").exists()
    assert results["stWebInv"]["status"] == "PASSED"


def test_cli_batch_dispatch(tmp_path, capsys):
    assert run.main(["--batch", str(tmp_path / "missing.json")]) == 2
    assert "harvest.py" in capsys.readouterr().out
