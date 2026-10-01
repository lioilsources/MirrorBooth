"""Validator v2 checks. The 24 shipped shaders are the regression baseline."""

from pathlib import Path

import pytest

import checks.compile as compile_mod
from checks.contract import check_contract, check_uniforms, uniform_shape
from checks.perf import check_perf
from config import SHADERS_DIR, settings
from tests.conftest import VALID_SHADER

APP_SHADERS = sorted(SHADERS_DIR.glob("*.frag"))
HEADER = "#include <flutter/runtime_effect.glsl>\n"


def _shader(
    uniforms: str, body: str = "fragColor = vec4(texture(uTexture, FlutterFragCoord().xy / uResolution).rgb, 1.0);"
):
    return f"{HEADER}{uniforms}\nout vec4 fragColor;\nvoid main() {{ {body} }}\n"


def test_app_shaders_present():
    assert len(APP_SHADERS) >= 24


@pytest.mark.parametrize("path", APP_SHADERS, ids=lambda p: p.name)
def test_app_shaders_pass_contract_and_perf(path: Path):
    code = path.read_text()
    assert check_contract(code) == []
    errors, _warnings, _summary = check_perf(code)
    assert errors == []
    assert uniform_shape(code) is not None


def test_uniform_shapes():
    base = "uniform sampler2D uTexture;\nuniform vec2 uResolution;\n"
    assert uniform_shape(_shader(base)) == (False, False)
    assert uniform_shape(_shader(base + "uniform float uTime;")) == (True, False)
    assert uniform_shape(_shader(base + "uniform vec2 uFaceCenter;\nuniform float uFaceScale;")) == (False, True)
    full = base + "uniform float uTime;\nuniform vec2 uFaceCenter;\nuniform float uFaceScale;"
    assert uniform_shape(_shader(full)) == (True, True)


@pytest.mark.parametrize(
    "uniforms",
    [
        "uniform vec2 uResolution;\nuniform sampler2D uTexture;",  # wrong order
        "uniform sampler2D uTexture;\nuniform vec2 uResolution;\nuniform vec2 uFaceCenter;\nuniform float uTime;",
        "uniform sampler2D uTexture;\nuniform vec2 uResolution;\nuniform vec2 uFaceCenter;",  # incomplete face pair
        "uniform sampler2D uTexture;\nuniform vec2 uResolution;\nuniform float uIntensity;",  # extra
        "uniform sampler2D uTexture;\nuniform sampler2D uNoise;\nuniform vec2 uResolution;",
    ],
)
def test_uniform_contract_violations(uniforms):
    assert any("contract order" in e for e in check_contract(_shader(uniforms)))


def test_flags_must_match_when_given():
    code = _shader("uniform sampler2D uTexture;\nuniform vec2 uResolution;\nuniform float uTime;")
    assert check_uniforms(code, needs_time=True, needs_face=False) == []
    assert check_uniforms(code, needs_time=False, needs_face=False)


@pytest.mark.parametrize(
    ("snippet", "label"),
    [
        ("float w = fwidth(uv.x);", "fwidth"),
        ("vec4 t = texelFetch(uTexture, ivec2(0), 0);", "texelFetch"),
        ("ivec2 s = textureSize(uTexture, 0);", "textureSize"),
        ("uint k = 3u;", "unsigned"),
        ("bool flag;", "bool"),
        ("vec4 t = texture(iChannel0, uv);", "iChannel"),
    ],
)
def test_forbidden_constructs(snippet, label):
    errors = check_contract(VALID_SHADER.replace("void main() {", "void main() {\n    " + snippet))
    assert any(label in e for e in errors), errors


def test_forbidden_in_comment_is_ignored():
    assert check_contract(VALID_SHADER + "\n// fwidth() is not supported\n") == []


def test_perf_budget():
    heavy = VALID_SHADER.replace(
        "vec3 col = texture(uTexture, uv).rgb;",
        "vec3 col = vec3(0.0);\n    for (int i = 0; i < 9; i++) { for (int j = 0; j < 9; j++) { col += texture(uTexture, uv).rgb; } }",
    )
    errors, _, summary = check_perf(heavy)
    assert summary["fetch_cost"] == 81
    assert any("texture fetches" in e for e in errors)
    deep = "void main(){ for(int a=0;a<2;a++){ for(int b=0;b<2;b++){ for(int c=0;c<2;c++){ } } } }"
    assert any("nested 3 deep" in e for e in check_perf(deep)[0])
    march = "float map(vec3 p){return 1.;}\nvoid main(){ for(int i=0;i<64;i++){ float d=map(p); t+=d; } }"
    errors, warnings, _ = check_perf(march)
    assert errors == [] and any("raymarch" in w for w in warnings)


def test_find_impellerc_layout(tmp_path):
    host = compile_mod._host_dirs()[0]
    binary = tmp_path / "bin" / "cache" / "artifacts" / "engine" / host / "impellerc"
    binary.parent.mkdir(parents=True)
    binary.write_text("")
    assert compile_mod.find_impellerc(str(tmp_path)) == binary
    assert compile_mod.find_impellerc("") is None


def test_no_compiler_is_unverified(monkeypatch):
    monkeypatch.setattr(compile_mod, "find_impellerc", lambda *_a, **_k: None)
    monkeypatch.setattr(compile_mod.shutil, "which", lambda _n: None)
    result = compile_mod.compile_shader(VALID_SHADER)
    assert result.ok and result.backend == "none" and not result.impeller_verified
    assert compile_mod.UNVERIFIED_WARNING in result.warnings[0]


def _impellerc_or_skip():
    if compile_mod.find_impellerc() is None:
        pytest.skip("FLUTTER_ROOT not set or impellerc missing")


@pytest.mark.flutter
@pytest.mark.parametrize("path", APP_SHADERS, ids=lambda p: p.name)
def test_app_shaders_compile_with_impellerc(path: Path, tmp_path):
    _impellerc_or_skip()
    result = compile_mod.compile_shader(path.read_text(), workdir=tmp_path)
    assert result.ok, result.errors
    assert result.impeller_verified and all(result.targets.values())


@pytest.mark.flutter
def test_impellerc_reports_errors_without_paths(tmp_path):
    _impellerc_or_skip()
    result = compile_mod.compile_shader(
        VALID_SHADER.replace("vec3 col", "vec3 col = undefinedThing;\n    vec3 col2"), workdir=tmp_path
    )
    assert not result.ok and result.errors
    assert all(str(tmp_path) not in e for e in result.errors)


@pytest.mark.flutter
def test_sksl_requirement_toggle(tmp_path, monkeypatch):
    _impellerc_or_skip()
    code = VALID_SHADER.replace("vec3 col = texture(uTexture, uv).rgb;", "vec3 col = vec3(fwidth(uv.x));")
    assert not compile_mod.compile_shader(code, workdir=tmp_path).ok
    monkeypatch.setattr(settings, "compile_require_sksl", False)
    relaxed = compile_mod.compile_shader(code, workdir=tmp_path)
    assert relaxed.ok and relaxed.targets["SkSL"] is False and relaxed.warnings
