import re
import shutil
import subprocess
import tempfile
from state import ShaderGenState

REQUIRED_PATTERNS = [
    (r'#include\s*<flutter/runtime_effect\.glsl>', "#include <flutter/runtime_effect.glsl>"),
    (r'uniform\s+sampler2D\s+uTexture', "uniform sampler2D uTexture"),
    (r'uniform\s+vec2\s+uResolution', "uniform vec2 uResolution"),
    (r'FlutterFragCoord\s*\(\s*\)', "FlutterFragCoord()"),
    (r'out\s+vec4\s+fragColor', "out vec4 fragColor"),
    (r'fragColor\s*=', "fragColor assignment in main()"),
]

FORBIDDEN_PATTERNS = [
    (r'\bgl_FragCoord\b', "gl_FragCoord (use FlutterFragCoord() instead)"),
    (r'#version\b', "#version directive (Flutter adds this automatically)"),
]


def _contract_check(code: str) -> list[str]:
    errors = []
    for pattern, label in REQUIRED_PATTERNS:
        if not re.search(pattern, code):
            errors.append(f"Missing: {label}")
    for pattern, label in FORBIDDEN_PATTERNS:
        if re.search(pattern, code):
            errors.append(f"Forbidden: {label}")
    return errors


def _glslang_check(code: str) -> list[str]:
    if not shutil.which("glslangValidator"):
        return []  # tool not installed — skip silently

    # glslangValidator needs a #version to parse; we inject one temporarily for syntax check only
    probe_code = "#version 300 es\nprecision mediump float;\n" + code
    with tempfile.NamedTemporaryFile(suffix=".frag", mode="w", delete=False) as f:
        f.write(probe_code)
        tmp_path = f.name

    result = subprocess.run(
        ["glslangValidator", tmp_path],
        capture_output=True,
        text=True,
        timeout=10,
    )
    if result.returncode != 0:
        lines = (result.stdout + result.stderr).strip().splitlines()
        # strip the temp file path from messages
        cleaned = [l.replace(tmp_path, "<shader>") for l in lines if l.strip()]
        return cleaned
    return []


def validator_node(state: ShaderGenState) -> ShaderGenState:
    code = state.get("glsl_code", "")
    errors: list[str] = []

    errors.extend(_contract_check(code))
    errors.extend(_glslang_check(code))

    return {
        **state,
        "validation_errors": errors,
        "retry_count": state.get("retry_count", 0) + (1 if errors else 0),
    }
