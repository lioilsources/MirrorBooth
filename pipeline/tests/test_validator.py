import pytest

import agents.validator as validator
from state import initial_state
from tests.conftest import INVALID_SHADER, VALID_SHADER


@pytest.fixture(autouse=True)
def _no_compiler(monkeypatch):
    import checks.compile as compile_mod

    monkeypatch.setattr(compile_mod, "find_impellerc", lambda *_a, **_k: None)
    monkeypatch.setattr(compile_mod.shutil, "which", lambda _name: None)


def _state(code: str, retry_count: int = 0):
    s = initial_state("test")
    s["glsl_code"] = code
    s["retry_count"] = retry_count
    return s


def test_valid_shader_passes():
    out = validator.validator_node(_state(VALID_SHADER))
    assert out["validation_errors"] == []
    assert out["validation_passed"] is True
    assert out["retry_count"] == 0


def test_invalid_shader_fails_and_counts_retry():
    out = validator.validator_node(_state(INVALID_SHADER, retry_count=1))
    assert out["validation_passed"] is False
    assert out["retry_count"] == 2
    joined = " ".join(out["validation_errors"])
    assert "gl_FragCoord" in joined
    assert "runtime_effect.glsl" in joined


def test_version_directive_forbidden():
    out = validator.validator_node(_state("#version 300 es\n" + VALID_SHADER))
    assert out["validation_passed"] is False
    assert any("#version" in e for e in out["validation_errors"])


def test_empty_code_fails():
    out = validator.validator_node(_state(""))
    assert out["validation_passed"] is False


def test_inspire_mode_derives_flags_from_uniforms():
    code = VALID_SHADER.replace("uniform vec2 uResolution;", "uniform vec2 uResolution;\nuniform float uTime;")
    out = validator.validator_node(_state(code))
    assert out["validation_passed"] is True
    assert out["needs_time"] is True and out["needs_face"] is False


def test_port_mode_is_strict_about_flags():
    s = _state(VALID_SHADER)
    s["source"] = {"kind": "shadertoy", "id": "x"}
    s["needs_time"] = True
    out = validator.validator_node(s)
    assert out["validation_passed"] is False
    assert any("needs_time=True" in e or "contract order" in e for e in out["validation_errors"])


def test_unverified_compile_is_recorded():
    out = validator.validator_node(_state(VALID_SHADER))
    compile_info = out["provenance"]["compile"]
    assert compile_info["backend"] == "none" and compile_info["impeller_verified"] is False
    assert any("NOT compiled by Impeller" in w for w in out["provenance"]["validation_warnings"])
