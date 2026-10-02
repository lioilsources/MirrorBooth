"""Port-mode entry node: Shadertoy shader -> MirrorBooth GLSL (deterministic)."""

from __future__ import annotations

from shadertoy.client import ShadertoyClient, load_cached
from shadertoy.transpile import transpile
from state import ShaderGenState


def load_source_shader(shader_id: str):
    """From the harvest cache; falls back to the API (which then caches it)."""
    try:
        return load_cached(shader_id)
    except FileNotFoundError:
        return ShadertoyClient().get(shader_id)


def transpiler_node(state: ShaderGenState) -> ShaderGenState:
    source = state["source"]
    shader = load_source_shader(source["id"])
    result = transpile(
        shader,
        blend_mode=source.get("blend") or None,
        allow_nc_license=bool(source.get("allow_nc_license")),
    )
    tech_spec = {
        "effect_name": shader.info.name,
        "description": (shader.info.description or shader.info.name).strip()[:500],
        "techniques": shader.info.tags,
        "category": result.category,
        "blend_mode": result.blend_mode,
        "needs_time": result.needs_time,
    }
    provenance = {
        "source": {
            "kind": "shadertoy",
            "id": shader.id,
            "url": shader.url,
            "name": shader.info.name,
            "author": shader.info.username,
        },
        "license": result.license["license"],
        "license_evidence": result.license.get("evidence", ""),
        "license_ok": bool(result.license["permissive"]),
        "category": result.category,
        "portability_score": result.portability.get("score"),
        "blend_mode": result.blend_mode,
        "transformations": result.transformations,
        "fixes_needed": result.fixes_needed,
        "source_sha256": result.source_sha256,
        "fixer_rounds": [],
    }
    return {
        **state,
        "source": {
            **source,
            "license": result.license["license"],
            "permissive": bool(result.license["permissive"]),
            "url": shader.url,
            "author": shader.info.username,
            "name": shader.info.name,
        },
        "tech_spec": tech_spec,
        "glsl_code": result.code,
        "needs_time": result.needs_time,
        "needs_face": result.needs_face,
        "category": result.category,
        "fixes_needed": result.fixes_needed,
        "provenance": provenance,
    }
