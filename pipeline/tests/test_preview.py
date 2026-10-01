"""Headless preview, metrics and the vision ranker."""

import json

import numpy as np
import pytest

import agents.preview as preview_agent
import agents.vision_ranker as vr
from config import settings
from preview.metrics import evaluate, frame_metrics
from preview.render import RenderResult
from state import initial_state
from tests.conftest import VALID_SHADER

H, W = 32, 18


def _img(value=(120, 80, 40)):
    img = np.zeros((H, W, 3), dtype=np.uint8)
    img[:] = value
    img[:4, :4] = (255, 230, 0)
    return img


# --- metrics (pure numpy, run in CI) ---------------------------------------------


def test_frame_metrics():
    img = _img()
    m = frame_metrics(np.zeros_like(img), img)
    assert m.black_ratio == 1.0 and m.identical_ratio == 0.0
    assert frame_metrics(img, img).identical_ratio == 1.0


def test_evaluate_thresholds():
    img = _img()
    black = RenderResult(frames=[np.zeros_like(img)], times=[0.0], render_ms=1.0, input_image=img)
    _, errors, _ = evaluate(black, needs_time=False)
    assert any("black" in e for e in errors)

    same = RenderResult(frames=[img.copy()], times=[0.0], render_ms=1.0, input_image=img)
    _, errors, _ = evaluate(same, needs_time=False)
    assert any("does nothing" in e for e in errors)

    tinted = (img * 0.5).astype(np.uint8)
    static = RenderResult(frames=[tinted, tinted, tinted], times=[0, 0.7, 1.9], render_ms=1.0, input_image=img)
    metrics, errors, warnings = evaluate(static, needs_time=True)
    assert errors == [] and any("animation" in w for w in warnings)
    assert metrics["animation_diff"] == 0.0 and len(metrics["frames"]) == 3


# --- preview node with a fake renderer -------------------------------------------


@pytest.fixture
def fake_render(monkeypatch):
    import preview.render as render_mod

    holder = {"frame": None}

    def render(code, image, needs_time, needs_face, times=(0.0, 0.7, 1.9), ctx=None):
        img = _img()
        frame = holder["frame"] if holder["frame"] is not None else (255 - img)
        return RenderResult(frames=[frame], times=[0.0], render_ms=2.0, input_image=img)

    monkeypatch.setattr(render_mod, "render", render)
    monkeypatch.setattr(render_mod, "load_image", lambda _p: _img())
    monkeypatch.setattr(settings, "preview_enabled", True)
    return holder


def _validated_state(tmp_path):
    s = initial_state("x")
    s["glsl_code"] = VALID_SHADER
    s["validation_passed"] = True
    s["output_path"] = str(tmp_path)
    return s


def test_preview_node_saves_frames(fake_render, tmp_path):
    out = preview_agent.preview_node(_validated_state(tmp_path))
    assert out["validation_passed"] is True
    assert out["preview_paths"] == [str(tmp_path / "preview_t0.png")]
    assert (tmp_path / "preview_t0.png").exists()
    assert out["provenance"]["preview"]["max_identical_ratio"] < 0.5


def test_preview_node_fails_do_nothing_shader(fake_render, tmp_path):
    fake_render["frame"] = _img()
    out = preview_agent.preview_node(_validated_state(tmp_path))
    assert out["validation_passed"] is False
    assert out["retry_count"] == 1
    assert any("does nothing" in e for e in out["validation_errors"])


def test_preview_skipped_when_unavailable(monkeypatch, tmp_path):
    import preview.render as render_mod

    def boom(*_a, **_k):
        raise render_mod.PreviewUnavailable("no GL here")

    monkeypatch.setattr(render_mod, "render", boom)
    monkeypatch.setattr(settings, "preview_enabled", True)
    out = preview_agent.preview_node(_validated_state(tmp_path))
    assert out["validation_passed"] is True and out["preview_paths"] == []
    assert out["provenance"]["preview"]["skipped"] == "no GL here"


def test_inspire_graph_retries_after_failed_preview(offline_graph, fake_llm, fake_render, monkeypatch, tmp_path):
    frames = iter([_img(), None])  # first preview: identical to input, then a visible effect

    import preview.render as render_mod

    real = render_mod.render

    def render(*a, **k):
        fake_render["frame"] = next(frames)
        return real(*a, **k)

    monkeypatch.setattr(render_mod, "render", render)
    state = initial_state("x")
    state["output_path"] = str(tmp_path)
    final = offline_graph.build_graph().invoke(state)
    assert final["validation_passed"] is True
    assert fake_llm.count("coder") == 2


# --- vision ranker ------------------------------------------------------------------


@pytest.fixture
def png(tmp_path):
    from PIL import Image

    path = tmp_path / "p.png"
    Image.fromarray(_img()).save(path)
    return str(path)


def test_build_messages_per_provider(png):
    s = initial_state("neon outline")
    s["preview_paths"] = [png, png]
    s["tech_spec"] = {"effect_name": "Neon", "description": "glowing edges"}
    anth = vr.build_messages(s, png, "anthropic")[1].content
    assert [b["type"] for b in anth] == ["text", "image", "image", "image"]
    assert anth[1]["source"]["media_type"] == "image/png"
    spark = vr.build_messages(s, png, "spark")[1].content
    assert spark[1]["image_url"]["url"].startswith("data:image/png;base64,")


def test_vision_node_merges_scores(monkeypatch, png):
    class FakeVision:
        def invoke(self, messages):
            return type(
                "R",
                (),
                {
                    "content": json.dumps(
                        {
                            "visual_quality": 8,
                            "face_readability": 6,
                            "matches_intent": 7,
                            "artifacts": ["banding"],
                            "explanation": "ok",
                        }
                    )
                },
            )()

    monkeypatch.setattr(vr, "get_llm", lambda role, cfg=None: FakeVision())
    monkeypatch.setattr(vr, "provider_for", lambda role, cfg=None: "spark")
    s = initial_state("x")
    s["preview_paths"] = [png]
    s["rank_report"] = {"scores": {"correctness": 9, "flutter_compliance": 10}, "overall": 9.5}
    out = vr.vision_ranker_node(s)
    report = out["rank_report"]
    assert report["scores"]["face_readability"] == 6
    assert report["overall"] == round((9 + 10 + 8 + 6 + 7) / 5, 1)
    assert report["vision"]["artifacts"] == ["banding"] and report["vision"]["provider"] == "spark"


def test_vision_node_degrades_gracefully(monkeypatch, png):
    from llm import LLMConfigError

    def no_key(role, cfg=None):
        raise LLMConfigError("llm_provider=anthropic requires ANTHROPIC_API_KEY")

    monkeypatch.setattr(vr, "get_llm", no_key)
    s = initial_state("x")
    s["preview_paths"] = [png]
    s["rank_report"] = {"overall": 7}
    out = vr.vision_ranker_node(s)
    assert out["rank_report"]["overall"] == 7 and "ANTHROPIC_API_KEY" in out["rank_report"]["vision"]["skipped"]


def test_vision_skipped_without_previews():
    s = initial_state("x")
    assert vr.vision_ranker_node(s) is s


# --- real headless GL (local: pytest -m gl) ---------------------------------------


def _gl_or_skip():
    pytest.importorskip("moderngl")
    from preview.render import PreviewUnavailable, create_context

    try:
        return create_context()
    except PreviewUnavailable as exc:
        pytest.skip(str(exc))


@pytest.mark.gl
def test_identity_shader_keeps_orientation():
    from preview.render import default_input, load_image, render

    ctx = _gl_or_skip()
    img = load_image(default_input())
    out = render(VALID_SHADER, img, False, False, ctx=ctx).frames[0]
    assert np.abs(out.astype(int) - img).max() == 0


@pytest.mark.gl
def test_ported_passthrough_is_not_upside_down():
    """Y is flipped twice in a port (fragCoord and UV) — the result must equal the input."""
    from preview.render import default_input, load_image, render
    from shadertoy.model import parse_shader
    from shadertoy.transpile import transpile
    from tests.shadertoy_factory import channel, shader_payload

    ctx = _gl_or_skip()
    code = transpile(
        parse_shader(
            shader_payload(
                code="// MIT License\nvoid mainImage(out vec4 c, in vec2 f){ c = texture(iChannel0, f / iResolution.xy); }",
                inputs=[channel("webcam")],
            )
        )
    ).code
    img = load_image(default_input())
    out = render(code, img, False, False, ctx=ctx).frames[0]
    assert np.abs(out.astype(int) - img).max() <= 1
    assert tuple(out[20, 20]) == (255, 230, 0)  # top-left orientation marker


@pytest.mark.gl
@pytest.mark.parametrize("name", ["webcam_invert", "procedural_plasma", "noise_texture", "common_tab"])
def test_goldens_render_cleanly(name, tmp_path):
    from preview.render import default_input, load_image, render, save_frames
    from shadertoy.model import parse_shader
    from shadertoy.transpile import transpile
    from tests.shadertoy_factory import load_fixture

    ctx = _gl_or_skip()
    r = transpile(parse_shader(load_fixture(name)))
    result = render(r.code, load_image(default_input()), r.needs_time, r.needs_face, ctx=ctx)
    _, errors, _ = evaluate(result, r.needs_time)
    assert errors == []
    assert len(save_frames(result, tmp_path)) == (3 if r.needs_time else 1)
