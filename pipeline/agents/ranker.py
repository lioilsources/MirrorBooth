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
  (this one is overridden by the compiler result; still give your estimate)

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

    rank_report = apply_compliance(rank_report, state)
    return {**state, "rank_report": rank_report}


def compliance_score(state: ShaderGenState) -> tuple[int | None, str]:
    """flutter_compliance from facts, not from the LLM's opinion.

    10 = compiled by impellerc for every target and passed the contract,
    1  = did not pass validation (compiler or contract),
    None = could not be verified by Impeller (keep the LLM value, capped at 5).
    """
    compile_info = state.get("provenance", {}).get("compile", {})
    if not state.get("validation_passed", False):
        return 1, "failed validation/compilation"
    if compile_info.get("impeller_verified"):
        return 10, "compiled by impellerc (Metal, GLES, GLES3, Vulkan, SkSL)"
    return None, f"not verified by impellerc (backend: {compile_info.get('backend', 'none')})"


def apply_compliance(rank_report: dict, state: ShaderGenState) -> dict:
    scores = dict(rank_report.get("scores") or {})
    value, note = compliance_score(state)
    if value is None:
        llm_value = scores.get("flutter_compliance")
        value = min(float(llm_value), 5.0) if isinstance(llm_value, (int, float)) else 5
    scores["flutter_compliance"] = value
    numeric = [v for v in scores.values() if isinstance(v, (int, float))]
    report = {**rank_report, "scores": scores, "flutter_compliance_source": note}
    if numeric:
        report["overall"] = round(sum(numeric) / len(numeric), 1)
    return report
