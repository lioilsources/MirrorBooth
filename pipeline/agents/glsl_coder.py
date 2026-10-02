from langchain_core.messages import HumanMessage, SystemMessage

from llm import get_llm, strip_code_fence
from state import ShaderGenState

FLUTTER_CONTRACT = """
All shaders MUST follow this Flutter/Impeller contract exactly:

#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;    // camera frame input
uniform vec2 uResolution;      // viewport size in pixels
// uniform float uTime;        // include ONLY if animated
// uniform vec2 uFaceCenter;   // include ONLY together with uFaceScale, for face-anchored effects
// uniform float uFaceScale;   //   (uFaceCenter in 0..1, top-left origin)

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    // ... effect code ...
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}

Rules:
- Uniforms exactly in the order above (uTexture, uResolution, [uTime], [uFaceCenter, uFaceScale]), no other uniforms or samplers
- Use FlutterFragCoord() NOT gl_FragCoord
- No #version directive (Flutter adds it)
- Not available: fwidth/dFdx/dFdy, texelFetch, textureSize, uint/uvec, uniform arrays
- Mobile budget: at most ~64 texture fetches inside loops per pixel, loops nested at most 2 deep
- Minimize branching (if/else) inside loops for mobile GPU performance
- Output must always assign fragColor
"""

SYSTEM_PROMPT = f"""You are an expert GLSL shader developer for mobile apps (Flutter/Impeller engine).
{FLUTTER_CONTRACT}
LICENSING RULE (hard, never break it):
Reference snippets carry a `// source:` line. Snippets marked "reference only, do not copy"
(Shadertoy shaders without a permissive license) may ONLY inform the technique. Never copy
their code verbatim or near-verbatim (no copied function bodies, constants tables or
distinctive expressions) — write your own implementation from scratch.

Write complete, compilable GLSL fragment shader code. Output raw GLSL only, no explanation, no markdown."""


def glsl_coder_node(state: ShaderGenState) -> ShaderGenState:
    llm = get_llm("coder")

    tech_spec = state["tech_spec"]
    rag_snippets = state.get("rag_context", [])
    errors = state.get("validation_errors", [])

    rag_block = ""
    if rag_snippets:
        joined = "\n\n// ---\n".join(rag_snippets)
        rag_block = (
            "\n\nReference GLSL snippets (technique inspiration; obey the licensing rule for each `// source:` line):\n"
            f"```glsl\n{joined}\n```"
        )

    error_block = ""
    if errors:
        error_block = "\n\nPrevious attempt failed validation. Fix these issues:\n" + "\n".join(
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
    code = strip_code_fence(response.content)

    return {
        **state,
        "glsl_code": code,
        "validation_errors": [],
        "validation_passed": False,
        "retry_count": state.get("retry_count", 0),
    }
