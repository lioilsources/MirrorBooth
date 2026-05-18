"""
shadertoy_porter graph node — deterministic, no LLM, no network.

Scans the RAG context for Shadertoy-convention snippets, ports the best
clean one to the Flutter/Impeller contract and exposes it as
`state["port_reference"]` so glsl_coder can adapt it directly instead of
re-deriving the effect from scratch.
"""

from agents.shadertoy_adapter import is_shadertoy_source, port_shadertoy
from state import ShaderGenState

_TECH_HINTS = {
    "voronoi": "voronoi",
    "fbm": "fbm",
    "noise": "noise",
    "kaleid": "kaleidoscope",
    "tunnel": "tunnel",
    "march": "raymarch",
    "warp": "domain_warp",
    "palette": "palette_cycle",
    "truchet": "truchet",
    "metaball": "metaballs",
    "curl": "flow_field",
    "hex": "hex_grid",
    "scan": "crt",
    "chromat": "chromatic_aberration",
}


def _sniff_techniques(code: str) -> list[str]:
    low = code.lower()
    return sorted({tag for kw, tag in _TECH_HINTS.items() if kw in low})


def shadertoy_porter_node(state: ShaderGenState) -> ShaderGenState:
    # RAG snippets arrive in relevance order; the first clean port is the
    # highest-confidence reference.
    for snippet in state.get("rag_context", []):
        if not is_shadertoy_source(snippet):
            continue
        result = port_shadertoy(snippet)
        if result.is_clean:
            return {
                **state,
                "port_reference": result.code,
                "port_techniques": _sniff_techniques(result.code),
            }

    return {**state, "port_reference": "", "port_techniques": []}
