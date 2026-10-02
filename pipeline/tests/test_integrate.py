"""integrate.py on copies of the real app files (no flutter run; verify is injected)."""

import json
import shutil
import subprocess

import pytest

import integrate
from config import PROJECT_ROOT
from tests.conftest import VALID_SHADER

REAL_APP = PROJECT_ROOT / "mirrorbooth"
TIME_SHADER = VALID_SHADER.replace("uniform vec2 uResolution;", "uniform vec2 uResolution;\nuniform float uTime;")


@pytest.fixture
def app(tmp_path):
    app = tmp_path / "mirrorbooth"
    (app / "lib" / "core").mkdir(parents=True)
    (app / "shaders").mkdir()
    shutil.copy(REAL_APP / "lib" / "core" / "mirror_filter.dart", app / "lib" / "core" / "mirror_filter.dart")
    shutil.copy(REAL_APP / "pubspec.yaml", app / "pubspec.yaml")
    return app


def make_run(tmp_path, code=TIME_SHADER, **prov):
    run = tmp_path / "output" / "filter_holo_1"
    run.mkdir(parents=True)
    (run / "filter_holo.frag").write_text(code)
    provenance = {
        "frag": "filter_holo.frag",
        "license_ok": True,
        "license": "MIT",
        "needs_time": True,
        "needs_face": False,
    }
    provenance.update(prov)
    (run / "provenance.json").write_text(json.dumps(provenance))
    (run / "validation.json").write_text(
        json.dumps({"validation_passed": True, "compile": {"impeller_verified": True, "backend": "impellerc"}})
    )
    return run


def green(_app):
    return True, ""


def _run(app, run, **kw):
    args = dict(enum_name="hologram", label="Holo", icon="◇", collection="art", app_dir=app, verify=green)
    args.update(kw)
    return integrate.integrate(run, **args)


def test_integrates_all_marker_sites(app, tmp_path):
    run = make_run(tmp_path)
    assert _run(app, run) == 0
    dart = (app / "lib" / "core" / "mirror_filter.dart").read_text()
    assert "  popArt,\n  hologram,\n  // @shadergen:enum:art" in dart
    assert "        MirrorFilter.hologram => 'Holo',\n        // @shadergen:label" in dart
    assert "        MirrorFilter.hologram => '◇',\n        // @shadergen:icon" in dart
    assert "        MirrorFilter.hologram => true,\n        // @shadergen:needsTime" in dart
    assert "MirrorFilter.hologram => true,\n        // @shadergen:needsFace" not in dart
    assert (
        "        // @shadergen:collection:art\n        MirrorFilter.hologram ||\n        MirrorFilter.pencil ||" in dart
    )
    assert "        MirrorFilter.hologram => 'shaders/filter_hologram.frag',\n        // @shadergen:shaderAsset" in dart
    pubspec = (app / "pubspec.yaml").read_text()
    assert "    - shaders/filter_hologram.frag\n    # @shadergen:shaders" in pubspec
    assert (app / "shaders" / "filter_hologram.frag").read_text() == TIME_SHADER
    assert json.loads((run / "integrated.json").read_text())["collection"] == "art"


def test_second_run_changes_nothing(app, tmp_path, capsys):
    run = make_run(tmp_path)
    _run(app, run)
    before = {p: p.read_text() for p in app.rglob("*") if p.is_file()}
    assert _run(app, run) == 0
    assert "already integrated" in capsys.readouterr().out
    assert {p: p.read_text() for p in app.rglob("*") if p.is_file()} == before


def test_fantasy_member_after_dart_format_removed_comma(app, tmp_path):
    dart_path = app / "lib" / "core" / "mirror_filter.dart"
    dart_path.write_text(
        dart_path.read_text().replace(
            "  frozen,\n  // @shadergen:enum:fantasy", "  frozen\n  // @shadergen:enum:fantasy"
        )
    )
    assert _run(app, make_run(tmp_path, needs_face=True), collection="fantasy", enum_name="specter") == 0
    dart = dart_path.read_text()
    assert "  frozen,\n  specter,\n  // @shadergen:enum:fantasy\n  ;" in dart
    assert "MirrorFilter.specter => true,\n        // @shadergen:needsFace" in dart
    assert "// @shadergen:collection:fantasy\n        MirrorFilter.specter ||" in dart
    assert "MirrorFilter.specter => 'shaders/filter_specter.frag'" in dart


def test_camel_case_asset_name(app, tmp_path):
    _run(app, make_run(tmp_path), enum_name="neonEdge", label="Edge")
    assert (app / "shaders" / "filter_neon_edge.frag").exists()


def test_failed_verification_restores_everything(app, tmp_path, capsys):
    before = {p: p.read_text() for p in app.rglob("*") if p.is_file()}
    rc = _run(app, make_run(tmp_path), verify=lambda _a: (False, "flutter analyze: 1 issue"))
    assert rc == 1
    assert {p: p.read_text() for p in app.rglob("*") if p.is_file()} == before
    assert not (app / "shaders" / "filter_hologram.frag").exists()
    assert "restored" in capsys.readouterr().out


def test_dry_run_writes_nothing(app, tmp_path, capsys):
    before = {p: p.read_text() for p in app.rglob("*") if p.is_file()}
    assert _run(app, make_run(tmp_path), dry_run=True, verify=lambda _a: pytest.fail("must not run flutter")) == 0
    out = capsys.readouterr().out
    assert "+        MirrorFilter.hologram => 'Holo'," in out and "dry run" in out
    assert {p: p.read_text() for p in app.rglob("*") if p.is_file()} == before


def test_license_cannot_be_forced(app, tmp_path):
    run = make_run(tmp_path, license_ok=False, license="CC BY-NC-SA 3.0 (default)")
    with pytest.raises(integrate.IntegrationError, match="no override"):
        _run(app, run, force=True)


def test_failed_validation_needs_force(app, tmp_path, capsys):
    run = make_run(tmp_path)
    (run / "validation.json").write_text(json.dumps({"validation_passed": False, "compile": {}}))
    with pytest.raises(integrate.IntegrationError, match="refusing"):
        _run(app, run)
    assert _run(app, run, force=True) == 0
    assert "WARNING (--force)" in capsys.readouterr().out


def test_existing_asset_with_other_content_is_refused(app, tmp_path):
    (app / "shaders" / "filter_glow.frag").write_text("// the real glow shader")
    with pytest.raises(integrate.IntegrationError, match="already exists"):
        _run(app, make_run(tmp_path), enum_name="glow", label="Glow")


@pytest.mark.parametrize(
    ("kw", "msg"),
    [({"enum_name": "Holo"}, "lowerCamelCase"), ({"label": "Hologram FX"}, "label"), ({"icon": "abc"}, "icon")],
)
def test_bad_names(app, tmp_path, kw, msg):
    with pytest.raises(integrate.IntegrationError, match=msg):
        _run(app, make_run(tmp_path), **kw)


def test_cli_error_is_friendly(tmp_path, capsys):
    rc = integrate.main(
        ["--run-dir", str(tmp_path), "--enum-name", "x", "--label", "X", "--icon", "x", "--collection", "art"]
    )
    assert rc == 2 and "not a ShaderGen run directory" in capsys.readouterr().out


@pytest.mark.flutter
def test_real_flutter_roundtrip(tmp_path):
    """Full copy of the app: integrate a valid shader, flutter analyze + test must be green."""
    if not shutil.which("flutter"):
        pytest.skip("flutter not on PATH")
    app = tmp_path / "mirrorbooth"
    shutil.copytree(
        REAL_APP,
        app,
        ignore=shutil.ignore_patterns("build", ".dart_tool", "ios", "android", "macos", "windows", "linux", "web"),
    )
    rc = integrate.integrate(make_run(tmp_path), "hologram", "Holo", "◇", "art", app_dir=app)
    assert rc == 0
    out = subprocess.run(["flutter", "test", "test/shader_contract_test.dart"], cwd=app, capture_output=True, text=True)
    assert "hologram declares uniforms in contract order" in out.stdout
