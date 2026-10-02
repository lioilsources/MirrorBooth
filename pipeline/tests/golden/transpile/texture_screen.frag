// Ported from https://www.shadertoy.com/view/stTexScr — "Chromatic Split" by bob, MIT
// Converted to the MirrorBooth/Flutter shader contract by ShaderGen v2 (pipeline/shadertoy/transpile.py).

#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

#define iResolution vec3(uResolution, 1.0)

// Shadertoy UV (bottom-left origin) -> camera texture (top-left origin)
vec4 stSample(vec2 uv) { return texture(uTexture, vec2(uv.x, 1.0 - uv.y)); }

// ---- Shadertoy: Image ----
// SPDX-License-Identifier: MIT

#define OFFSET 0.004
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    float r = stSample(fract(uv + vec2(OFFSET, 0.0))).r;
    float g = stSample(fract(uv)).g;
    float b = stSample(fract(uv - vec2(OFFSET, 0.0))).b;
    fragColor = vec4(r, g, b, 1.0);
}

// ---- MirrorBooth entry point ----
void main() {
    vec2 fc = FlutterFragCoord().xy;
    fc.y = uResolution.y - fc.y;  // Flutter: top-left origin, Shadertoy: bottom-left
    vec4 c = vec4(0.0);
    mainImage(c, fc);
    fragColor = vec4(clamp(c.rgb, 0.0, 1.0), 1.0);
}
