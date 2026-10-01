import pytest

from shadertoy.model import parse_shader
from shadertoy.portability import classify
from tests.shadertoy_factory import load_fixture

EXPECTED = {
    "webcam_invert": "image_filter",
    "texture_screen": "image_filter",
    "common_tab": "image_filter",
    "procedural_plasma": "procedural",
    "fwidth_edges": "procedural",
    "raymarch_heavy": "procedural",
    "noise_texture": "data_texture",
    "multipass": "unsupported",
    "cubemap": "unsupported",
    "keyboard": "unsupported",
}


@pytest.mark.parametrize(("fixture", "category"), sorted(EXPECTED.items()))
def test_categories(fixture, category):
    report = classify(parse_shader(load_fixture(fixture)))
    assert report.category == category
    if category == "unsupported":
        assert report.score == 0 and report.unsupported_reasons
    else:
        assert 0 < report.score <= 100


def test_time_and_mouse_detection():
    plasma = classify(parse_shader(load_fixture("procedural_plasma")))
    assert plasma.uses_time and plasma.uses_mouse
    tex = classify(parse_shader(load_fixture("texture_screen")))
    assert not tex.uses_time and not tex.uses_mouse


def test_penalties_lower_the_score():
    clean = classify(parse_shader(load_fixture("webcam_invert"))).score
    fw = classify(parse_shader(load_fixture("fwidth_edges")))
    march = classify(parse_shader(load_fixture("raymarch_heavy")))
    assert "derivatives (dFdx/dFdy/fwidth)" in fw.issues
    assert any("raymarch" in i for i in march.issues)
    assert clean > fw.score > march.score
