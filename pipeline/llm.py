"""LLM provider abstraction + shared helpers for parsing LLM output.

Every agent obtains its chat model via ``get_llm(role)`` instead of building
``ChatOpenAI(...)`` itself. The returned object exposes ``invoke(messages)``
returning a message with a ``.content`` string (LangChain chat-model protocol).

Providers:
  * ``spark``     — OpenAI-compatible endpoint (LiteLLM gateway on SPARK). The
                    ``vision`` role uses ``spark_vision_base_url``/``spark_vision_model``.
  * ``anthropic`` — optional; official ``anthropic`` SDK, model from settings.
"""

from __future__ import annotations

import json
import re
from typing import Any, Literal, get_args

from config import Settings
from config import settings as default_settings

Role = Literal["architect", "coder", "ranker", "fixer", "vision"]
ROLES: tuple[str, ...] = get_args(Role)

# Sampling temperature per role (matches the pre-refactor per-agent values).
ROLE_TEMPERATURE: dict[str, float] = {
    "architect": 0.3,
    "coder": 0.2,
    "ranker": 0.1,
    "fixer": 0.1,
    "vision": 0.1,
}


class LLMConfigError(RuntimeError):
    """Raised when the requested provider cannot be used with the current settings."""


def provider_for(role: str, cfg: Settings | None = None) -> str:
    cfg = cfg or default_settings
    if role == "vision" and cfg.llm_provider_vision:
        return cfg.llm_provider_vision
    return cfg.llm_provider


def get_llm(role: Role, cfg: Settings | None = None) -> Any:
    """Return a chat model for ``role`` according to ``settings.llm_provider``."""
    if role not in ROLES:
        raise ValueError(f"Unknown LLM role {role!r}; expected one of {ROLES}")
    cfg = cfg or default_settings
    provider = provider_for(role, cfg)
    temperature = ROLE_TEMPERATURE[role]

    if provider == "spark":
        return _spark_llm(role, temperature, cfg)
    if provider == "anthropic":
        return _anthropic_llm(cfg)
    raise LLMConfigError(f"Unknown llm_provider {provider!r}; expected 'spark' or 'anthropic'")


def _spark_llm(role: str, temperature: float, cfg: Settings) -> Any:
    from langchain_openai import ChatOpenAI

    if role == "vision":
        return ChatOpenAI(
            base_url=cfg.spark_vision_base_url,
            api_key=cfg.spark_vision_api_key or cfg.spark_api_key,
            model=cfg.spark_vision_model,
            temperature=temperature,
        )
    return ChatOpenAI(
        base_url=cfg.spark_base_url,
        api_key=cfg.spark_api_key,
        model=cfg.spark_model,
        temperature=temperature,
    )


def _anthropic_llm(cfg: Settings) -> AnthropicChat:
    if not cfg.anthropic_api_key:
        raise LLMConfigError(
            "llm_provider=anthropic requires ANTHROPIC_API_KEY in pipeline/.env "
            "(or switch LLM_PROVIDER back to 'spark')."
        )
    try:
        import anthropic
    except ImportError as exc:  # pragma: no cover - depends on optional install
        raise LLMConfigError(
            "llm_provider=anthropic requires the optional 'anthropic' package: pip install anthropic"
        ) from exc
    client = anthropic.Anthropic(api_key=cfg.anthropic_api_key)
    return AnthropicChat(client=client, model=cfg.anthropic_model, max_tokens=cfg.anthropic_max_tokens)


class _Reply:
    """Minimal stand-in for a LangChain AIMessage (only ``.content`` is used)."""

    def __init__(self, content: str):
        self.content = content


class AnthropicChat:
    """Tiny adapter giving the official Anthropic client a LangChain-like ``invoke``.

    Accepts LangChain message objects (``SystemMessage``/``HumanMessage``/``AIMessage``)
    or plain ``{"role", "content"}`` dicts. List content is passed through unchanged,
    so callers can send Anthropic content blocks (e.g. images for the vision role).
    Sampling params are not sent: current Opus models reject ``temperature``.
    """

    def __init__(self, client: Any, model: str, max_tokens: int = 16000):
        self.client = client
        self.model = model
        self.max_tokens = max_tokens

    @staticmethod
    def _convert(messages: list[Any]) -> tuple[str, list[dict]]:
        system_parts: list[str] = []
        converted: list[dict] = []
        for m in messages:
            if isinstance(m, dict):
                role, content = m["role"], m["content"]
            else:
                role = {"system": "system", "human": "user", "ai": "assistant"}.get(m.type, m.type)
                content = m.content
            if role == "system":
                system_parts.append(content if isinstance(content, str) else json.dumps(content))
            else:
                converted.append({"role": role, "content": content})
        return "\n\n".join(system_parts), converted

    def invoke(self, messages: list[Any]) -> _Reply:
        system, converted = self._convert(messages)
        kwargs: dict[str, Any] = {"model": self.model, "max_tokens": self.max_tokens, "messages": converted}
        if system:
            kwargs["system"] = system
        response = self.client.messages.create(**kwargs)
        if getattr(response, "stop_reason", None) == "refusal":
            raise RuntimeError(f"Anthropic model {self.model} refused the request")
        text = "".join(block.text for block in response.content if getattr(block, "type", None) == "text")
        return _Reply(text)


# ---------------------------------------------------------------------------
# Parsing helpers shared by all agents
# ---------------------------------------------------------------------------

_FENCE_RE = re.compile(r"```[ \t]*([\w+-]*)[ \t]*\n?(.*?)```", re.DOTALL)


def strip_code_fence(text: str) -> str:
    """Return the body of the first fenced block, or the stripped text if there is none."""
    text = text.strip()
    match = _FENCE_RE.search(text)
    if match:
        return match.group(2).strip()
    # unterminated fence (model got cut off): drop the opening line
    if text.startswith("```"):
        return text.split("\n", 1)[1].strip() if "\n" in text else ""
    return text


def parse_json_block(text: str) -> dict:
    """Parse a JSON object from LLM output.

    Handles raw JSON, ```json fences and JSON embedded in surrounding prose.
    Raises ``ValueError`` if no JSON object can be decoded.
    """
    if not isinstance(text, str) or not text.strip():
        raise ValueError("empty LLM response, expected JSON")

    candidates = [text.strip(), strip_code_fence(text)]
    for candidate in candidates:
        try:
            value = json.loads(candidate)
        except json.JSONDecodeError:
            continue
        if isinstance(value, dict):
            return value

    # fall back to the first decodable {...} object anywhere in the text
    decoder = json.JSONDecoder()
    for start in (i for i, ch in enumerate(text) if ch == "{"):
        try:
            value, _ = decoder.raw_decode(text, start)
        except json.JSONDecodeError:
            continue
        if isinstance(value, dict):
            return value

    raise ValueError(f"no JSON object found in LLM response: {text[:200]!r}")
