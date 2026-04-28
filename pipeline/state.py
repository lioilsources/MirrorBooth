from typing import TypedDict


class ShaderGenState(TypedDict):
    style_prompt: str
    tech_spec: dict
    rag_context: list[str]
    glsl_code: str
    validation_errors: list[str]
    retry_count: int
    rank_report: dict
    output_path: str
