#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float fractSin(float x) {
    return fract(sin(x) * 43758.5453);
}

vec2 hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return vec2(p.x * p.y, p.y * p.x);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float t = floor(uTime * 7.0);
    float blockHeight = 24.0;
    float blockY = floor(uv.y * blockHeight);
    float rowOffset = fractSin(blockY + t * 0.9) * 0.05;
    float shift = (fract(t * 13.17 + blockY * 7.43) - 0.5) * 0.12;
    vec2 cell = floor(uv * vec2(10.0, blockHeight));
    float noise = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
    float glitch = step(0.95, noise);
    float rgbShift = (fract(t * 17.5 + uv.y * 9.3) - 0.5) * 0.02 * glitch;
    vec2 offset = vec2(shift + rgbShift, rowOffset);
    vec3 col;
    col.r = texture(uTexture, uv + vec2(offset.x, 0.0)).r;
    col.g = texture(uTexture, uv).g;
    col.b = texture(uTexture, uv - vec2(offset.x, 0.0)).b;
    if (glitch > 0.0) {
        col += (noise - 0.5) * 0.25 * vec3(1.0, 0.6, 0.9);
    }
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
