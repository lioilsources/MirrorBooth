from langgraph.graph import StateGraph, END
from state import ShaderGenState
from agents.style_architect import style_architect_node
from agents.rag_retriever import rag_retriever_node
from agents.shadertoy_porter import shadertoy_porter_node
from agents.glsl_coder import glsl_coder_node
from agents.validator import validator_node
from agents.ranker import ranker_node
from config import settings


def _should_retry(state: ShaderGenState) -> str:
    if state["validation_errors"] and state["retry_count"] < settings.max_retries:
        return "retry"
    return "done"


def build_graph() -> StateGraph:
    graph = StateGraph(ShaderGenState)

    graph.add_node("style_architect", style_architect_node)
    graph.add_node("rag_retriever", rag_retriever_node)
    graph.add_node("shadertoy_porter", shadertoy_porter_node)
    graph.add_node("glsl_coder", glsl_coder_node)
    graph.add_node("validator", validator_node)
    graph.add_node("ranker", ranker_node)

    graph.set_entry_point("style_architect")
    graph.add_edge("style_architect", "rag_retriever")
    graph.add_edge("rag_retriever", "shadertoy_porter")
    graph.add_edge("shadertoy_porter", "glsl_coder")
    graph.add_edge("glsl_coder", "validator")
    graph.add_conditional_edges(
        "validator",
        _should_retry,
        {"retry": "glsl_coder", "done": "ranker"},
    )
    graph.add_edge("ranker", END)

    return graph.compile()
