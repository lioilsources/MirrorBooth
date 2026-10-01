"""GLSL chunking + technique tagging shared by both RAG ingest scripts."""

from __future__ import annotations

import re

LOCAL_COLLECTION = "glsl_shaders"
SHADERTOY_COLLECTION = "shadertoy_shaders"

TECHNIQUE_TAGS = {
    # MirrorBooth vocabulary (v1)
    "sobel": "sobel_edge_detection",
    "edge": "edge_detection",
    "blur": "gaussian_blur",
    "gaussian": "gaussian_blur",
    "cel": "cel_shading",
    "toon": "cel_shading",
    "noise": "noise",
    "random": "noise",
    "hue": "hue_rotation",
    "hsv": "hue_rotation",
    "posteriz": "posterization",
    "quantiz": "color_quantization",
    "floor": "color_quantization",
    "chromat": "chromatic_aberration",
    "offset": "chromatic_aberration",
    "halftone": "halftone",
    "pixel": "pixelation",
    "glitch": "glitch",
    "watercolor": "watercolor",
    "oil": "oil_painting",
    "sketch": "sketch",
    "pencil": "sketch",
    "thermal": "thermal",
    "neon": "neon",
    "crt": "crt",
    "sin(": "animation",
    "cos(": "animation",
    "itime": "animation",
    "utime": "animation",
    # Shadertoy vocabulary (v2)
    "raymarch": "raymarching",
    "march": "raymarching",
    "sdf": "sdf",
    "sdsphere": "sdf",
    "sdbox": "sdf",
    "kaleido": "kaleidoscope",
    "voronoi": "voronoi",
    "worley": "voronoi",
    "fbm": "fbm",
    "dither": "dithering",
    "bayer": "dithering",
    "bloom": "bloom",
    "glow": "bloom",
    "vhs": "vhs",
    "scanline": "crt",
    "barrel": "barrel_distortion",
    "fisheye": "barrel_distortion",
    "vignette": "vignette",
    "kuwahara": "oil_painting",
    "ascii": "ascii_art",
    "mosaic": "pixelation",
    "swirl": "swirl_distortion",
    "twirl": "swirl_distortion",
    "ripple": "ripple_distortion",
    "fractal": "fractal",
    "mandelbrot": "fractal",
    "plasma": "plasma",
    "lut": "color_grading",
    "grading": "color_grading",
    "film grain": "film_grain",
    "grain": "film_grain",
    "emboss": "emboss",
    "sharpen": "sharpen",
    "mirror": "mirror",
    "hexagon": "hex_tiling",
}


def infer_techniques(code: str, name: str = "", extra: str = "") -> list[str]:
    combined = f"{code} {name} {extra}".lower()
    return sorted({tag for keyword, tag in TECHNIQUE_TAGS.items() if keyword in combined})


_FUNC_START = re.compile(r"(?:^|\n)(?:[\w]+\s+)+\w+\s*\([^)]*\)\s*\{", re.MULTILINE)


def split_functions(code: str) -> list[str]:
    """Split GLSL code into top-level function blocks (preamble goes with the first)."""
    starts = [m.start() for m in _FUNC_START.finditer(code)]
    if not starts:
        return [code]

    chunks = []
    for i, start in enumerate(starts):
        end = starts[i + 1] if i + 1 < len(starts) else len(code)
        chunks.append(code[start:end].strip())
    return [c for c in chunks if c]
