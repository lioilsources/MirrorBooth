"""Live smoke test against the SPARK LiteLLM gateway.

Deselected in CI (`-m "not network and not llm"`); run manually from M2:
    python -m pytest tests/test_live_smoke.py -m "network and llm"
"""

import pytest

pytestmark = [pytest.mark.network, pytest.mark.llm]


def test_gateway_coder_answers():
    from langchain_core.messages import HumanMessage

    from llm import get_llm

    reply = get_llm("coder").invoke([HumanMessage(content="Reply with the single word: ok")])
    assert reply.content.strip()
