"""Fast regex pre-filter for the MirrorBooth shader contract.

The authoritative check is compilation with impellerc (checks/compile.py);
this catches contract violations the compiler would accept but the app would
render wrongly (uniform order!) and gives the coder/fixer readable messages.
"""

from __future__ import annotations

import re

from glslscan import strip_comments

REQUIRED_PATTERNS = [
    (r"#include\s*<flutter/runtime_effect\.glsl>", "#include <flutter/runtime_effect.glsl>"),
    (r"uniform\s+sampler2D\s+uTexture", "uniform sampler2D uTexture"),
    (r"uniform\s+vec2\s+uResolution", "uniform vec2 uResolution"),
    (r"FlutterFragCoord\s*\(\s*\)", "FlutterFragCoord()"),
    (r"out\s+vec4\s+fragColor", "out vec4 fragColor"),
    (r"fragColor\s*=", "fragColor assignment in main()"),
]

FORBIDDEN_PATTERNS = [
    (r"\bgl_FragCoord\b", "gl_FragCoord (use FlutterFragCoord() instead)"),
    (r"#version\b", "#version directive (Flutter adds this automatically)"),
    (r"\b(?:fwidth|dFdx|dFdy)\s*\(", "fwidth/dFdx/dFdy (not supported by the SkSL backend; use 1.5/uResolution.y)"),
    (r"\btexelFetch\s*\(", "texelFetch (use texture() with (p + 0.5) / uResolution)"),
    (r"\btextureSize\s*\(", "textureSize (use uResolution)"),
    (r"\buint\b|\buvec[234]\b", "unsigned integer types (uint/uvec)"),
    (r"\bbool\b\s+\w+\s*;", "uninitialised bool variable (use float 0.0/1.0)"),
    (r"uniform\s+\w+\s+\w+\s*\[", "uniform arrays"),
    (r"\biChannel\d\b", "Shadertoy iChannel (use uTexture)"),
]

UNIFORM_RE = re.compile(r"^\s*uniform\s+(\w+)\s+(\w+)\s*;", re.MULTILINE)


def expected_uniforms(needs_time: bool, needs_face: bool) -> list[tuple[str, str]]:
    """The only uniform sequences _FilterShaderPainter can feed (fixed float slots)."""
    u = [("sampler2D", "uTexture"), ("vec2", "uResolution")]
    if needs_time:
        u.append(("float", "uTime"))
    if needs_face:
        u += [("vec2", "uFaceCenter"), ("float", "uFaceScale")]
    return u


def declared_uniforms(code: str) -> list[tuple[str, str]]:
    return UNIFORM_RE.findall(strip_comments(code))


def uniform_shape(code: str) -> tuple[bool, bool] | None:
    """(needs_time, needs_face) if the declared uniforms match a contract shape, else None."""
    declared = declared_uniforms(code)
    for needs_time in (False, True):
        for needs_face in (False, True):
            if declared == expected_uniforms(needs_time, needs_face):
                return needs_time, needs_face
    return None


def _fmt(uniforms: list[tuple[str, str]]) -> str:
    return ", ".join(f"{t} {n}" for t, n in uniforms)


def check_uniforms(code: str, needs_time: bool | None = None, needs_face: bool | None = None) -> list[str]:
    """Uniform order/completeness. With flags given, the shape must match them exactly."""
    declared = declared_uniforms(code)
    shape = uniform_shape(code)
    if shape is None:
        hint = (
            _fmt(expected_uniforms(bool(needs_time), bool(needs_face)))
            if needs_time is not None
            else "uTexture, uResolution, [uTime], [uFaceCenter, uFaceScale]"
        )
        return [
            f"Uniforms must be declared exactly in contract order ({hint}) with no others; found: {_fmt(declared) or 'none'}"
        ]
    errors = []
    if needs_time is not None and shape[0] != needs_time:
        errors.append(f"needs_time={needs_time} but uTime is {'declared' if shape[0] else 'missing'}")
    if needs_face is not None and shape[1] != needs_face:
        errors.append(f"needs_face={needs_face} but uFaceCenter/uFaceScale are {'declared' if shape[1] else 'missing'}")
    return errors


def check_contract(code: str, needs_time: bool | None = None, needs_face: bool | None = None) -> list[str]:
    errors = []
    for pattern, label in REQUIRED_PATTERNS:
        if not re.search(pattern, code):
            errors.append(f"Missing: {label}")
    stripped = strip_comments(code)
    for pattern, label in FORBIDDEN_PATTERNS:
        if re.search(pattern, stripped):
            errors.append(f"Forbidden: {label}")
    if not code.strip():
        return errors
    errors += check_uniforms(code, needs_time, needs_face)
    return errors
