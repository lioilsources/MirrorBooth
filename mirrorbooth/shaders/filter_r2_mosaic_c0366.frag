#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 pixelMosaic(vec2 uv) {
    float cellSize = 34.0;
    vec2 grid = floor(uv * uResolution / cellSize);
    vec2 offset = mod(grid, 2.0) * 0.5;
    vec2 cellCenter = (grid + offset) * cellSize / uResolution;
    return texture(uTexture, cellCenter).rgb;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter / uResolution;
    float scale = uFaceScale * 44.0;
    vec2 p = (uv - center) * scale + center;

    // Use floor to create square grid cells
    float s = 34.0;
    vec2 grid = floor(p * s);
    vec2 cellUV = (grid + 0.5) / s;
    vec3 squareCol = texture(uTexture, cellUV).rgb;

    // Use mod and round to create a hexagonal grid effect
    vec2 p_hex = vec2(uv.x * uResolution.x / uResolution.y, uv.y) * s;
    vec2 r = vec2(1.0, 1.7320508);
    vec2 h = r * 0.5;
    vec2 a = mod(p_hex, r) - h;
    vec2 b = mod(p_hex - h, r) - h;
    vec2 g = dot(a, a) < dot(b, b) ? a : b;
    vec2 c_hex = (p_hex - g) / s;
    vec2 hexUV = clamp(vec2(c_hex.x * uResolution.y / uResolution.x, c_hex.y), 0.0, 1.0);
    vec3 hexCol = texture(uTexture, hexUV).rgb;

    // Blend square and hexagonal results using round and mod
    float blend = 0.5 + 0.5 * sin(uTime * 0.3);
    vec3 finalCol = mix(squareCol, hexCol, blend);

    // Final adjustment
    finalCol = pow(finalCol, vec3(0.9)) * 1.1;
    fragColor = vec4(clamp(finalCol, 0.0, 1.0), 1.0);
}
