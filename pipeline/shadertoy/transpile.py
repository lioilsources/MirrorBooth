"""Deterministic Shadertoy -> MirrorBooth transpiler (port mode).

Implements the "Kontrakt: Shadertoy -> MirrorBooth" table of the ShaderGen v2
plan. Output block order:

  1. attribution header
  2. #include <flutter/runtime_effect.glsl>
  3. uniforms in contract order: uTexture, uResolution, [uTime], [uFaceCenter, uFaceScale]
  4. out vec4 fragColor;
  5. shims (iResolution, iTime, iTimeDelta, iFrame, iMouse) + stSample / stNoiseTex
  6. Common code, Image code
  7. generated main() (composite template for procedural shaders)

Anything that cannot be converted deterministically is listed in
``fixes_needed`` for the LLM fixer; the transpiler never guesses.
"""

from __future__ import annotations

import hashlib
import re
from dataclasses import asdict, dataclass, field

from config import PIPELINE_DIR
from shadertoy.license import LicenseInfo, classify_shader
from shadertoy.model import Shader
from shadertoy.portability import classify

TEMPLATES_DIR = PIPELINE_DIR / "templates"
SNIPPETS_DIR = PIPELINE_DIR / "snippets"

BLEND_MODES = {
    "multiply": "    return cam * fx;",
    "screen": "    return 1.0 - (1.0 - cam) * (1.0 - fx);",
    "overlay": "    return stOverlay(cam, fx);",
    "luma_mask": "    return mix(cam, fx, smoothstep(0.2, 0.8, stLuma(cam)));",
    "edge_mask": "    return mix(cam, fx, stEdge(uv));",
}
DEFAULT_BLEND = "screen"

# fixes_needed vocabulary (consumed by agents/llm_fixer.py)
FIX_DERIVATIVES = "derivatives"
FIX_TEXEL_FETCH = "texel_fetch"  # texelFetch on anything but iChannel0
FIX_TEXTURE_SIZE = "texture_size"  # textureSize on anything but iChannel0


class TranspileError(ValueError):
    """The shader cannot be ported (license or unsupported category)."""


@dataclass
class TranspileResult:
    code: str
    needs_time: bool
    needs_face: bool
    category: str
    fixes_needed: list[str] = field(default_factory=list)
    attribution_header: str = ""
    transformations: list[str] = field(default_factory=list)
    blend_mode: str = ""
    source_sha256: str = ""
    license: dict = field(default_factory=dict)
    portability: dict = field(default_factory=dict)

    def to_dict(self) -> dict:
        return asdict(self)


# ---------------------------------------------------------------------------
# small text helpers
# ---------------------------------------------------------------------------


def _split_args(text: str) -> list[str]:
    """Split a call's argument text on top-level commas."""
    args, depth, cur = [], 0, []
    for ch in text:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == "," and depth == 0:
            args.append("".join(cur).strip())
            cur = []
        else:
            cur.append(ch)
    if cur or args:
        args.append("".join(cur).strip())
    return args


def _close_paren(code: str, open_idx: int) -> int:
    depth = 0
    for i in range(open_idx, len(code)):
        if code[i] == "(":
            depth += 1
        elif code[i] == ")":
            depth -= 1
            if depth == 0:
                return i
    raise TranspileError(f"unbalanced parentheses near: {code[open_idx : open_idx + 60]!r}")


def rewrite_calls(code: str, func_pattern: str, rewrite) -> tuple[str, int]:
    """Replace every ``<func>(args)`` whose name matches ``func_pattern``.

    ``rewrite(name, args) -> str | None``; None keeps the call unchanged.
    """
    out, pos, count = [], 0, 0
    regex = re.compile(r"\b(" + func_pattern + r")\s*\(")
    while True:
        m = regex.search(code, pos)
        if not m:
            break
        open_idx = m.end() - 1
        close_idx = _close_paren(code, open_idx)
        args = _split_args(code[open_idx + 1 : close_idx])
        replacement = rewrite(m.group(1), args)
        if replacement is None:
            out.append(code[pos : m.end()])
            pos = m.end()
            continue
        out.append(code[pos : m.start()])
        out.append(replacement)
        pos = close_idx + 1
        count += 1
    out.append(code[pos:])
    return "".join(out), count


def _strip_directives(code: str, log: list[str]) -> str:
    new = re.sub(r"^[ \t]*#version[^\n]*\n?", "", code, flags=re.MULTILINE)
    if new != code:
        log.append("removed #version")
    newer = re.sub(r"^[ \t]*precision\s+\w+\s+\w+\s*;[ \t]*\n?", "", new, flags=re.MULTILINE)
    if newer != new:
        log.append("removed precision statements")
    return newer


def _uses(code: str, name: str) -> bool:
    return re.search(r"\b" + name + r"\b", code) is not None


# ---------------------------------------------------------------------------
# channel 0 rewriting
# ---------------------------------------------------------------------------


def _rewrite_channel0(code: str, sampler_fn: str, wrap_repeat: bool, log: list[str], fixes: list[str]) -> str:
    def rewrite(name: str, args: list[str]) -> str | None:
        if not args or args[0] != "iChannel0":
            return None
        if name == "texelFetch":
            if len(args) < 2:
                return None
            texel_size = "vec2(256.0)" if sampler_fn == "stNoiseTex" else "uResolution"
            return f"{sampler_fn}((vec2({args[1]}) + 0.5) / {texel_size})"
        if len(args) < 2:
            return None
        uv = args[1]
        if wrap_repeat:
            uv = f"fract({uv})"
        return f"{sampler_fn}({uv})"

    code, n = rewrite_calls(code, r"texture|textureLod|texture2D|textureGrad|texelFetch", rewrite)
    if n:
        log.append(f"iChannel0 sampling -> {sampler_fn}() ({n}x{', wrap=repeat via fract()' if wrap_repeat else ''})")

    def size_rewrite(name: str, args: list[str]) -> str | None:
        if args and args[0] == "iChannel0":
            return "ivec2(uResolution)"
        return None

    code, n = rewrite_calls(code, r"textureSize", size_rewrite)
    if n:
        log.append(f"textureSize(iChannel0) -> ivec2(uResolution) ({n}x)")
    if _uses(code, "textureSize") and FIX_TEXTURE_SIZE not in fixes:
        fixes.append(FIX_TEXTURE_SIZE)

    new = re.sub(r"\biChannelResolution\s*\[\s*0\s*\]", "vec3(uResolution, 1.0)", code)
    if new != code:
        log.append("iChannelResolution[0] -> vec3(uResolution, 1.0)")
    return new


# ---------------------------------------------------------------------------
# main entry
# ---------------------------------------------------------------------------


def attribution_header(shader: Shader, lic: LicenseInfo) -> str:
    name = shader.info.name.replace("\n", " ")
    lines = [
        f'// Ported from {shader.url} — "{name}" by {shader.info.username}, {lic.license}',
        "// Converted to the MirrorBooth/Flutter shader contract by ShaderGen v2 (pipeline/shadertoy/transpile.py).",
    ]
    if not lic.permissive:
        lines.append("// LICENSE NOT PERMISSIVE — local experiment only, must not ship (license_ok=false).")
    return "\n".join(lines)


def transpile(
    shader: Shader,
    blend_mode: str | None = None,
    allow_nc_license: bool = False,
) -> TranspileResult:
    lic = classify_shader(shader)
    port = classify(shader)

    if not lic.permissive and not allow_nc_license:
        raise TranspileError(
            f"Shader {shader.id} is licensed '{lic.license}' ({lic.reason}). Port mode only accepts explicitly "
            "permissive licenses (MIT, CC0, public domain, CC BY, Unlicense, BSD). Use inspire mode "
            "(run.py --style ...) to take the technique, not the code."
        )
    if port.category == "unsupported":
        raise TranspileError(
            f"Shader {shader.id} cannot be ported: {'; '.join(port.unsupported_reasons)}. "
            "Its text can still serve as RAG inspiration (rag/ingest_shadertoy.py)."
        )

    image = shader.image_pass
    assert image is not None  # guaranteed by classify()
    log: list[str] = []
    fixes: list[str] = []

    common = _strip_directives(shader.common_code, log) if shader.common_code.strip() else ""
    body = _strip_directives(image.code, log)
    joined = common + "\n" + body

    channel0 = next((i for i in image.inputs if i.channel == 0), None)
    wrap_repeat = bool(channel0 and channel0.sampler.wrap == "repeat")

    if port.category == "data_texture":
        # Deterministic stand-in for the preset noise texture (snippets/noise.glsl); recorded
        # as a transformation, not a fix — the LLM only gets what cannot be done mechanically.
        sampler_fn = "stNoiseTex"
        # noise textures are sampled with repeat wrap already inside stNoiseTex
        common = _rewrite_channel0(common, sampler_fn, False, log, fixes)
        body = _rewrite_channel0(body, sampler_fn, False, log, fixes)
    elif port.category == "image_filter":
        sampler_fn = "stSample"
        common = _rewrite_channel0(common, sampler_fn, wrap_repeat, log, fixes)
        body = _rewrite_channel0(body, sampler_fn, wrap_repeat, log, fixes)
    else:
        sampler_fn = ""

    remaining = common + "\n" + body
    if re.search(r"\b(?:dFdx|dFdy|fwidth)\s*\(", remaining):
        fixes.append(FIX_DERIVATIVES)
    if _uses(remaining, "texelFetch"):
        fixes.append(FIX_TEXEL_FETCH)

    needs_time = any(_uses(joined, n) for n in ("iTime", "iGlobalTime", "iFrame"))
    needs_face = _uses(joined, "iMouse")

    # --- uniforms (contract order) ---
    uniforms = ["uniform sampler2D uTexture;", "uniform vec2 uResolution;"]
    if needs_time:
        uniforms.append("uniform float uTime;")
    if needs_face:
        uniforms += ["uniform vec2 uFaceCenter;", "uniform float uFaceScale;"]

    # --- shims ---
    shims = ["#define iResolution vec3(uResolution, 1.0)"]
    if _uses(joined, "iTime"):
        shims.append("#define iTime uTime")
    if _uses(joined, "iGlobalTime"):
        shims.append("#define iGlobalTime uTime")
    if _uses(joined, "iTimeDelta"):
        shims.append("const float iTimeDelta = 1.0 / 60.0;")
    if _uses(joined, "iFrame"):
        shims.append("#define iFrame int(uTime * 60.0)")
    if needs_face:
        # Face centre (0..1, top-left origin) as the Shadertoy mouse (pixels, bottom-left origin).
        shims.append(
            "#define iMouse vec4(uFaceCenter.x * uResolution.x, (1.0 - uFaceCenter.y) * uResolution.y, 0.0, 0.0)"
        )
    shim_names = [re.match(r"(?:#define|const\s+float)\s+(\w+)", s).group(1) for s in shims]
    log.append("uniform shims: " + ", ".join(shim_names))

    helpers = []
    if sampler_fn == "stSample":
        helpers.append(
            "// Shadertoy UV (bottom-left origin) -> camera texture (top-left origin)\n"
            "vec4 stSample(vec2 uv) { return texture(uTexture, vec2(uv.x, 1.0 - uv.y)); }"
        )
    elif sampler_fn == "stNoiseTex":
        helpers.append((SNIPPETS_DIR / "noise.glsl").read_text(encoding="utf-8").strip())

    # --- main ---
    if port.category == "procedural":
        blend = blend_mode or DEFAULT_BLEND
        if blend not in BLEND_MODES:
            raise TranspileError(f"unknown blend mode {blend!r}; expected one of {sorted(BLEND_MODES)}")
        template = (TEMPLATES_DIR / "composite_main.glsl").read_text(encoding="utf-8")
        main_code = template.replace("{{BLEND_MODE}}", blend).replace("{{BLEND_BODY}}", BLEND_MODES[blend]).strip()
        log.append(f"composite main() with blend mode '{blend}'")
    else:
        blend = ""
        main_code = (
            "void main() {\n"
            "    vec2 fc = FlutterFragCoord().xy;\n"
            "    fc.y = uResolution.y - fc.y;  // Flutter: top-left origin, Shadertoy: bottom-left\n"
            "    vec4 c = vec4(0.0);\n"
            "    mainImage(c, fc);\n"
            "    fragColor = vec4(clamp(c.rgb, 0.0, 1.0), 1.0);\n"
            "}"
        )
        log.append("generated main() with Y flip")

    header = attribution_header(shader, lic)
    sections = [
        header,
        "#include <flutter/runtime_effect.glsl>",
        "\n".join(uniforms),
        "out vec4 fragColor;",
        "\n".join(shims),
        *helpers,
    ]
    if common.strip():
        sections.append("// ---- Shadertoy: Common ----\n" + common.strip())
    sections.append("// ---- Shadertoy: Image ----\n" + body.strip())
    sections.append("// ---- MirrorBooth entry point ----\n" + main_code)
    code = "\n\n".join(sections) + "\n"

    return TranspileResult(
        code=code,
        needs_time=needs_time,
        needs_face=needs_face,
        category=port.category,
        fixes_needed=fixes,
        attribution_header=header,
        transformations=log,
        blend_mode=blend,
        source_sha256=hashlib.sha256(shader.all_code.encode("utf-8")).hexdigest(),
        license=lic.to_dict(),
        portability=port.to_dict(),
    )


def detect_fixes(code: str) -> list[str]:
    """Blocking constructs still present in (already transpiled) code."""
    from glslscan import strip_comments

    code = strip_comments(code)
    fixes = []
    if re.search(r"\b(?:dFdx|dFdy|fwidth)\s*\(", code):
        fixes.append(FIX_DERIVATIVES)
    if _uses(code, "texelFetch"):
        fixes.append(FIX_TEXEL_FETCH)
    if _uses(code, "textureSize"):
        fixes.append(FIX_TEXTURE_SIZE)
    return fixes
