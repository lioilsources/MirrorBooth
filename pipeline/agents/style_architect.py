from langchain_core.messages import HumanMessage, SystemMessage

from llm import get_llm, parse_json_block
from state import ShaderGenState

SYSTEM_PROMPT = """You are a graphics engineer specializing in GLSL shader design for mobile apps.
Given a description of a visual filter effect, output a technical specification as JSON.

The JSON must have exactly these fields:
- effect_name: short display name (string)
- techniques: list of GLSL techniques needed (e.g. "sobel_edge_detection", "gaussian_blur", "color_quantization", "cel_shading", "chromatic_aberration", "noise", "hue_rotation", "posterization")
- uniforms: list of required uniforms — always include "uTexture" and "uResolution", add "uTime" only if animation is needed
- needs_time: boolean — true only if the effect is animated/time-varying
- description: one sentence technical description of the effect

Respond with raw JSON only, no markdown fences."""


def _fallback_spec(style_prompt: str, raw: str, error: str) -> dict:
    """Minimal spec used when the model does not return parseable JSON."""
    return {
        "effect_name": style_prompt.strip()[:40] or "Custom Filter",
        "techniques": [],
        "uniforms": ["uTexture", "uResolution"],
        "needs_time": False,
        "description": style_prompt.strip(),
        "_parse_error": f"{error}; raw={raw[:500]!r}",
    }


def style_architect_node(state: ShaderGenState) -> ShaderGenState:
    llm = get_llm("architect")
    messages = [
        SystemMessage(content=SYSTEM_PROMPT),
        HumanMessage(content=f"Design a GLSL shader for this effect: {state['style_prompt']}"),
    ]
    response = llm.invoke(messages)
    raw = response.content.strip()
    try:
        tech_spec = parse_json_block(raw)
    except ValueError as exc:
        print(f"[style_architect] WARNING: could not parse tech spec JSON ({exc}); using fallback spec")
        tech_spec = _fallback_spec(state["style_prompt"], raw, str(exc))

    needs_time = bool(tech_spec.get("needs_time", False))
    return {
        **state,
        "tech_spec": tech_spec,
        "needs_time": needs_time,
        "needs_face": bool(state.get("needs_face", False)),
    }
