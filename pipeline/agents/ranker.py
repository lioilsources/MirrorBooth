from langchain_core.messages import HumanMessage, SystemMessage

from llm import get_llm, parse_json_block
from state import ShaderGenState

SYSTEM_PROMPT = """You are a senior GLSL code reviewer specializing in mobile GPU shaders.
Rate the given GLSL shader on 4 dimensions (1-10 each) and return a JSON object.

JSON format:
{
  "scores": {
    "correctness": <1-10>,
    "creativity": <1-10>,
    "mobile_optimization": <1-10>,
    "flutter_compliance": <1-10>
  },
  "overall": <average rounded to 1 decimal>,
  "explanation": "<2-3 sentences summarizing strengths and weaknesses>"
}

Scoring guide:
- correctness: syntactically valid, correct math, no undefined behavior
- creativity: originality and visual interest of the effect
- mobile_optimization: avoids heavy branching, minimizes texture fetches, uses efficient math
- flutter_compliance: proper use of FlutterFragCoord(), uTexture, uResolution, no forbidden constructs

Respond with raw JSON only."""


def ranker_node(state: ShaderGenState) -> ShaderGenState:
    llm = get_llm("ranker")

    tech_spec = state.get("tech_spec", {})
    messages = [
        SystemMessage(content=SYSTEM_PROMPT),
        HumanMessage(
            content=(
                f"Effect: {tech_spec.get('effect_name', 'Unknown')}\n"
                f"Description: {tech_spec.get('description', '')}\n\n"
                f"GLSL code:\n```glsl\n{state['glsl_code']}\n```"
            )
        ),
    ]
    response = llm.invoke(messages)
    raw = response.content.strip()

    try:
        rank_report = parse_json_block(raw)
    except ValueError:
        rank_report = {"scores": {}, "overall": 0, "explanation": raw}

    return {**state, "rank_report": rank_report}
