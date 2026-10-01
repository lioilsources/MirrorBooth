"""LangGraph wiring for both pipeline modes.

inspire (source.kind == "style"):
    style_architect -> rag_retriever -> glsl_coder -> validator --(retry)--> glsl_coder
                                                            \\--> ranker
port (source.kind == "shadertoy"):
    transpiler -> validator --(errors or fixes_needed)--> llm_fixer -> validator
                          \\--> ranker
"""

from langgraph.graph import END, StateGraph

from agents.glsl_coder import glsl_coder_node
from agents.llm_fixer import llm_fixer_node
from agents.rag_retriever import rag_retriever_node
from agents.ranker import ranker_node
from agents.style_architect import style_architect_node
from agents.transpiler import transpiler_node
from agents.validator import validator_node
from config import settings
from state import ShaderGenState


def _entry(state: ShaderGenState) -> str:
    return "port" if state.get("source", {}).get("kind") == "shadertoy" else "inspire"


def _is_port(state: ShaderGenState) -> bool:
    return _entry(state) == "port"


def _should_retry(state: ShaderGenState) -> str:
    if state["validation_errors"] and state["retry_count"] < settings.max_retries:
        return "retry"
    return "done"


def _should_fix(state: ShaderGenState) -> str:
    provenance = state.get("provenance", {})
    rounds = len(provenance.get("fixer_rounds", []))
    pending = state["validation_errors"] or state.get("fixes_needed")
    if pending and not provenance.get("unfixable") and rounds < settings.max_retries:
        return "fix"
    return "done"


def _after_validation(state: ShaderGenState) -> str:
    if _is_port(state):
        return _should_fix(state)
    return _should_retry(state)


def build_graph() -> StateGraph:
    graph = StateGraph(ShaderGenState)

    graph.add_node("style_architect", style_architect_node)
    graph.add_node("rag_retriever", rag_retriever_node)
    graph.add_node("glsl_coder", glsl_coder_node)
    graph.add_node("transpiler", transpiler_node)
    graph.add_node("llm_fixer", llm_fixer_node)
    graph.add_node("validator", validator_node)
    graph.add_node("ranker", ranker_node)

    graph.set_conditional_entry_point(_entry, {"inspire": "style_architect", "port": "transpiler"})
    graph.add_edge("style_architect", "rag_retriever")
    graph.add_edge("rag_retriever", "glsl_coder")
    graph.add_edge("glsl_coder", "validator")
    graph.add_edge("transpiler", "validator")
    graph.add_edge("llm_fixer", "validator")
    graph.add_conditional_edges(
        "validator",
        _after_validation,
        {"retry": "glsl_coder", "fix": "llm_fixer", "done": "ranker"},
    )
    graph.add_edge("ranker", END)

    return graph.compile()
