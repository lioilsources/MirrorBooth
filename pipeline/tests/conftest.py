"""Shared offline fixtures.

No network, no live LLM, no embedding model: every agent's ``get_llm`` is
replaced by ``FakeLLM`` returning canned responses per role, and the RAG
retriever is stubbed.
"""

from __future__ import annotations

import sys
import types
from collections.abc import Callable
from pathlib import Path

import pytest

PIPELINE_DIR = Path(__file__).resolve().parent.parent
if str(PIPELINE_DIR) not in sys.path:
    sys.path.insert(0, str(PIPELINE_DIR))

VALID_SHADER = """#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 col = texture(uTexture, uv).rgb;
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
"""

# Uses gl_FragCoord and lacks the Flutter include -> contract violations.
INVALID_SHADER = """uniform sampler2D uTexture;
out vec4 fragColor;
void main() { fragColor = texture(uTexture, gl_FragCoord.xy); }
"""

TECH_SPEC_JSON = (
    '{"effect_name": "Test FX", "techniques": ["noise", "hue_rotation"], '
    '"uniforms": ["uTexture", "uResolution"], "needs_time": false, '
    '"description": "a deterministic test effect"}'
)

RANK_JSON = (
    '{"scores": {"correctness": 9, "creativity": 7, "mobile_optimization": 8, '
    '"flutter_compliance": 10}, "overall": 8.5, "explanation": "clean and compliant"}'
)

DEFAULT_RESPONSES: dict[str, str | Callable[[int], str]] = {
    "architect": f"```json\n{TECH_SPEC_JSON}\n```",
    "coder": f"```glsl\n{VALID_SHADER}```",
    "ranker": RANK_JSON,
}


class FakeLLM:
    """Records calls and returns canned content for one role."""

    def __init__(self, role: str, response: str | Callable[[int], str], calls: list):
        self.role = role
        self.response = response
        self.calls = calls

    def invoke(self, messages):
        n = sum(1 for role, _ in self.calls if role == self.role)
        self.calls.append((self.role, messages))
        content = self.response(n) if callable(self.response) else self.response
        return types.SimpleNamespace(content=content)


class FakeLLMFactory:
    def __init__(self):
        self.responses: dict[str, str | Callable[[int], str]] = dict(DEFAULT_RESPONSES)
        self.calls: list[tuple[str, list]] = []

    def __call__(self, role, cfg=None):
        if role not in self.responses:
            raise AssertionError(f"unexpected LLM role {role!r} in offline test")
        return FakeLLM(role, self.responses[role], self.calls)

    def count(self, role: str) -> int:
        return sum(1 for r, _ in self.calls if r == role)


@pytest.fixture
def fake_llm(monkeypatch) -> FakeLLMFactory:
    """Replace ``get_llm`` in every agent module with a canned responder."""
    import agents.glsl_coder as gc
    import agents.ranker as rk
    import agents.style_architect as sa

    factory = FakeLLMFactory()
    for mod in (sa, gc, rk):
        monkeypatch.setattr(mod, "get_llm", factory)
    return factory


@pytest.fixture
def offline_graph(monkeypatch, fake_llm):
    """Graph wired to the fake LLM, with a stub RAG retriever and no glslangValidator."""
    import agents.validator as validator
    import graph as graph_mod
    from config import settings

    def stub_rag(state):
        return {**state, "rag_context": ["float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }"]}

    monkeypatch.setattr(graph_mod, "rag_retriever_node", stub_rag)
    monkeypatch.setattr(validator.shutil, "which", lambda _name: None)
    monkeypatch.setattr(settings, "max_retries", 3)
    return graph_mod
