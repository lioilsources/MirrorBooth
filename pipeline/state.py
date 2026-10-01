from typing import Any, TypedDict


class ShaderSource(TypedDict, total=False):
    """Where a shader request comes from.

    kind="style"     — generated from a natural-language style prompt (inspire mode)
    kind="shadertoy" — ported from a Shadertoy shader (port mode, Phase 3)
    """

    kind: str  # "style" | "shadertoy"
    id: str  # Shadertoy id; empty for style runs
    license: str
    permissive: bool
    url: str
    author: str
    name: str
    blend: str  # port mode: composite blend mode for procedural shaders
    allow_nc_license: bool  # --i-accept-nc-license (local experiments only)


class ShaderGenState(TypedDict):
    style_prompt: str
    source: ShaderSource
    tech_spec: dict
    rag_context: list[str]
    glsl_code: str
    needs_time: bool
    needs_face: bool
    category: str  # image_filter | procedural | data_texture | unsupported | "" (style runs)
    fixes_needed: list[str]  # port mode: constructs the LLM fixer must still repair
    validation_errors: list[str]
    validation_passed: bool
    retry_count: int
    rank_report: dict
    preview_paths: list[str]
    provenance: dict[str, Any]
    output_path: str


def initial_state(style_prompt: str, source: ShaderSource | None = None) -> ShaderGenState:
    """Build a fully-populated initial state for a graph run."""
    return {
        "style_prompt": style_prompt,
        "source": source if source is not None else {"kind": "style", "id": "", "license": ""},
        "tech_spec": {},
        "rag_context": [],
        "glsl_code": "",
        "needs_time": False,
        "needs_face": False,
        "category": "",
        "fixes_needed": [],
        "validation_errors": [],
        "validation_passed": False,
        "retry_count": 0,
        "rank_report": {},
        "preview_paths": [],
        "provenance": {},
        "output_path": "",
    }
