import types

import pytest
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI

import llm
from config import Settings
from llm import AnthropicChat, LLMConfigError, get_llm, parse_json_block, strip_code_fence


def _cfg(**overrides) -> Settings:
    return Settings(_env_file=None, **overrides)


@pytest.mark.parametrize("role", ["architect", "coder", "ranker", "fixer"])
def test_spark_text_roles_use_gateway(role):
    cfg = _cfg(spark_base_url="http://gw:8080/v1", spark_model="translate", spark_api_key="sk-x")
    model = get_llm(role, cfg)
    assert isinstance(model, ChatOpenAI)
    assert model.model_name == "translate"
    assert model.openai_api_base == "http://gw:8080/v1"
    assert model.openai_api_key.get_secret_value() == "sk-x"
    assert model.temperature == llm.ROLE_TEMPERATURE[role]


def test_spark_vision_uses_separate_settings():
    cfg = _cfg(
        spark_base_url="http://gw:8080/v1",
        spark_model="translate",
        spark_api_key="sk-x",
        spark_vision_base_url="http://vision:8001/v1",
        spark_vision_model="vl",
        spark_vision_api_key=None,
    )
    model = get_llm("vision", cfg)
    assert isinstance(model, ChatOpenAI)
    assert model.model_name == "vl"
    assert model.openai_api_base == "http://vision:8001/v1"
    # vision key falls back to the gateway key
    assert model.openai_api_key.get_secret_value() == "sk-x"


def test_spark_vision_own_key():
    model = get_llm("vision", _cfg(spark_api_key="sk-x", spark_vision_api_key="sk-vl"))
    assert model.openai_api_key.get_secret_value() == "sk-vl"


def test_unknown_role():
    with pytest.raises(ValueError):
        get_llm("painter", _cfg())


def test_anthropic_without_key_is_clear_error():
    with pytest.raises(LLMConfigError, match="ANTHROPIC_API_KEY"):
        get_llm("coder", _cfg(llm_provider="anthropic", anthropic_api_key=""))


def test_vision_provider_override_only_affects_vision():
    cfg = _cfg(llm_provider="spark", llm_provider_vision="anthropic", anthropic_api_key="")
    assert isinstance(get_llm("coder", cfg), ChatOpenAI)
    with pytest.raises(LLMConfigError):
        get_llm("vision", cfg)


def test_anthropic_provider_builds_adapter():
    pytest.importorskip("anthropic")
    model = get_llm("ranker", _cfg(llm_provider="anthropic", anthropic_api_key="sk-ant-test"))
    assert isinstance(model, AnthropicChat)
    assert model.model == "claude-opus-5"


class _FakeMessages:
    def __init__(self, response):
        self.response = response
        self.kwargs = None

    def create(self, **kwargs):
        self.kwargs = kwargs
        return self.response


def test_anthropic_adapter_converts_messages_and_joins_text():
    response = types.SimpleNamespace(
        stop_reason="end_turn",
        content=[
            types.SimpleNamespace(type="thinking", thinking=""),
            types.SimpleNamespace(type="text", text='{"ok": '),
            types.SimpleNamespace(type="text", text="true}"),
        ],
    )
    messages_api = _FakeMessages(response)
    chat = AnthropicChat(client=types.SimpleNamespace(messages=messages_api), model="claude-opus-5", max_tokens=123)

    reply = chat.invoke([SystemMessage(content="sys prompt"), HumanMessage(content="hello")])

    assert reply.content == '{"ok": true}'
    assert messages_api.kwargs == {
        "model": "claude-opus-5",
        "max_tokens": 123,
        "system": "sys prompt",
        "messages": [{"role": "user", "content": "hello"}],
    }


def test_anthropic_adapter_raises_on_refusal():
    response = types.SimpleNamespace(stop_reason="refusal", content=[])
    chat = AnthropicChat(client=types.SimpleNamespace(messages=_FakeMessages(response)), model="m")
    with pytest.raises(RuntimeError, match="refused"):
        chat.invoke([HumanMessage(content="x")])


# --- parse helpers ---------------------------------------------------------


@pytest.mark.parametrize(
    "text",
    [
        '{"a": 1, "b": [1, 2]}',
        '```json\n{"a": 1, "b": [1, 2]}\n```',
        '```\n{"a": 1, "b": [1, 2]}\n```',
        'Sure! Here is the spec:\n```json\n{"a": 1, "b": [1, 2]}\n```\nHope it helps.',
        'The answer is {"a": 1, "b": [1, 2]} as requested.',
        '  \n{"a": 1, "b": [1, 2]}\n\n',
    ],
)
def test_parse_json_block_variants(text):
    assert parse_json_block(text) == {"a": 1, "b": [1, 2]}


@pytest.mark.parametrize("text", ["", "   ", "no json here", "```json\n{broken\n```", "[1, 2, 3]"])
def test_parse_json_block_rejects(text):
    with pytest.raises(ValueError):
        parse_json_block(text)


def test_strip_code_fence():
    assert strip_code_fence("```glsl\nvoid main() {}\n```") == "void main() {}"
    assert strip_code_fence("void main() {}") == "void main() {}"
    assert strip_code_fence("Here:\n```glsl\nvoid main() {}\n```\nDone") == "void main() {}"
    assert strip_code_fence("```glsl\nvoid main() {}") == "void main() {}"
