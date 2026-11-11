#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

vec2 earLens(vec2 d, vec2 ear, float R) {
    vec2 k = d - ear;
    float sigma = 0.34 * R;
    float w = exp(-dot(k, k) / (sigma * sigma));
    return k * (1.0 - 0.45 * w) + ear - d;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float aspect = uResolution.x / uResolution.y;
    float R = uFaceScale;

    vec2 d = uv - uFaceCenter;
    d.x *= aspect;

    vec2 earL = vec2(-0.85 * R, -0.02 * R);
    vec2 earR = vec2(0.85 * R, -0.02 * R);

    vec2 src = d + earLens(d, earL, R) + earLens(d, earR, R);
    src.x /= aspect;
    vec2 wUV = uFaceCenter + src;

    // Apply bubbling distortion anchored on face center and scale
    vec2 anchor = uFaceCenter;
    float radius = 0.35 * uFaceScale;
    vec2 diff = wUV - anchor;
    diff.x *= aspect;
    float dist = length(diff);
    float t = dist / radius;
    float bubble = 1.0 + 0.8 * (1.0 - t) * sin(3.14159 * t);
    vec2 finalUV = anchor + diff * bubble;

    // Clamp final UV to texture bounds
    finalUV = clamp(finalUV, 0.0, 1.0);

    // Sample the original image at the final warped location
    vec3 col = texture(uTexture, finalUV).rgb;

    // Apply smoothstep-based tone mapping with three-color gradients
    float l = lum(col);
    l = smoothstep(0.05, 0.95, l);
    vec3 lo = vec3(0.1, 0.05, 0.38);
    vec3 mid = vec3(0.93, 0.18, 0.5);
    vec3 hi = vec3(1.0, 0.92, 0.45);
    col = l < 0.5 ? mix(lo, mid, l * 2.0) : mix(mid, hi, l * 2.0 - 1.0);

    // Slight desaturation with a green cast on midtones
    float m = smoothstep(0.15, 0.5, l) * (1.0 - smoothstep(0.6, 0.95, l));
    col = mix(vec3(l), col, 0.75);
    col *= mix(vec3(1.0), vec3(0.92, 1.10, 0.92), m * 0.6);

    // Final color output
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
