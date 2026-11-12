#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 px = FlutterFragCoord().xy;
    float cell = uResolution.x / 60.0;
    vec2 grid = floor(px / cell);
    vec2 offset = fract(px / cell);
    float pattern = mod(offset.x + offset.y, 1.0);
    float dither = step(0.5, fract(uTime * 0.3 + pattern));
    float brightness = luma(texture(uTexture, uv).rgb);
    float dotSize = smoothstep(0.3, 0.7, brightness);
    float dist = length(offset - 0.5);
    float ink = step(dotSize * 0.45 + dither * 0.15, dist);
    vec3 col = mix(vec3(0.94, 0.91, 0.84), vec3(0.05, 0.04, 0.10), ink);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
