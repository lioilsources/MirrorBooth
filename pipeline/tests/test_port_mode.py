"""Port mode end-to-end with a canned LLM: transpiler -> validator -> llm_fixer -> ranker."""

import json

import pytest

import agents.llm_fixer as llm_fixer
import agents.transpiler as transpiler
import run
from shadertoy.model import parse_shader
from shadertoy.transpile import transpile
from state import initial_state
from tests.shadertoy_factory import load_fixture

FIXTURE_IDS = {
    "stWebInv": "webcam_invert",
    "stFwidth": "fwidth_edges",
    "stNoLic": "nc_default",
    "stMulti": "multipass",
    "stPlasma": "procedural_plasma",
}


@pytest.fixture
def fixture_source(monkeypatch):
    def load(shader_id):
        return parse_shader(load_fixture(FIXTURE_IDS[shader_id]))

    monkeypatch.setattr(transpiler, "load_source_shader", load)
    return load


def _fixed_fwidth(code: str) -> str:
    return code.replace("float w = fwidth(d);", "float w = 8.0 * 1.5 / uResolution.y;")


def _port_state(shader_id, **source):
    return initial_state(f"port {shader_id}", {"kind": "shadertoy", "id": shader_id, **source})


def test_port_clean_shader_skips_fixer(offline_graph, fake_llm, fixture_source):
    final = offline_graph.build_graph().invoke(_port_state("stWebInv"))
    assert final["validation_passed"] is True
    assert final["category"] == "image_filter"
    assert final["needs_time"] is True and final["needs_face"] is False
    assert fake_llm.count("fixer") == 0 and fake_llm.count("architect") == 0 and fake_llm.count("coder") == 0
    assert fake_llm.count("ranker") == 1
    assert final["provenance"]["license_ok"] is True
    assert final["provenance"]["source"]["url"] == "https://www.shadertoy.com/view/stWebInv"


def test_port_fwidth_goes_through_fixer(offline_graph, fake_llm, fixture_source, tmp_path):
    state = _port_state("stFwidth")
    state["output_path"] = str(tmp_path)
    fixed = _fixed_fwidth(transpile(fixture_source("stFwidth")).code)
    fake_llm.responses["fixer"] = f"```glsl\n{fixed}\n```"
    final = offline_graph.build_graph().invoke(state)

    assert final["validation_passed"] is True
    assert fake_llm.count("fixer") == 1
    assert "fwidth" not in final["glsl_code"]
    assert final["fixes_needed"] == []
    patch = (tmp_path / "fixer_diff.patch").read_text()
    assert "-    float w = fwidth(d);" in patch and "+    float w = 8.0 * 1.5 / uResolution.y;" in patch
    # the fixer prompt enumerates exactly the derivative problem
    human = fake_llm.calls[[r for r, _ in fake_llm.calls].index("fixer")][1][1].content
    assert "dFdx/dFdy/fwidth" in human


def test_fixer_touching_protected_region_is_rejected(offline_graph, fake_llm, fixture_source):
    code = transpile(fixture_source("stFwidth")).code
    tampered = _fixed_fwidth(code).replace(
        "uniform vec2 uResolution;", "uniform vec2 uResolution;\nuniform float uExtra;"
    )
    fake_llm.responses["fixer"] = tampered
    final = offline_graph.build_graph().invoke(_port_state("stFwidth"))

    assert final["validation_passed"] is False
    rounds = final["provenance"]["fixer_rounds"]
    assert len(rounds) == 3 and not any(r["accepted"] for r in rounds)
    assert "uExtra" not in final["glsl_code"]


def test_fixer_unfixable_stops_loop(offline_graph, fake_llm, fixture_source):
    fake_llm.responses["fixer"] = "// UNFIXABLE: the effect is built on screen-space derivatives"
    final = offline_graph.build_graph().invoke(_port_state("stFwidth"))
    assert fake_llm.count("fixer") == 1
    assert final["validation_passed"] is False
    assert "UNFIXABLE" in final["provenance"]["unfixable"]


def test_check_protected_detects_main_change():
    code = transpile(parse_shader(load_fixture("webcam_invert"))).code
    assert llm_fixer.check_protected(code, code) == []
    changed = code.replace("fc.y = uResolution.y - fc.y;", "")
    assert any("entry point" in p for p in llm_fixer.check_protected(code, changed))


# --- CLI -----------------------------------------------------------------


@pytest.fixture
def out_dir(tmp_path, monkeypatch):
    monkeypatch.setattr(run, "OUTPUT_DIR", tmp_path)
    return tmp_path


def test_cli_port_success_writes_provenance(offline_graph, fake_llm, fixture_source, out_dir, capsys):
    rc = run.main(["--from-shadertoy", "stWebInv"])
    assert rc == 0
    (run_dir,) = list(out_dir.iterdir())
    assert run_dir.name.startswith("filter_webcam_invert_wave_")
    frag = (run_dir / "filter_webcam_invert_wave.frag").read_text()
    assert frag.startswith("// Ported from https://www.shadertoy.com/view/stWebInv")
    prov = json.loads((run_dir / "provenance.json").read_text())
    assert prov["license"] == "MIT" and prov["license_ok"] is True
    assert prov["category"] == "image_filter" and prov["needs_time"] is True
    assert prov["source"]["author"] == "alice"
    assert len(prov["source_sha256"]) == 64
    assert any("stSample" in t for t in prov["transformations"])


def test_cli_port_license_rejection_is_friendly(fixture_source, out_dir, capsys):
    rc = run.main(["--from-shadertoy", "stNoLic", "--name", "x"])
    out = capsys.readouterr().out
    assert rc == 2
    assert "Cannot port stNoLic" in out and "permissive" in out and "Traceback" not in out
    assert list(out_dir.iterdir()) == []


def test_cli_port_unsupported_rejection(fixture_source, out_dir, capsys):
    assert run.main(["--from-shadertoy", "stMulti"]) == 2
    assert "multi-pass" in capsys.readouterr().out


def test_cli_nc_override_marks_license_not_ok(offline_graph, fake_llm, fixture_source, out_dir, capsys):
    rc = run.main(["--from-shadertoy", "stNoLic", "--name", "nc", "--i-accept-nc-license"])
    assert rc == 0
    (run_dir,) = list(out_dir.iterdir())
    assert json.loads((run_dir / "provenance.json").read_text())["license_ok"] is False
    assert "local experiments only" in capsys.readouterr().out


def test_cli_blend_for_procedural(offline_graph, fake_llm, fixture_source, out_dir):
    assert run.main(["--from-shadertoy", "stPlasma", "--blend", "overlay", "--name", "plasma"]) == 0
    (run_dir,) = list(out_dir.iterdir())
    assert "return stOverlay(cam, fx);" in (run_dir / "filter_plasma.frag").read_text()
    assert json.loads((run_dir / "tech_spec.json").read_text())["blend_mode"] == "overlay"


def test_cli_style_still_requires_name():
    with pytest.raises(SystemExit):
        run.main(["--style", "x"])
