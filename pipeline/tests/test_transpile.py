"""Transpiler: golden outputs per contract-table row, uniform contract, rejections.

Regenerate goldens after an intended change:  UPDATE_GOLDEN=1 pytest tests/test_transpile.py
"""

import os
import re
from pathlib import Path

import pytest

from shadertoy.model import parse_shader
from shadertoy.transpile import FIX_DERIVATIVES, TranspileError, detect_fixes, rewrite_calls, transpile
from tests.shadertoy_factory import channel, load_fixture, shader_payload

GOLDEN = Path(__file__).parent / "golden" / "transpile"
PORTABLE = ["webcam_invert", "texture_screen", "common_tab", "procedural_plasma", "noise_texture", "fwidth_edges"]
REJECTED = ["multipass", "cubemap", "keyboard"]

UNIFORM_RE = re.compile(r"^\s*uniform\s+(\w+)\s+(\w+)\s*;", re.MULTILINE)


def expected_uniforms(needs_time: bool, needs_face: bool) -> list[tuple[str, str]]:
    u = [("sampler2D", "uTexture"), ("vec2", "uResolution")]
    if needs_time:
        u.append(("float", "uTime"))
    if needs_face:
        u += [("vec2", "uFaceCenter"), ("float", "uFaceScale")]
    return u


def _port(name, **kw):
    return transpile(parse_shader(load_fixture(name)), **kw)


@pytest.mark.parametrize("name", PORTABLE)
def test_golden(name):
    result = _port(name)
    path = GOLDEN / f"{name}.frag"
    if os.environ.get("UPDATE_GOLDEN"):
        path.write_text(result.code, encoding="utf-8")
    assert result.code == path.read_text(encoding="utf-8")


@pytest.mark.parametrize("name", PORTABLE)
def test_uniforms_in_contract_order_and_nothing_else(name):
    r = _port(name)
    assert UNIFORM_RE.findall(r.code) == expected_uniforms(r.needs_time, r.needs_face)
    assert "iChannel" not in re.sub(r"//[^\n]*", "", r.code)
    assert "#version" not in r.code and not re.search(r"^\s*precision\s", r.code, re.MULTILINE)
    assert r.code.index("// Ported from https://www.shadertoy.com/view/") == 0
    assert r.code.count("#include <flutter/runtime_effect.glsl>") == 1
    assert "out vec4 fragColor;" in r.code and "FlutterFragCoord()" in r.code


def test_flags_and_categories():
    assert (_port("webcam_invert").needs_time, _port("webcam_invert").needs_face) == (True, False)
    plasma = _port("procedural_plasma")
    assert plasma.needs_time and plasma.needs_face and plasma.category == "procedural"
    assert plasma.blend_mode == "screen"
    assert "#define iMouse vec4(uFaceCenter.x * uResolution.x, (1.0 - uFaceCenter.y) * uResolution.y" in plasma.code
    assert _port("noise_texture").category == "data_texture"
    assert "vec4 stNoiseTex(vec2 uv)" in _port("noise_texture").code
    assert _port("fwidth_edges").fixes_needed == [FIX_DERIVATIVES]
    assert _port("webcam_invert").fixes_needed == []


def test_texture_call_rewrites():
    code = _port("texture_screen").code
    # wrap=repeat -> fract(); 3-arg texture and textureLod -> 2-arg stSample
    assert "stSample(fract(uv + vec2(OFFSET, 0.0))).r" in code
    assert "stSample(fract(uv)).g" in code
    assert "textureLod" not in code


def test_texel_fetch_on_channel0_is_deterministic():
    shader = parse_shader(
        shader_payload(
            code="// MIT License\nvoid mainImage(out vec4 c, in vec2 f){ vec2 uv = f / iResolution.xy; "
            "c = texelFetch(iChannel0, ivec2(f), 0) + texture(iChannel0, uv); }",
            inputs=[channel("webcam")],
        )
    )
    r = transpile(shader)
    assert "stSample((vec2(ivec2(f)) + 0.5) / uResolution)" in r.code
    assert r.fixes_needed == []


def test_blend_mode_choice_and_validation():
    assert "return cam * fx;" in _port("procedural_plasma", blend_mode="multiply").code
    with pytest.raises(TranspileError, match="blend mode"):
        _port("procedural_plasma", blend_mode="dodge")


@pytest.mark.parametrize("name", REJECTED)
def test_unsupported_rejected(name):
    with pytest.raises(TranspileError, match="cannot be ported"):
        _port(name)


def test_non_permissive_rejected_unless_accepted():
    with pytest.raises(TranspileError, match="permissive"):
        _port("nc_default")
    r = _port("nc_default", allow_nc_license=True)
    assert "LICENSE NOT PERMISSIVE" in r.code
    assert r.license["permissive"] is False


def test_rewrite_calls_handles_nesting():
    code, n = rewrite_calls("a = f(g(1, 2), h(3));", "f", lambda name, args: f"F[{'|'.join(args)}]")
    assert code == "a = F[g(1, 2)|h(3)];" and n == 1


def test_detect_fixes_ignores_comments():
    assert detect_fixes("// fwidth(x) was here\nfloat a = 1.0;") == []
    assert detect_fixes("float w = fwidth(x);") == [FIX_DERIVATIVES]


@pytest.mark.flutter
@pytest.mark.parametrize("name", PORTABLE)
def test_goldens_compile_with_impellerc(name, tmp_path):
    from checks.compile import compile_shader, find_impellerc

    if find_impellerc() is None:
        pytest.skip("FLUTTER_ROOT / impellerc not available")
    r = _port(name)
    result = compile_shader(r.code, workdir=tmp_path)
    if name == "fwidth_edges":
        assert not result.ok and any("SkSL" in e for e in result.errors)
    else:
        assert result.ok, result.errors
