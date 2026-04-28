import json
import re
from langchain_openai import ChatOpenAI
from langchain_core.messages import SystemMessage, HumanMessage
from config import settings
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
    llm = ChatOpenAI(
        base_url=settings.spark_base_url,
        api_key=settings.spark_api_key,
        model=settings.spark_model,
        temperature=0.1,
    )

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

    # strip markdown fences
    raw = re.sub(r"^```(?:json)?\n?", "", raw)
    raw = re.sub(r"\n?```$", "", raw)

    try:
        rank_report = json.loads(raw.strip())
    except json.JSONDecodeError:
        rank_report = {"scores": {}, "overall": 0, "explanation": raw}

    return {**state, "rank_report": rank_report}
