#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;

    float cellSize = 9.0;

    // Cell center in screen space
    vec2 cellCenter = floor(fragCoord / cellSize) * cellSize + cellSize * 0.5;
    vec3 cellCol = texture(uTexture, cellCenter / uResolution).rgb;
    float cellLum = lum(cellCol);

    // Dot radius: darker areas → bigger dot
    float maxR = cellSize * 0.52;
    float dotR = sqrt(1.0 - cellLum) * maxR;

    float dist = length(fragCoord - cellCenter);
    float inDot = 1.0 - smoothstep(dotR - 0.7, dotR + 0.7, dist);

    // Dot uses cell color (slightly saturated); paper is warm white
    vec3 saturated = mix(vec3(cellLum), cellCol, 1.6);
    vec3 paper = vec3(0.97, 0.94, 0.88);
    vec3 col = mix(paper, saturated, inDot);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
