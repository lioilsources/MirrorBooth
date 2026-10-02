"""Compile a shader the way Flutter's build does (impellerc), with a glslang fallback.

Flags mirror flutter_tools/lib/src/build_system/tools/shader_compiler.dart
(Flutter 3.41-3.44): ``<targets> --iplr --sl=<out> --spirv=<out>.spirv
--input=<frag> --input-type=frag --include=<dir> --include=<shader_lib>``.
iOS builds ``--runtime-stage-metal``; Android ``--sksl --runtime-stage-gles
--runtime-stage-gles3 --runtime-stage-vulkan``. Each target is compiled
separately so errors can be attributed. SkSL (Skia fallback on older Android
devices) is required by default — every shipped MirrorBooth shader passes it.
"""

from __future__ import annotations

import platform
import re
import shutil
import subprocess
import tempfile
from dataclasses import asdict, dataclass, field
from pathlib import Path

from config import settings

TARGETS: list[tuple[str, str]] = [
    ("Metal", "--runtime-stage-metal"),
    ("GLES", "--runtime-stage-gles"),
    ("GLES3", "--runtime-stage-gles3"),
    ("Vulkan", "--runtime-stage-vulkan"),
    ("SkSL", "--sksl"),
]

UNVERIFIED_WARNING = "WARNING: shader was NOT compiled by Impeller (impellerc unavailable) — set FLUTTER_ROOT"


@dataclass
class CompileResult:
    ok: bool
    backend: str  # impellerc | glslang | none
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    targets: dict[str, bool] = field(default_factory=dict)

    @property
    def impeller_verified(self) -> bool:
        return self.backend == "impellerc" and self.ok

    def to_dict(self) -> dict:
        return {**asdict(self), "impeller_verified": self.impeller_verified}


def _host_dirs() -> list[str]:
    system = platform.system().lower()
    machine = platform.machine().lower()
    if system == "darwin":
        return ["darwin-x64", "darwin-arm64"]
    if system == "linux":
        return ["linux-arm64", "linux-x64"] if machine in ("arm64", "aarch64") else ["linux-x64"]
    return ["windows-x64", "windows-arm64"]


def find_impellerc(flutter_root: str | None = None) -> Path | None:
    root = flutter_root if flutter_root is not None else settings.flutter_root
    if not root:
        return None
    engine = Path(root).expanduser() / "bin" / "cache" / "artifacts" / "engine"
    for host in _host_dirs():
        for name in ("impellerc", "impellerc.exe"):
            candidate = engine / host / name
            if candidate.is_file():
                return candidate
    return None


def _clean(text: str, paths: list[Path]) -> list[str]:
    for p in sorted({str(p) for p in paths}, key=len, reverse=True):
        text = text.replace(p, "<shader>" if p.endswith(".frag") else "<tmp>")
    lines = [ln.rstrip() for ln in text.splitlines() if ln.strip()]
    keep = [ln for ln in lines if re.search(r"error|Error|ERROR|failed|undeclared|unknown|no match", ln)]
    return (keep or lines)[:12]


def _compile_impellerc(code: str, impellerc: Path, workdir: Path, require_sksl: bool) -> CompileResult:
    frag = workdir / "shader.frag"
    frag.write_text(code, encoding="utf-8")
    shader_lib = impellerc.parent / "shader_lib"
    result = CompileResult(ok=True, backend="impellerc")
    for label, flag in TARGETS:
        out = workdir / f"out_{label}"
        cmd = [
            str(impellerc),
            flag,
            "--iplr",
            f"--sl={out}",
            f"--spirv={out}.spirv",
            f"--input={frag}",
            "--input-type=frag",
            f"--include={workdir}",
            f"--include={shader_lib}",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        passed = proc.returncode == 0
        result.targets[label] = passed
        if passed:
            continue
        messages = _clean(proc.stdout + "\n" + proc.stderr, [frag, workdir])
        if label == "SkSL" and not require_sksl:
            result.warnings.append("SkSL: shader will not load on the Skia fallback — " + "; ".join(messages[:3]))
            continue
        result.ok = False
        result.errors += [f"impellerc {label}: {m}" for m in messages]
    return result


GLSLANG_SHIM = """#version 310 es
precision highp float;
vec4 FlutterFragCoord() { return gl_FragCoord; }
"""


def _compile_glslang(code: str, workdir: Path) -> CompileResult:
    body = re.sub(r"^\s*#include\s*<flutter/runtime_effect\.glsl>\s*$", "", code, flags=re.MULTILINE)
    probe = workdir / "probe.frag"
    probe.write_text(GLSLANG_SHIM + body, encoding="utf-8")
    proc = subprocess.run(["glslangValidator", str(probe)], capture_output=True, text=True, timeout=30)
    result = CompileResult(ok=proc.returncode == 0, backend="glslang", warnings=[UNVERIFIED_WARNING])
    if not result.ok:
        result.errors = [f"glslang: {m}" for m in _clean(proc.stdout + proc.stderr, [probe, workdir])]
    return result


def compile_shader(
    code: str,
    workdir: Path | None = None,
    flutter_root: str | None = None,
    require_sksl: bool | None = None,
) -> CompileResult:
    require_sksl = settings.compile_require_sksl if require_sksl is None else require_sksl
    impellerc = find_impellerc(flutter_root)
    with tempfile.TemporaryDirectory(prefix="shadergen_") as tmp:
        wd = Path(workdir) if workdir else Path(tmp)
        wd.mkdir(parents=True, exist_ok=True)
        if impellerc:
            return _compile_impellerc(code, impellerc, wd, require_sksl)
        if shutil.which("glslangValidator"):
            return _compile_glslang(code, wd)
    return CompileResult(ok=True, backend="none", warnings=[UNVERIFIED_WARNING + " (glslangValidator missing too)"])
