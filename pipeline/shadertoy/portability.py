"""Portability classifier: can a Shadertoy shader become a MirrorBooth filter?

Categories (see "Kontrakt: Shadertoy -> MirrorBooth" in the plan):

* ``image_filter`` — samples ``iChannel0`` (webcam/video, or a texture read in
  screen space) and nothing else. Direct port. Priority 1.
* ``procedural``   — samples no channel. Ported via the composite template.
* ``data_texture`` — reads ``iChannel0`` as a lookup/noise texture; needs the
  LLM fixer to substitute procedural noise.
* ``unsupported``  — multi-pass buffers, cubemaps, sound, keyboard, extra
  channels, ``iDate`` & co. Not portable (text still goes to RAG).
"""

from __future__ import annotations

import re
from dataclasses import asdict, dataclass, field

from config import settings
from glslscan import loop_summary, strip_comments
from shadertoy.model import Shader

CATEGORIES = ("image_filter", "procedural", "data_texture", "unsupported")
CATEGORY_PRIORITY = {"image_filter": 1, "procedural": 2, "data_texture": 3, "unsupported": 9}

UNSUPPORTED_PASSES = {"buffer", "sound", "cubemap"}
UNSUPPORTED_CTYPES = {"buffer", "cubemap", "keyboard", "music", "musicstream", "mic", "volume"}
IMAGE_CTYPES = {"webcam", "video"}

_UNSUPPORTED_UNIFORMS = [
    (r"\biDate\b", "iDate"),
    (r"\biSampleRate\b", "iSampleRate"),
    (r"\biChannelTime\b", "iChannelTime"),
    (r"\biChannelResolution\s*\[\s*[1-3]\s*\]", "iChannelResolution[1..3]"),
    (r"\biChannel[1-3]\b", "iChannel1..3"),
    (r"\bmainSound\s*\(", "sound output"),
    (r"\bmainCubemap\s*\(", "cubemap output"),
    (r"\bmainVR\s*\(", "VR entry point"),
]

# (regex, issue label, score penalty) — constructs Impeller/our contract cannot take as-is.
_PENALTIES = [
    (r"\b(?:dFdx|dFdy|fwidth)\s*\(", "derivatives (dFdx/dFdy/fwidth)", 10),
    (r"\btexelFetch\s*\(", "texelFetch", 15),
    (r"\btextureSize\s*\(", "textureSize", 5),
    (r"\buint\b|\buvec[234]\b", "unsigned ints", 5),
    (r"\bbool\s+\w+\s*[;=]", "bool variables", 3),
    (r"\b(?:float|int|vec[234])\s+\w+\s*\[\s*\w*\s*\]\s*(?:=|;)", "arrays", 5),
    (r"\bswitch\s*\(", "switch statement", 3),
    (r"\b(?:floatBitsToUint|uintBitsToFloat|floatBitsToInt|intBitsToFloat)\s*\(", "bit casts", 10),
]

_SCREEN_SPACE_UV = re.compile(r"fragCoord(?:\.xy)?\s*/\s*iResolution(?:\.xy)?")
_DATA_TEXTURE_HINT = re.compile(r"/\s*(?:256|64|1024|32)\.0*\b|\+\s*0\.5\s*\)\s*/")
_NOISE_FUNC = re.compile(r"\b(?:\w*noise\w*|hash\w*|rand\w*|fbm\w*)\s*\(", re.IGNORECASE)


@dataclass
class PortabilityReport:
    category: str
    score: int
    issues: list[str] = field(default_factory=list)
    unsupported_reasons: list[str] = field(default_factory=list)
    uses_time: bool = False
    uses_mouse: bool = False
    channel0_ctype: str = ""
    loops: dict = field(default_factory=dict)
    line_count: int = 0

    def to_dict(self) -> dict:
        return asdict(self)


def _channel_inputs(shader: Shader) -> dict[int, str]:
    image = shader.image_pass
    return {inp.channel: inp.ctype for inp in (image.inputs if image else [])}


def _texture_calls(code: str, channel: str = "iChannel0") -> list[tuple[int, str]]:
    """(offset, argument text) of each texture*(iChannel0, ...) call."""
    calls = []
    for m in re.finditer(r"\b(?:texture|textureLod|texture2D|textureGrad|texelFetch)\s*\(\s*" + channel + r"\b", code):
        depth = 0
        start = code.find("(", m.start())
        i = start
        for i in range(start, len(code)):
            if code[i] == "(":
                depth += 1
            elif code[i] == ")":
                depth -= 1
                if depth == 0:
                    break
        calls.append((m.start(), code[start + 1 : i]))
    return calls


def _enclosing_function(code: str, offset: int) -> str:
    """Name of the function whose body contains ``offset`` (best effort)."""
    best = ""
    for m in re.finditer(r"\b[A-Za-z_]\w*\s+([A-Za-z_]\w*)\s*\([^;{)]*\)\s*\{", code):
        if m.start() < offset:
            best = m.group(1)
        else:
            break
    return best


def _is_data_texture_usage(code: str) -> bool:
    calls = _texture_calls(code)
    if not calls:
        return False
    for offset, args in calls:
        if "texelFetch" in code[offset : offset + 12]:
            return True
        if _DATA_TEXTURE_HINT.search(args):
            return True
        if _NOISE_FUNC.match(_enclosing_function(code, offset) + "("):
            return True
    return not _SCREEN_SPACE_UV.search(code)


def classify(shader: Shader) -> PortabilityReport:
    image = shader.image_pass
    common = shader.common_code
    code = strip_comments((common + "\n\n" + image.code) if image else common)
    report = PortabilityReport(
        category="unsupported", score=0, line_count=len([ln for ln in code.splitlines() if ln.strip()])
    )

    if image is None:
        report.unsupported_reasons.append("no Image pass")
        return report

    for p in shader.renderpass:
        if p.type in UNSUPPORTED_PASSES:
            report.unsupported_reasons.append(f"{p.type} pass ({p.name or p.type}) — multi-pass is out of scope")
    channels = _channel_inputs(shader)
    for channel, ctype in sorted(channels.items()):
        if ctype in UNSUPPORTED_CTYPES:
            report.unsupported_reasons.append(f"iChannel{channel} is a {ctype}")
    for pattern, label in _UNSUPPORTED_UNIFORMS:
        if re.search(pattern, code):
            report.unsupported_reasons.append(f"uses {label}")

    report.uses_time = bool(re.search(r"\biTime\b|\biFrame\b|\biTimeDelta\b|\biGlobalTime\b", code))
    report.uses_mouse = bool(re.search(r"\biMouse\b", code))
    report.channel0_ctype = channels.get(0, "")
    report.loops = loop_summary(code)

    if report.unsupported_reasons:
        report.unsupported_reasons = list(dict.fromkeys(report.unsupported_reasons))
        return report

    uses_ch0 = bool(re.search(r"\biChannel0\b", code))
    if not uses_ch0:
        report.category = "procedural"
    elif report.channel0_ctype in IMAGE_CTYPES:
        report.category = "image_filter"
    elif _is_data_texture_usage(code):
        report.category = "data_texture"
    else:
        report.category = "image_filter"

    report.score = _score(report, code, has_common=bool(common.strip()))
    return report


def _score(report: PortabilityReport, code: str, has_common: bool) -> int:
    score = 100
    score -= {"image_filter": 0, "procedural": 15, "data_texture": 30}[report.category]

    for pattern, label, penalty in _PENALTIES:
        if re.search(pattern, code):
            report.issues.append(label)
            score -= penalty

    if has_common:
        report.issues.append("Common tab")
        score -= 5

    if report.line_count > 150:
        report.issues.append(f"long ({report.line_count} lines)")
        score -= min(25, (report.line_count - 150) // 10)

    loops = report.loops
    if loops.get("max_depth", 0) > settings.perf_max_loop_depth:
        report.issues.append(f"loop nesting depth {loops['max_depth']}")
        score -= 15
    if loops.get("fetch_cost", 0) > settings.perf_max_loop_fetch_budget:
        report.issues.append(f"loop fetch cost {loops['fetch_cost']}")
        score -= 15
    steps = loops.get("raymarch_steps", 0)
    if steps > settings.perf_raymarch_max_steps:
        report.issues.append(f"raymarch {steps} steps")
        score -= 30
    elif steps > settings.perf_raymarch_warn_steps:
        report.issues.append(f"raymarch {steps} steps")
        score -= 15
    elif loops.get("max_iterations", 0) > settings.perf_raymarch_max_steps:
        report.issues.append(f"loop with {loops['max_iterations']} iterations")
        score -= 10
    if loops.get("unknown_bounds", 0):
        report.issues.append(f"{loops['unknown_bounds']} loop(s) with dynamic bounds")
        score -= 5 * loops["unknown_bounds"]

    return max(0, min(100, score))
