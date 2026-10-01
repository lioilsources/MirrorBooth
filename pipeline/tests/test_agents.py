import sys

import agents.glsl_coder as glsl_coder
import agents.rag_retriever as rag_retriever
import agents.ranker as ranker
import agents.style_architect as style_architect
from state import initial_state
from tests.conftest import VALID_SHADER


def test_style_architect_parses_fenced_json(fake_llm):
    out = style_architect.style_architect_node(initial_state("hue noise"))
    assert out["tech_spec"]["effect_name"] == "Test FX"
    assert out["needs_time"] is False
    assert fake_llm.count("architect") == 1


def test_style_architect_sets_needs_time(fake_llm):
    fake_llm.responses["architect"] = (
        'Here you go: {"effect_name": "Wave", "techniques": ["animation"], '
        '"uniforms": ["uTexture", "uResolution", "uTime"], "needs_time": true, "description": "waves"}'
    )
    out = style_architect.style_architect_node(initial_state("waves"))
    assert out["needs_time"] is True
    assert out["tech_spec"]["techniques"] == ["animation"]


def test_style_architect_survives_garbage(fake_llm):
    fake_llm.responses["architect"] = "I cannot produce JSON today, sorry."
    out = style_architect.style_architect_node(initial_state("pastel dream"))
    spec = out["tech_spec"]
    assert spec["description"] == "pastel dream"
    assert spec["uniforms"] == ["uTexture", "uResolution"]
    assert "_parse_error" in spec


def test_glsl_coder_strips_fence_and_resets_errors(fake_llm):
    s = initial_state("x")
    s["tech_spec"] = {"effect_name": "X", "techniques": ["noise"], "description": "d"}
    s["validation_errors"] = ["Missing: something"]
    s["retry_count"] = 1
    out = glsl_coder.glsl_coder_node(s)
    assert out["glsl_code"] == VALID_SHADER.strip()
    assert out["validation_errors"] == []
    assert out["validation_passed"] is False
    assert out["retry_count"] == 1
    # previous errors were fed back to the model
    _, messages = fake_llm.calls[-1]
    assert "Missing: something" in messages[-1].content


def test_ranker_parses_json(fake_llm):
    s = initial_state("x")
    s["glsl_code"] = VALID_SHADER
    s["validation_passed"] = True
    s["provenance"] = {"compile": {"backend": "impellerc", "ok": True, "impeller_verified": True}}
    out = ranker.ranker_node(s)
    assert out["rank_report"]["scores"]["flutter_compliance"] == 10
    assert out["rank_report"]["overall"] == 8.5


def test_ranker_compliance_is_programmatic(fake_llm):
    s = initial_state("x")
    s["glsl_code"] = VALID_SHADER
    s["validation_passed"] = False  # LLM says 10, compiler says no
    out = ranker.ranker_node(s)
    assert out["rank_report"]["scores"]["flutter_compliance"] == 1
    assert out["rank_report"]["overall"] == round((9 + 7 + 8 + 1) / 4, 1)

    s["validation_passed"] = True
    s["provenance"] = {"compile": {"backend": "glslang", "ok": True, "impeller_verified": False}}
    out = ranker.ranker_node(s)
    assert out["rank_report"]["scores"]["flutter_compliance"] == 5  # capped: not verified by impellerc
    assert "not verified" in out["rank_report"]["flutter_compliance_source"]


def test_ranker_fallback_on_garbage(fake_llm):
    fake_llm.responses["ranker"] = "looks good to me"
    s = initial_state("x")
    s["glsl_code"] = VALID_SHADER
    out = ranker.ranker_node(s)
    report = out["rank_report"]
    assert report["explanation"] == "looks good to me"
    assert report["scores"] == {"flutter_compliance": 1} and report["overall"] == 1


def test_rag_retriever_without_chromadb(monkeypatch):
    # simulate chromadb not being installed
    monkeypatch.setitem(sys.modules, "chromadb", None)
    s = initial_state("x")
    s["tech_spec"] = {"techniques": ["noise"], "description": "d"}
    out = rag_retriever.rag_retriever_node(s)
    assert out["rag_context"] == []
