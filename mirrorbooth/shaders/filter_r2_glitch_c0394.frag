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
    float t = floor(uTime * 5.0);
    float blockHeight = 32.0;
    float blockY = floor(uv.y * blockHeight);
    float rowOffset = fractSin(blockY + t * 0.7) * 0.04;
    float shift = (fract(t * 11.23 + blockY * 5.67) - 0.5) * 0.1;
    vec2 cell = floor(uv * vec2(8.0, blockHeight));
    float noise = fract(sin(dot(cell, vec2(17.9898, 89.233))) * 43758.5453);
    float glitch = step(0.97, noise);
    float rgbShift = (fract(t * 15.3 + uv.y * 8.1) - 0.5) * 0.03 * glitch;
    vec2 offset = vec2(shift + rgbShift, rowOffset);
    
    // Transfer: Use the column-based shifting from the other filter
    float n = 11.0;
    float id = floor(uv.x * n);
    float f = fract(uv.x * n);
    float off = sin(id * 1.7 + uTime * 1.4) * 0.05;
    vec2 suv = vec2((id + 0.5 + (f - 0.5) * 1.7) / n, uv.y + off);
    
    vec3 col;
    col.r = texture(uTexture, suv + vec2(offset.x, 0.0)).r;
    col.g = texture(uTexture, suv).g;
    col.b = texture(uTexture, suv - vec2(offset.x, 0.0)).b;
    
    if (glitch > 0.0) {
        col += (noise - 0.5) * 0.3 * vec3(1.0, 0.7, 1.1);
    }
    
    float shade = 0.65 + 0.35 * sin(f * 3.14159);
    col *= shade;
    
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
