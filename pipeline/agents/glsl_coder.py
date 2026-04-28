import re
from langchain_openai import ChatOpenAI
from langchain_core.messages import SystemMessage, HumanMessage
from config import settings
from state import ShaderGenState

FLUTTER_CONTRACT = """
All shaders MUST follow this Flutter/Impeller contract exactly:

#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;    // camera frame input
uniform vec2 uResolution;      // viewport size in pixels
// uniform float uTime;        // include ONLY if animated

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    // ... effect code ...
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}

Rules:
- Use FlutterFragCoord() NOT gl_FragCoord
- No #version directive (Flutter adds it)
- Minimize branching (if/else) inside loops for mobile GPU performance
- Avoid texture fetches in tight loops; prefer separable passes mentally
- Output must always assign fragColor
"""

SYSTEM_PROMPT = f"""You are an expert GLSL shader developer for mobile apps (Flutter/Impeller engine).
{FLUTTER_CONTRACT}
Write complete, compilable GLSL fragment shader code. Output raw GLSL only, no explanation, no markdown."""


def glsl_coder_node(state: ShaderGenState) -> ShaderGenState:
    llm = ChatOpenAI(
        base_url=settings.spark_base_url,
        api_key=settings.spark_api_key,
        model=settings.spark_model,
        temperature=0.2,
    )

    tech_spec = state["tech_spec"]
    rag_snippets = state.get("rag_context", [])
    errors = state.get("validation_errors", [])

    rag_block = ""
    if rag_snippets:
        joined = "\n\n// ---\n".join(rag_snippets)
        rag_block = f"\n\nReference GLSL snippets from existing shaders (use as inspiration, adapt as needed):\n```glsl\n{joined}\n```"

    error_block = ""
    if errors:
        error_block = f"\n\nPrevious attempt failed validation. Fix these issues:\n" + "\n".join(
            f"- {e}" for e in errors
        )

    user_msg = (
        f"Write a Flutter GLSL fragment shader for this effect:\n"
        f"Name: {tech_spec.get('effect_name', 'Custom Filter')}\n"
        f"Techniques: {', '.join(tech_spec.get('techniques', []))}\n"
        f"Description: {tech_spec.get('description', '')}\n"
        f"Needs time uniform: {tech_spec.get('needs_time', False)}"
        f"{rag_block}{error_block}"
    )

    messages = [SystemMessage(content=SYSTEM_PROMPT), HumanMessage(content=user_msg)]
    response = llm.invoke(messages)
    code = response.content.strip()

    # strip markdown fences
    code = re.sub(r"^```(?:glsl)?\n?", "", code)
    code = re.sub(r"\n?```$", "", code)

    return {**state, "glsl_code": code.strip(), "validation_errors": [], "retry_count": state.get("retry_count", 0)}
