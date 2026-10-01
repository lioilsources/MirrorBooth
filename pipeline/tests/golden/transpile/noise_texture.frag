// Ported from https://www.shadertoy.com/view/stNoiseTx — "Noise Clouds" by dave, Public Domain
// Converted to the MirrorBooth/Flutter shader contract by ShaderGen v2 (pipeline/shadertoy/transpile.py).

#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

#define iResolution vec3(uResolution, 1.0)

// Procedural stand-in for Shadertoy's preset noise textures (/media/a/*.png).
// stNoiseTex(uv) mimics a 256x256 RGBA white-noise texture sampled with
// linear filtering and repeat wrap: smooth value noise over a 256-cell grid.
vec4 stHash44(vec2 p) {
    vec4 p4 = fract(vec4(p.xyxy) * vec4(0.1031, 0.1030, 0.0973, 0.1099));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

vec4 stNoiseTex(vec2 uv) {
    vec2 x = uv * 256.0 - 0.5;
    vec2 i = floor(x);
    vec2 f = fract(x);
    vec4 a = stHash44(mod(i, 256.0));
    vec4 b = stHash44(mod(i + vec2(1.0, 0.0), 256.0));
    vec4 c = stHash44(mod(i + vec2(0.0, 1.0), 256.0));
    vec4 d = stHash44(mod(i + vec2(1.0, 1.0), 256.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// ---- Shadertoy: Image ----
// This shader is released into the public domain.

float noise(in vec2 x)
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    vec2 uv = (p + f + 0.5) / 256.0;
    return stNoiseTex(uv).x;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = fragCoord / iResolution.y;
    float n = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) { n += a * noise(p * 8.0); p *= 2.0; a *= 0.5; }
    fragColor = vec4(vec3(n), 1.0);
}

// ---- MirrorBooth entry point ----
void main() {
    vec2 fc = FlutterFragCoord().xy;
    fc.y = uResolution.y - fc.y;  // Flutter: top-left origin, Shadertoy: bottom-left
    vec4 c = vec4(0.0);
    mainImage(c, fc);
    fragColor = vec4(clamp(c.rgb, 0.0, 1.0), 1.0);
}
