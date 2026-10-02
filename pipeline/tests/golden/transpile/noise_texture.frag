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
// --- ShaderGen composite template (procedural Shadertoy shader x camera) ---
// The procedural colour `fx` is blended over the camera frame `cam`.
// Blend mode is selected at port time: screen

float stLuma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

vec3 stOverlay(vec3 base, vec3 top) {
    return mix(2.0 * base * top, 1.0 - 2.0 * (1.0 - base) * (1.0 - top), step(0.5, base));
}

float stEdge(vec2 uv) {
    vec2 px = 1.0 / uResolution;
    float tl = stLuma(texture(uTexture, uv + vec2(-px.x, -px.y)).rgb);
    float t  = stLuma(texture(uTexture, uv + vec2(0.0, -px.y)).rgb);
    float tr = stLuma(texture(uTexture, uv + vec2(px.x, -px.y)).rgb);
    float l  = stLuma(texture(uTexture, uv + vec2(-px.x, 0.0)).rgb);
    float r  = stLuma(texture(uTexture, uv + vec2(px.x, 0.0)).rgb);
    float bl = stLuma(texture(uTexture, uv + vec2(-px.x, px.y)).rgb);
    float b  = stLuma(texture(uTexture, uv + vec2(0.0, px.y)).rgb);
    float br = stLuma(texture(uTexture, uv + vec2(px.x, px.y)).rgb);
    float gx = -tl - 2.0 * l - bl + tr + 2.0 * r + br;
    float gy = -tl - 2.0 * t - tr + bl + 2.0 * b + br;
    return clamp(length(vec2(gx, gy)) * 2.0, 0.0, 1.0);
}

vec3 stBlend(vec3 cam, vec3 fx, vec2 uv) {
    return 1.0 - (1.0 - cam) * (1.0 - fx);
}

void main() {
    vec2 fc = FlutterFragCoord().xy;
    vec2 uv = fc / uResolution;
    vec3 cam = texture(uTexture, uv).rgb;
    fc.y = uResolution.y - fc.y;
    vec4 c = vec4(0.0);
    mainImage(c, fc);
    vec3 fx = clamp(c.rgb, 0.0, 1.0);
    fragColor = vec4(clamp(stBlend(cam, fx, uv), 0.0, 1.0), 1.0);
}
