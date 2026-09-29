import pytest

import agents.validator as validator
from state import initial_state
from tests.conftest import INVALID_SHADER, VALID_SHADER


@pytest.fixture(autouse=True)
def _no_glslang(monkeypatch):
    monkeypatch.setattr(validator.shutil, "which", lambda _name: None)


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
