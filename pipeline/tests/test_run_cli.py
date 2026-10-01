import json

import pytest

import run
from tests.conftest import INVALID_SHADER


@pytest.fixture
def out_dir(tmp_path, monkeypatch):
    monkeypatch.setattr(run, "OUTPUT_DIR", tmp_path)
    return tmp_path


def _single_run_dir(out_dir):
    dirs = list(out_dir.iterdir())
    assert len(dirs) == 1
    return dirs[0]


def test_run_style_success(offline_graph, fake_llm, out_dir, capsys):
    rc = run.main(["--style", "oil painting warm palette", "--name", "Oil Warm"])
    assert rc == 0

    run_dir = _single_run_dir(out_dir)
    assert run_dir.name.startswith("filter_oil_warm_")
    assert (run_dir / "filter_oil_warm.frag").read_text().startswith("#include <flutter/runtime_effect.glsl>")
    assert json.loads((run_dir / "tech_spec.json").read_text())["effect_name"] == "Test FX"
    assert (
        json.loads((run_dir / "rank_report.json").read_text())["overall"] == 7.2
    )  # flutter_compliance capped at 5: no impellerc offline
    assert json.loads((run_dir / "validation.json").read_text())["validation_passed"] is True
    assert not (run_dir / "FAILED").exists()

    out = capsys.readouterr().out
    assert "Status:    PASSED" in out
    assert "Next step: copy filter_oil_warm.frag" in out


def test_run_style_failure_is_marked(offline_graph, fake_llm, out_dir, capsys):
    fake_llm.responses["coder"] = INVALID_SHADER
    rc = run.main(["--style", "broken", "--name", "broken"])
    assert rc == 1

    run_dir = _single_run_dir(out_dir)
    assert (run_dir / "FAILED").exists()
    assert "gl_FragCoord" in (run_dir / "FAILED").read_text()
    validation = json.loads((run_dir / "validation.json").read_text())
    assert validation["validation_passed"] is False
    assert validation["retry_count"] == 3
    # the (invalid) shader is still written for inspection
    assert (run_dir / "filter_broken.frag").exists()

    out = capsys.readouterr().out
    assert "FAILED" in out
    assert "Next step" not in out


def test_run_requires_style_and_name():
    with pytest.raises(SystemExit):
        run.main(["--name", "x"])
