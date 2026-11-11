#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 px = FlutterFragCoord().xy;
    float cell = uResolution.x / 50.0;
    vec2 rp = px / cell;
    vec2 grid = floor(rp);
    vec2 offset = fract(rp) - 0.5;
    float pattern = mod(grid.x + grid.y, 2.0);
    float d = length(offset);
    float threshold = 0.3 + 0.5 * fract(uTime * 0.3 + grid.x * 0.1 + grid.y * 0.2);
    float dotSize = 0.5 * smoothstep(0.1, 0.9, luma(texture(uTexture, uv).rgb));
    float ink = step(dotSize, d * 1.5 + threshold * 0.2);
    vec3 base = vec3(0.95, 0.92, 0.85);
    vec3 inkColor = vec3(0.04, 0.03, 0.08);
    fragColor = vec4(mix(base, inkColor, ink), 1.0);
}
