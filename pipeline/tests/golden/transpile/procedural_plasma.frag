// Ported from https://www.shadertoy.com/view/stPlasma — "Tiny Plasma" by carol, CC0 1.0
// Converted to the MirrorBooth/Flutter shader contract by ShaderGen v2 (pipeline/shadertoy/transpile.py).

#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

#define iResolution vec3(uResolution, 1.0)
#define iTime uTime
#define iMouse vec4(uFaceCenter.x * uResolution.x, (1.0 - uFaceCenter.y) * uResolution.y, 0.0, 0.0)

// ---- Shadertoy: Image ----
// CC0 - public domain dedication

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec2 m = iMouse.xy / iResolution.xy;
    float v = sin(p.x * 4.0 + iTime) + sin(p.y * 3.0 - iTime * 0.7) + sin(length(p - m) * 6.0);
    vec3 col = 0.5 + 0.5 * cos(v + vec3(0.0, 2.0, 4.0));
    fragColor = vec4(col, 1.0);
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
