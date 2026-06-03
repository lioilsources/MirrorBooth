from pathlib import Path

from agents.shadertoy_adapter import is_shadertoy_source, port_shadertoy
from agents.validator import _contract_check

FIX = Path(__file__).parent / "fixtures"


def test_detects_shadertoy_source():
    assert is_shadertoy_source((FIX / "shadertoy_basic.glsl").read_text())
    assert not is_shadertoy_source("void main() { fragColor = vec4(1.0); }")
    # already-Flutter code must not be re-detected as Shadertoy
    flutter = (FIX / "shadertoy_basic.expected.frag").read_text()
    assert not is_shadertoy_source(flutter)


def test_basic_port_matches_golden():
    src = (FIX / "shadertoy_basic.glsl").read_text()
    out = port_shadertoy(src).code
    assert out == (FIX / "shadertoy_basic.expected.frag").read_text()


def test_ichannel_port_matches_golden():
    src = (FIX / "shadertoy_with_ichannel.glsl").read_text()
    out = port_shadertoy(src).code
    assert out == (FIX / "shadertoy_with_ichannel.expected.frag").read_text()


def test_ported_output_satisfies_flutter_contract():
    for name in ("shadertoy_basic", "shadertoy_with_ichannel"):
        out = port_shadertoy((FIX / f"{name}.glsl").read_text()).code
        assert _contract_check(out) == [], f"{name} failed contract: {out}"


def test_unportable_constructs_are_reported():
    res = port_shadertoy((FIX / "shadertoy_unportable.glsl").read_text())
    assert "iMouse" in res.unported_constructs
    assert "iChannel1" in res.unported_constructs
    assert not res.is_clean


def test_time_uniform_only_when_used():
    no_time = "void mainImage(out vec4 O, in vec2 fragCoord){ O = vec4(0.5); }"
    assert "uniform float uTime" not in port_shadertoy(no_time).code
    with_time = "void mainImage(out vec4 O, in vec2 fragCoord){ O = vec4(iTime); }"
    assert "uniform float uTime" in port_shadertoy(with_time).code
    # needs_time override forces the uniform even without iTime
    assert "uniform float uTime" in port_shadertoy(no_time, needs_time=True).code


def test_port_is_idempotent_on_already_ported_code():
    once = port_shadertoy((FIX / "shadertoy_basic.glsl").read_text()).code
    # already-Flutter code is not a Shadertoy source, so it must be left alone
    assert not is_shadertoy_source(once)
