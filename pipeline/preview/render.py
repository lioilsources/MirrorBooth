"""Render a MirrorBooth shader headlessly with desktop OpenGL (moderngl).

This is a stand-in for the device, not proof: desktop GL 3.3 accepts things
Impeller may not (compile validation is checks/compile.py's job). It exists to
catch black frames, NaNs, upside-down ports and do-nothing shaders, and to give
the vision ranker something to look at.

Shim: ``#version 330 core`` replaces the Flutter include and
``FlutterFragCoord()`` becomes a macro with Flutter's top-left origin. The
camera texture is uploaded top row first, so ``texture(uTexture, uv)`` sees the
same orientation as in the app.
"""

from __future__ import annotations

import platform
import re
import time
from dataclasses import dataclass, field
from pathlib import Path

from config import PIPELINE_DIR

TEST_INPUT_DIR = PIPELINE_DIR / "assets" / "test_input"
DEFAULT_TIMES = (0.0, 0.7, 1.9)
FACE_CENTER = (0.5, 0.5)
FACE_SCALE = 0.35

VERTEX_SHADER = """#version 330 core
in vec2 in_pos;
void main() { gl_Position = vec4(in_pos, 0.0, 1.0); }
"""

GL_SHIM = """#version 330 core
#define FlutterFragCoord() vec4(gl_FragCoord.x, uResolution.y - gl_FragCoord.y, 0.0, 1.0)
"""


class PreviewUnavailable(RuntimeError):
    """No headless GL context could be created on this machine."""


@dataclass
class RenderResult:
    frames: list  # numpy uint8 arrays HxWx3, top row first
    times: list[float]
    render_ms: float
    input_image: object = None  # numpy array of the input
    warnings: list[str] = field(default_factory=list)


def to_desktop_gl(code: str) -> str:
    body = re.sub(r"^\s*#include\s*<flutter/runtime_effect\.glsl>\s*$", "", code, flags=re.MULTILINE)
    return GL_SHIM + body


def create_context():
    """Standalone GL >= 3.3 context: EGL on Linux (llvmpipe works), CGL on macOS."""
    try:
        import moderngl
    except ImportError as exc:
        raise PreviewUnavailable("moderngl not installed (pip install moderngl numpy pillow)") from exc
    attempts = [{"backend": "egl"}, {}] if platform.system() == "Linux" else [{}]
    errors = []
    for kwargs in attempts:
        try:
            return moderngl.create_standalone_context(require=330, **kwargs)
        except Exception as exc:  # noqa: BLE001 - backend-specific failures
            errors.append(f"{kwargs.get('backend', 'default')}: {exc}")
    raise PreviewUnavailable("no headless OpenGL 3.3 context (" + "; ".join(errors) + ")")


def default_input() -> Path:
    images = sorted(p for p in TEST_INPUT_DIR.glob("*.png") if not p.name.startswith("placeholder"))
    return images[0] if images else TEST_INPUT_DIR / "placeholder_selfie.png"


def load_image(path: Path):
    import numpy as np
    from PIL import Image

    return np.asarray(Image.open(path).convert("RGB"), dtype=np.uint8)


def render(
    code: str,
    image,
    needs_time: bool,
    needs_face: bool,
    times: tuple[float, ...] = DEFAULT_TIMES,
    ctx=None,
) -> RenderResult:
    import numpy as np

    own_ctx = ctx is None
    ctx = ctx or create_context()
    try:
        h, w = image.shape[:2]
        try:
            program = ctx.program(vertex_shader=VERTEX_SHADER, fragment_shader=to_desktop_gl(code))
        except Exception as exc:  # moderngl.Error
            raise ValueError(f"desktop GL compile failed: {exc}") from exc
        quad = ctx.buffer(np.array([-1, -1, 3, -1, -1, 3], dtype="f4").tobytes())
        vao = ctx.vertex_array(program, [(quad, "2f", "in_pos")])
        tex = ctx.texture((w, h), 3, np.ascontiguousarray(image).tobytes())
        tex.filter = (ctx.LINEAR, ctx.LINEAR)
        tex.repeat_x = tex.repeat_y = False  # Flutter samples the camera image with clamp
        fbo = ctx.simple_framebuffer((w, h), components=4)
        fbo.use()

        def set_uniform(name, value):
            if name in program:
                program[name].value = value

        set_uniform("uResolution", (float(w), float(h)))
        if needs_face:
            set_uniform("uFaceCenter", FACE_CENTER)
            set_uniform("uFaceScale", FACE_SCALE)
        if "uTexture" in program:
            program["uTexture"].value = 0
        tex.use(0)

        frames = []
        frame_times = list(times) if needs_time else [times[0]]
        start = time.perf_counter()
        for t in frame_times:
            if needs_time:
                set_uniform("uTime", float(t))
            fbo.clear(0.0, 0.0, 0.0, 1.0)
            vao.render()
            raw = fbo.read(components=3, alignment=1)
            frame = np.frombuffer(raw, dtype=np.uint8).reshape(h, w, 3)[::-1].copy()  # GL rows are bottom-up
            frames.append(frame)
        render_ms = (time.perf_counter() - start) * 1000 / max(1, len(frame_times))
        for obj in (vao, quad, tex, fbo, program):
            obj.release()
        return RenderResult(frames=frames, times=frame_times, render_ms=render_ms, input_image=image)
    finally:
        if own_ctx:
            ctx.release()


def save_frames(result: RenderResult, out_dir: Path) -> list[str]:
    from PIL import Image

    out_dir.mkdir(parents=True, exist_ok=True)
    paths = []
    for t, frame in zip(result.times, result.frames, strict=True):
        path = out_dir / f"preview_t{t:g}.png"
        Image.fromarray(frame).save(path)
        paths.append(str(path))
    return paths
