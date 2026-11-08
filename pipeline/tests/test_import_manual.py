"""shadertoy/import_manual.py — populate the cache without ever calling Shadertoy."""

import json

import pytest

from shadertoy import import_manual
from shadertoy.import_manual import ManualImportError, build_shader_payload, import_path, load_shader
from tests.shadertoy_factory import FIXTURES


def test_template_requires_id_and_code():
    with pytest.raises(ManualImportError, match='"id"'):
        build_shader_payload({"code": "void mainImage(out vec4 fragColor, in vec2 fragCoord) {}"})
    with pytest.raises(ManualImportError, match='"code"'):
        build_shader_payload({"id": "abc123"})


def test_template_becomes_a_valid_shader(tmp_path):
    template = {
        "id": "myPick1",
        "name": "My Pick",
        "author": "someone",
        "description": "SPDX-License-Identifier: MIT",
        "channel0_ctype": "webcam",
        "code": (
            "void mainImage(out vec4 fragColor, in vec2 fragCoord) {\n"
            "    vec2 uv = fragCoord / iResolution.xy;\n"
            "    fragColor = 1.0 - texture(iChannel0, uv);\n"
            "}\n"
        ),
    }
    path = tmp_path / "pick.json"
    path.write_text(json.dumps(template), encoding="utf-8")

    shader = load_shader(path)
    assert shader.id == "myPick1"
    assert shader.info.username == "someone"
    assert shader.image_pass.inputs[0].ctype == "webcam"
    assert "texture(iChannel0" in shader.image_pass.code


def test_raw_api_shaped_copy_passes_through(tmp_path):
    raw = json.loads((FIXTURES / "webcam_invert.json").read_text(encoding="utf-8"))
    path = tmp_path / "raw.json"
    path.write_text(json.dumps(raw), encoding="utf-8")

    shader = load_shader(path)
    assert shader.id == raw["Shader"]["info"]["id"]
    assert shader.image_pass.inputs[0].ctype == "webcam"


def test_malformed_file_reports_a_clear_error(tmp_path):
    path = tmp_path / "bad.json"
    path.write_text(json.dumps({"id": "x", "code": 123}))  # code must be a string
    with pytest.raises(ManualImportError, match="bad.json"):
        load_shader(path)


def test_import_path_writes_into_cache_and_skips_template_readme(tmp_path):
    src_dir = tmp_path / "manual"
    src_dir.mkdir()
    (src_dir / "pick.json").write_text(
        json.dumps(
            {
                "id": "myPick1",
                "code": "void mainImage(out vec4 fragColor, in vec2 fragCoord) { fragColor = vec4(1.0); }",
            }
        ),
        encoding="utf-8",
    )
    (src_dir / "_TEMPLATE.json").write_text("{}", encoding="utf-8")
    (src_dir / "README.md").write_text("not json", encoding="utf-8")

    cache_dir = tmp_path / "cache"
    results = import_path(src_dir, cache_dir=cache_dir)

    assert [r[0].name for r in results] == ["pick.json"]
    source, shader, error = results[0]
    assert error is None and shader.id == "myPick1"
    cached = json.loads((cache_dir / "myPick1.json").read_text(encoding="utf-8"))
    assert cached["Shader"]["info"]["id"] == "myPick1"


def test_import_path_keeps_going_after_one_bad_file(tmp_path):
    src_dir = tmp_path / "manual"
    src_dir.mkdir()
    (src_dir / "good.json").write_text(
        json.dumps({"id": "good1", "code": "void mainImage(out vec4 fragColor, in vec2 fragCoord) {}"}),
        encoding="utf-8",
    )
    (src_dir / "broken.json").write_text(json.dumps({"id": "broken1"}), encoding="utf-8")  # missing code

    results = import_path(src_dir, cache_dir=tmp_path / "cache")
    by_name = {r[0].name: r for r in results}
    assert by_name["good.json"][1].id == "good1" and by_name["good.json"][2] is None
    assert by_name["broken.json"][1] is None and "code" in by_name["broken.json"][2]


def test_cli_imports_and_reports_portability(tmp_path, capsys):
    src_dir = tmp_path / "manual"
    src_dir.mkdir()
    (src_dir / "pick.json").write_text(
        json.dumps(
            {
                "id": "myPick1",
                "name": "My Pick",
                "author": "someone",
                "description": "SPDX-License-Identifier: MIT",
                "channel0_ctype": "webcam",
                "code": (
                    "void mainImage(out vec4 fragColor, in vec2 fragCoord) {\n"
                    "    fragColor = texture(iChannel0, fragCoord / iResolution.xy);\n"
                    "}\n"
                ),
            }
        ),
        encoding="utf-8",
    )
    cache_dir = tmp_path / "cache"
    code = import_manual.main([str(src_dir), "--cache-dir", str(cache_dir)])
    out = capsys.readouterr().out

    assert code == 0
    assert "license=MIT" in out and "port=yes" in out
    assert (cache_dir / "myPick1.json").exists()


def test_cli_missing_path_reports_error(tmp_path, capsys):
    missing = tmp_path / "does_not_exist"
    code = import_manual.main([str(missing)])
    assert code == 2
    assert "does not exist" in capsys.readouterr().out
