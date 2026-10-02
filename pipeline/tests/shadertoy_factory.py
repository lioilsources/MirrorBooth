"""Builders for Shadertoy API payloads used by the offline tests."""

from __future__ import annotations

import json
from pathlib import Path

FIXTURES = Path(__file__).parent / "fixtures" / "shadertoy"


def shader_payload(
    shader_id: str = "abc123",
    code: str = "void mainImage(out vec4 fragColor, in vec2 fragCoord) { fragColor = vec4(1.0); }",
    name: str = "Test",
    username: str = "tester",
    description: str = "",
    tags: list[str] | None = None,
    inputs: list[dict] | None = None,
    extra_passes: list[dict] | None = None,
    common: str | None = None,
) -> dict:
    passes = []
    if common is not None:
        passes.append(
            {"inputs": [], "outputs": [], "code": common, "name": "Common", "description": "", "type": "common"}
        )
    passes.append(
        {
            "inputs": inputs or [],
            "outputs": [{"id": 37, "channel": 0}],
            "code": code,
            "name": "Image",
            "description": "",
            "type": "image",
        }
    )
    passes += extra_passes or []
    return {
        "Shader": {
            "ver": "0.1",
            "info": {
                "id": shader_id,
                "date": "1600000000",
                "viewed": 1234,
                "name": name,
                "username": username,
                "description": description,
                "likes": 42,
                "published": 3,
                "flags": 0,
                "usePreview": 0,
                "tags": tags or ["test"],
            },
            "renderpass": passes,
        }
    }


def channel(ctype: str, channel_no: int = 0, src: str = "/media/a/x.png", wrap: str = "clamp") -> dict:
    return {
        "id": 30 + channel_no,
        "src": src,
        "ctype": ctype,
        "channel": channel_no,
        "sampler": {"filter": "linear", "wrap": wrap, "vflip": "true", "srgb": "false", "internal": "byte"},
        "published": 1,
    }


def load_fixture(name: str) -> dict:
    return json.loads((FIXTURES / f"{name}.json").read_text(encoding="utf-8"))
