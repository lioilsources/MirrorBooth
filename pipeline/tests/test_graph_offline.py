"""End-to-end graph runs with a canned LLM — no network, no chromadb."""

from state import initial_state
from tests.conftest import INVALID_SHADER, VALID_SHADER


def test_graph_happy_path(offline_graph, fake_llm):
    final = offline_graph.build_graph().invoke(initial_state("swirling neon plasma"))

    assert final["validation_passed"] is True
    assert final["validation_errors"] == []
    assert final["glsl_code"] == VALID_SHADER.strip()
    assert final["rank_report"]["overall"] == 7.2  # flutter_compliance capped at 5: no impellerc offline
    assert final["tech_spec"]["effect_name"] == "Test FX"
    assert final["rag_context"], "stub RAG context should reach the state"
    assert fake_llm.count("coder") == 1


def test_graph_recovers_after_retry(offline_graph, fake_llm):
    fake_llm.responses["coder"] = lambda n: INVALID_SHADER if n == 0 else VALID_SHADER
    final = offline_graph.build_graph().invoke(initial_state("x"))

    assert final["validation_passed"] is True
    assert final["retry_count"] == 1
    assert fake_llm.count("coder") == 2


def test_graph_exhausts_retries_and_flags_failure(offline_graph, fake_llm):
    fake_llm.responses["coder"] = INVALID_SHADER
    final = offline_graph.build_graph().invoke(initial_state("x"))

    assert final["validation_passed"] is False
    assert final["validation_errors"]
    assert final["retry_count"] == 3  # settings.max_retries
    assert fake_llm.count("coder") == 3
    # ranker still runs so the report exists, but the run is flagged
    assert fake_llm.count("ranker") == 1
