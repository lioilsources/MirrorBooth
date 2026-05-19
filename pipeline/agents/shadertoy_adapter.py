"""
Deterministic Shadertoy -> Flutter/Impeller GLSL adapter.

Pure functions, no LLM, no network. Used by both the RAG ingest step and the
shadertoy_porter graph node so there is exactly one port implementation.

Shadertoy convention                 Flutter/Impeller contract
---------------------------------    -------------------------------------
void mainImage(out vec4 o,           void main() {
               in vec2 fragCoord)        vec2 fragCoord = FlutterFragCoord().xy;
iResolution (vec3)                   uResolution (vec2)
iTime / iGlobalTime                  uTime
texture(iChannel0, uv)               texture(uTexture, uv)
(no #version)                        (Flutter injects #version)
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field

# Shadertoy inputs we cannot faithfully reproduce from a single camera frame.
# Presence of any of these makes a port low-confidence (still ported, but the
# porter node will not promote it to a direct reference).
UNPORTABLE = [
    "iChannel1",
    "iChannel2",
    "iChannel3",
    "iMouse",
    "iChannelResolution",
    "iChannelTime",
    "texelFetch",
    "iDate",
    "iFrame",
    "iTimeDelta",
    "iSampleRate",
]

_SIGNATURE_RE = re.compile(
    r"void\s+mainImage\s*\(\s*out\s+vec4\s+(\w+)\s*,\s*(?:in\s+)?vec2\s+(\w+)\s*\)",
    re.S,
)


@dataclass
class PortResult:
    code: str
    applied: list[str] = field(default_factory=list)
    unported_constructs: list[str] = field(default_factory=list)

    @property
    def is_clean(self) -> bool:
        return not self.unported_constructs


def _comment_mask(code: str) -> list[bool]:
    """Return a per-character mask, True where the char is inside a comment."""
    mask = [False] * len(code)
    i = 0
    n = len(code)
    while i < n:
        two = code[i : i + 2]
        if two == "//":
            while i < n and code[i] != "\n":
                mask[i] = True
                i += 1
        elif two == "/*":
            while i < n and code[i - 1 : i + 1] != "*/":
                mask[i] = True
                i += 1
            if i < n:
                mask[i] = True
                i += 1
        else:
            i += 1
    return mask


def _sub_outside(pattern: re.Pattern, repl: str, code: str, mask: list[bool],
                 lo: int = 0, hi: int | None = None) -> str:
    """re.sub but only for matches that start outside a comment and within [lo, hi)."""
    if hi is None:
        hi = len(code)
    out = []
    pos = 0
    for m in pattern.finditer(code):
        if m.start() < lo or m.start() >= hi or mask[m.start()]:
            continue
        out.append(code[pos : m.start()])
        out.append(m.expand(repl))
        pos = m.end()
    out.append(code[pos:])
    return "".join(out)


def is_shadertoy_source(src: str) -> bool:
    return bool(_SIGNATURE_RE.search(src)) and "FlutterFragCoord" not in src


def _find_unported(code: str, mask: list[bool]) -> list[str]:
    found = []
    for name in UNPORTABLE:
        for m in re.finditer(rf"\b{re.escape(name)}\b", code):
            if not mask[m.start()]:
                found.append(name)
                break
    return found


def port_shadertoy(src: str, needs_time: bool | None = None) -> PortResult:
    """Port Shadertoy-convention GLSL to the Flutter/Impeller contract."""
    applied: list[str] = []
    code = src

    # 1. strip #version directives (Flutter injects its own)
    new_code = re.sub(r"^[ \t]*#version\b.*$", "", code, flags=re.M)
    if new_code != code:
        applied.append("strip #version")
        code = new_code

    mask = _comment_mask(code)

    # 2. record unportable constructs
    unported = _find_unported(code, mask)

    # 3. decide whether uTime is required
    has_itime = bool(
        re.search(r"\b(iTime|iGlobalTime)\b", code)
    ) and any(
        not mask[m.start()]
        for m in re.finditer(r"\b(iTime|iGlobalTime)\b", code)
    )
    want_time = has_itime if needs_time is None else (needs_time or has_itime)

    # 4. substitutions (outside comments). Order matters: dotted before bare.
    code = _sub_outside(re.compile(r"\biResolution\.xy\b"), "uResolution", code, mask)
    mask = _comment_mask(code)
    code = _sub_outside(re.compile(r"\biResolution\.x\b"), "uResolution.x", code, mask)
    mask = _comment_mask(code)
    code = _sub_outside(re.compile(r"\biResolution\.y\b"), "uResolution.y", code, mask)
    mask = _comment_mask(code)
    code = _sub_outside(re.compile(r"\biResolution\b"), "vec3(uResolution, 0.0)", code, mask)
    mask = _comment_mask(code)
    code = _sub_outside(re.compile(r"\b(iTime|iGlobalTime)\b"), "uTime", code, mask)
    mask = _comment_mask(code)
    code = _sub_outside(re.compile(r"\biChannel0\b"), "uTexture", code, mask)
    mask = _comment_mask(code)
    code = _sub_outside(re.compile(r"\btexture2D\b"), "texture", code, mask)
    mask = _comment_mask(code)
    applied.append("rewrite iResolution/iTime/iChannel0")

    # 5. entry-point conversion: mainImage -> main, with body color/coord rename
    m = _SIGNATURE_RE.search(code)
    if not m or mask[m.start()]:
        unported.append("mainImage signature not found")
    else:
        out_name, coord_name = m.group(1), m.group(2)
        sig_end = m.end()
        # locate body opening brace (skip comments)
        brace_open = -1
        for i in range(sig_end, len(code)):
            if not mask[i] and code[i] == "{":
                brace_open = i
                break
        if brace_open == -1:
            unported.append("mainImage body not found")
        else:
            depth = 0
            brace_close = -1
            for i in range(brace_open, len(code)):
                if mask[i]:
                    continue
                c = code[i]
                if c == "{":
                    depth += 1
                elif c == "}":
                    depth -= 1
                    if depth == 0:
                        brace_close = i
                        break
            if brace_close == -1:
                unported.append("unbalanced mainImage body")
            else:
                # rename out-color identifier -> fragColor within the body span
                if out_name != "fragColor":
                    code = _sub_outside(
                        re.compile(rf"\b{re.escape(out_name)}\b"),
                        "fragColor",
                        code,
                        mask,
                        lo=brace_open,
                        hi=brace_close + 1,
                    )
                # inject the fragCoord declaration as the first body statement
                inject = f"\n    vec2 {coord_name} = FlutterFragCoord().xy;"
                code = code[: brace_open + 1] + inject + code[brace_open + 1 :]
                # replace the signature itself with void main()
                code = code[: m.start()] + "void main()" + code[brace_open:]
                applied.append("mainImage -> main")

    # 6. prepend the Flutter/Impeller header
    header_lines = [
        "#include <flutter/runtime_effect.glsl>",
        "",
        "uniform sampler2D uTexture;",
        "uniform vec2 uResolution;",
    ]
    if want_time:
        header_lines.append("uniform float uTime;")
    header_lines += ["", "out vec4 fragColor;", "", ""]
    code = "\n".join(header_lines) + code.lstrip("\n")
    applied.append("prepend Flutter contract header")

    # 7. normalize: strip trailing spaces, single trailing newline
    code = "\n".join(line.rstrip() for line in code.splitlines())
    code = code.rstrip("\n") + "\n"

    # dedupe unported preserving order
    seen = set()
    unported = [u for u in unported if not (u in seen or seen.add(u))]

    return PortResult(code=code, applied=applied, unported_constructs=unported)
