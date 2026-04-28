import json
from langchain_openai import ChatOpenAI
from langchain_core.messages import SystemMessage, HumanMessage
from config import settings
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


def style_architect_node(state: ShaderGenState) -> ShaderGenState:
    llm = ChatOpenAI(
        base_url=settings.spark_base_url,
        api_key=settings.spark_api_key,
        model=settings.spark_model,
        temperature=0.3,
    )
    messages = [
        SystemMessage(content=SYSTEM_PROMPT),
        HumanMessage(content=f"Design a GLSL shader for this effect: {state['style_prompt']}"),
    ]
    response = llm.invoke(messages)
    raw = response.content.strip()
    # strip markdown fences if model adds them anyway
    if raw.startswith("```"):
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]
    tech_spec = json.loads(raw.strip())
    return {**state, "tech_spec": tech_spec}
