"""Vision ranker: a multimodal model judges the headless previews.

Works with either provider of the ``vision`` role (llm.py): Anthropic (content
blocks with base64 images) or the SPARK gateway (OpenAI ``image_url`` blocks,
e.g. the ``vl`` alias). Any failure — no key, no endpoint, refusal, garbage —
leaves the text-only rank report untouched.
"""

from __future__ import annotations

import base64
from pathlib import Path

from langchain_core.messages import HumanMessage, SystemMessage

from llm import get_llm, parse_json_block, provider_for
from state import ShaderGenState

VISION_KEYS = ("visual_quality", "face_readability", "matches_intent")

SYSTEM_PROMPT = """You judge camera filters for a selfie mirror app. The first image is the unfiltered input
(a synthetic or real test selfie); the following images are the filter output at different times.
Return raw JSON only:
{
  "visual_quality": <1-10, how good and polished the effect looks>,
  "face_readability": <1-10, the face is still clearly recognisable and centred>,
  "matches_intent": <1-10, the output matches the described effect>,
  "artifacts": [<short strings: banding, black areas, upside-down, seams, noise, ...>],
  "explanation": "<2 sentences>"
}"""


def _image_block(path: str, provider: str) -> dict:
    data = base64.b64encode(Path(path).read_bytes()).decode("ascii")
    if provider == "anthropic":
        return {"type": "image", "source": {"type": "base64", "media_type": "image/png", "data": data}}
    return {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{data}"}}


def build_messages(state: ShaderGenState, input_image: str, provider: str) -> list:
    spec = state.get("tech_spec", {})
    content = [
        {
            "type": "text",
            "text": f"Effect: {spec.get('effect_name', '?')}\nIntended look: {spec.get('description', state.get('style_prompt', ''))}",
        },
        _image_block(input_image, provider),
    ]
    content += [_image_block(p, provider) for p in state.get("preview_paths", [])]
    return [SystemMessage(content=SYSTEM_PROMPT), HumanMessage(content=content)]


def merge_vision(rank_report: dict, vision: dict) -> dict:
    scores = dict(rank_report.get("scores") or {})
    for key in VISION_KEYS:
        value = vision.get(key)
        if isinstance(value, (int, float)):
            scores[key] = value
    numeric = [v for v in scores.values() if isinstance(v, (int, float))]
    report = {**rank_report, "scores": scores, "vision": vision}
    if numeric:
        report["overall"] = round(sum(numeric) / len(numeric), 1)
    return report


def vision_ranker_node(state: ShaderGenState) -> ShaderGenState:
    if not state.get("preview_paths"):
        return state
    from preview.render import default_input

    provider = provider_for("vision")
    try:
        llm = get_llm("vision")
        response = llm.invoke(build_messages(state, str(default_input()), provider))
        vision = parse_json_block(response.content)
    except Exception as exc:  # noqa: BLE001 - vision ranking is optional by design
        print(f"[vision_ranker] skipped ({provider}): {str(exc)[:200]}")
        report = {**state.get("rank_report", {}), "vision": {"skipped": f"{provider}: {str(exc)[:200]}"}}
        return {**state, "rank_report": report}
    vision["provider"] = provider
    return {**state, "rank_report": merge_vision(state.get("rank_report", {}), vision)}
