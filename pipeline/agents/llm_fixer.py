"""LLM fixer for port mode: repairs only what the transpiler/validator enumerate.

The fixer does not get creative freedom. Its prompt lists the exact problems
(``fixes_needed`` from the transpiler + validator errors) and the protected
regions it must not touch (attribution header, uniforms, the generated main()).
Output that alters a protected region is rejected and the previous code kept.
Every accepted change is appended as a unified diff to
``<output_path>/fixer_diff.patch``.
"""

from __future__ import annotations

import difflib
import re
from pathlib import Path

from langchain_core.messages import HumanMessage, SystemMessage

from agents.validator import UNRESOLVED_PREFIX
from llm import get_llm, strip_code_fence
from shadertoy.transpile import FIX_DERIVATIVES, FIX_TEXEL_FETCH, FIX_TEXTURE_SIZE, detect_fixes
from state import ShaderGenState

ENTRY_MARKER = "// ---- MirrorBooth entry point ----"

FIX_INSTRUCTIONS = {
    FIX_DERIVATIVES: (
        "Remove every dFdx/dFdy/fwidth call (unsupported by the Skia/SkSL backend). Replace fwidth(x) with a "
        "constant pixel footprint such as (1.5 / uResolution.y) scaled to the units of x, or with an analytic "
        "derivative when x is a simple function of fragCoord. Same for dFdx/dFdy (e.g. 1.0 / uResolution.x)."
    ),
    FIX_TEXEL_FETCH: (
        "Replace texelFetch(...) on non-camera samplers. If it reads a lookup table, inline the values or "
        "compute them procedurally."
    ),
    FIX_TEXTURE_SIZE: "Replace textureSize(...) with uResolution (as ivec2(uResolution)).",
}

SYSTEM_PROMPT = """You repair GLSL fragment shaders that were mechanically ported from Shadertoy to Flutter (Impeller + SkSL).
You are a surgical fixer, not an author:
- Change ONLY what the numbered problem list asks for. Keep every other line byte-identical.
- NEVER modify the comment header at the top (license attribution), the #include line, the uniform declarations,
  the `out vec4 fragColor;` line, the #define shims, or anything after the line
  "// ---- MirrorBooth entry point ----".
- Do not add uniforms, samplers, #version or precision statements.
- If a problem cannot be fixed without changing the shader's look substantially, output exactly
  `// UNFIXABLE: <reason>` and nothing else.
Output the complete corrected shader as raw GLSL, no markdown, no explanation."""


def protected_lines(code: str) -> list[str]:
    """Lines the fixer must keep: header comments, include, uniforms, out, shims."""
    keep = []
    for line in code.splitlines():
        s = line.strip()
        if s.startswith(("#include", "uniform ", "out vec4", "#define i", "const float iTimeDelta")):
            keep.append(s)
        elif s.startswith("// Ported from") or s.startswith("// LICENSE NOT PERMISSIVE"):
            keep.append(s)
    return keep


def entry_section(code: str) -> str:
    idx = code.find(ENTRY_MARKER)
    return code[idx:].strip() if idx >= 0 else ""


def check_protected(before: str, after: str) -> list[str]:
    after_lines = {ln.strip() for ln in after.splitlines()}
    problems = [
        f"fixer removed or changed protected line: {ln}" for ln in protected_lines(before) if ln not in after_lines
    ]
    extra_uniforms = set(re.findall(r"^\s*uniform\s+[^;]+;", after, re.MULTILINE)) - set(
        re.findall(r"^\s*uniform\s+[^;]+;", before, re.MULTILINE)
    )
    problems += [f"fixer added uniform: {u.strip()}" for u in sorted(extra_uniforms)]
    if entry_section(before) != entry_section(after):
        problems.append("fixer changed the generated main() entry point")
    return problems


def _append_diff(output_path: str, before: str, after: str, round_no: int) -> None:
    if not output_path:
        return
    diff = difflib.unified_diff(
        before.splitlines(keepends=True),
        after.splitlines(keepends=True),
        fromfile=f"round{round_no}/before.frag",
        tofile=f"round{round_no}/after.frag",
    )
    path = Path(output_path) / "fixer_diff.patch"
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as fh:
        fh.writelines(diff)


def llm_fixer_node(state: ShaderGenState) -> ShaderGenState:
    code = state["glsl_code"]
    fixes = list(state.get("fixes_needed", []))
    errors = list(state.get("validation_errors", []))
    problems = [FIX_INSTRUCTIONS[f] for f in fixes if f in FIX_INSTRUCTIONS]
    problems += [f"Compiler/validator error: {e}" for e in errors if not e.startswith(UNRESOLVED_PREFIX)]
    if not problems:
        return state

    numbered = "\n".join(f"{i}. {p}" for i, p in enumerate(problems, 1))
    messages = [
        SystemMessage(content=SYSTEM_PROMPT),
        HumanMessage(content=f"Problems to fix:\n{numbered}\n\nShader:\n```glsl\n{code}\n```"),
    ]
    response = get_llm("fixer").invoke(messages)
    new_code = strip_code_fence(response.content)

    provenance = dict(state.get("provenance", {}))
    rounds = list(provenance.get("fixer_rounds", []))
    round_no = len(rounds) + 1

    if new_code.startswith("// UNFIXABLE"):
        reason = new_code.strip()[:300]
        rounds.append({"round": round_no, "accepted": False, "reason": reason})
        return {
            **state,
            "provenance": {**provenance, "fixer_rounds": rounds, "unfixable": reason},
            "validation_errors": errors + [reason],
            "validation_passed": False,
        }

    violations = check_protected(code, new_code)
    if violations:
        rounds.append({"round": round_no, "accepted": False, "reason": "; ".join(violations)})
        print(f"[llm_fixer] rejected round {round_no}: {violations[0]}")
        return {
            **state,
            "provenance": {**provenance, "fixer_rounds": rounds},
            "validation_errors": errors + violations,
        }

    _append_diff(state.get("output_path", ""), code, new_code, round_no)
    rounds.append({"round": round_no, "accepted": True, "problems": problems})
    return {
        **state,
        "glsl_code": new_code,
        "fixes_needed": detect_fixes(new_code),
        "validation_errors": [],
        "validation_passed": False,
        "provenance": {**provenance, "fixer_rounds": rounds},
    }
