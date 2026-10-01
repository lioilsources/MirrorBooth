"""Pydantic models for Shadertoy API responses (``GET /api/v1/shaders/{id}``).

Only the fields the pipeline uses are typed; everything else is kept
(``extra="allow"``) so cached JSON round-trips losslessly. The API is loose
with types (numbers as strings, ``"true"``/``"false"`` booleans), hence the
lenient coercions.
"""

from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict, Field, field_validator

SHADERTOY_VIEW_URL = "https://www.shadertoy.com/view/{id}"


class _Loose(BaseModel):
    model_config = ConfigDict(extra="allow", populate_by_name=True)


class Sampler(_Loose):
    filter: str = ""
    wrap: str = ""
    vflip: bool = False
    srgb: bool = False
    internal: str = ""

    @field_validator("vflip", "srgb", mode="before")
    @classmethod
    def _boolish(cls, v: Any) -> bool:
        if isinstance(v, str):
            return v.strip().lower() == "true"
        return bool(v)


class RenderInput(_Loose):
    id: str | int = ""
    src: str = Field(default="", alias="filepath")
    ctype: str = Field(default="", alias="type")
    channel: int = 0
    sampler: Sampler = Field(default_factory=Sampler)
    published: int | None = None

    @field_validator("id", mode="before")
    @classmethod
    def _id_str(cls, v: Any) -> str:
        return "" if v is None else str(v)


class RenderPass(_Loose):
    type: str = "image"  # image | common | buffer | sound | cubemap
    name: str = ""
    code: str = ""
    description: str = ""
    inputs: list[RenderInput] = Field(default_factory=list)
    outputs: list[dict[str, Any]] = Field(default_factory=list)


class ShaderInfo(_Loose):
    id: str
    name: str = ""
    username: str = ""
    description: str = ""
    tags: list[str] = Field(default_factory=list)
    likes: int = 0
    viewed: int = 0
    date: str = ""
    published: int | None = None

    @field_validator("likes", "viewed", mode="before")
    @classmethod
    def _intish(cls, v: Any) -> int:
        try:
            return int(v)
        except (TypeError, ValueError):
            return 0


class Shader(_Loose):
    ver: str = ""
    info: ShaderInfo
    renderpass: list[RenderPass] = Field(default_factory=list)

    @property
    def id(self) -> str:
        return self.info.id

    @property
    def url(self) -> str:
        return SHADERTOY_VIEW_URL.format(id=self.info.id)

    def passes(self, kind: str) -> list[RenderPass]:
        return [p for p in self.renderpass if p.type == kind]

    @property
    def image_pass(self) -> RenderPass | None:
        images = self.passes("image")
        return images[0] if images else None

    @property
    def common_code(self) -> str:
        return "\n\n".join(p.code for p in self.passes("common"))

    @property
    def all_code(self) -> str:
        return "\n\n".join(p.code for p in self.renderpass)


def parse_shader(payload: dict[str, Any]) -> Shader:
    """Parse an API payload (``{"Shader": {...}}``) or a bare shader object."""
    body = payload.get("Shader", payload)
    return Shader.model_validate(body)
