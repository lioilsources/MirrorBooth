"""End-to-end graph test with a canned LLM and no chromadb / network."""

from pathlib import Path

import graph as graph_mod
from agents.validator import _contract_check

FIX = Path(__file__).parent / "fixtures"


def _initial_state():
    return {
        "style_prompt": "swirling neon plasma",
        "tech_spec": {},
        "rag_context": [],
        "port_reference": "",
        "port_techniques": [],
        "glsl_code": "",
        "validation_errors": [],
        "retry_count": 0,
        "rank_report": {},
        "output_path": "",
    }


def _seed_rag(snippets):
    def fake_rag(state):
        return {**state, "rag_context": snippets}
    return fake_rag


def test_graph_runs_and_emits_contract_valid_shader(fake_llm, monkeypatch):
    monkeypatch.setattr(graph_mod, "rag_retriever_node", _seed_rag([]))
    final = graph_mod.build_graph().invoke(_initial_state())

    assert _contract_check(final["glsl_code"]) == []
    assert final["rank_report"]["overall"] == 8.5
    assert final["validation_errors"] == []


def test_graph_port_path_promotes_clean_shadertoy_reference(fake_llm, monkeypatch):
    shadertoy = (FIX / "shadertoy_basic.glsl").read_text()
    monkeypatch.setattr(graph_mod, "rag_retriever_node", _seed_rag([shadertoy]))

    final = graph_mod.build_graph().invoke(_initial_state())

    assert final["port_reference"], "expected a ported Shadertoy reference"
    assert _contract_check(final["port_reference"]) == []
    assert "FlutterFragCoord" in final["port_reference"]


def test_graph_skips_port_for_non_shadertoy_context(fake_llm, monkeypatch):
    flutter_snippet = "void main() { fragColor = vec4(FlutterFragCoord().xy, 0.0, 1.0); }"
    monkeypatch.setattr(graph_mod, "rag_retriever_node", _seed_rag([flutter_snippet]))

    final = graph_mod.build_graph().invoke(_initial_state())
    assert final["port_reference"] == ""
