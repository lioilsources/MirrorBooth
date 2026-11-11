#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float R = uFaceScale;

    float dx = uv.x - uFaceCenter.x;
    float dy = uv.y - uFaceCenter.y;

    float gx = exp(-(dx * dx) / (1.8 * R * R));
    float headMask = smoothstep(0.45 * R, -0.2 * R, dy);
    float srcY = uFaceCenter.y + dy * (1.0 + 0.35 * headMask);
    float srcX = uFaceCenter.x + dx * (1.0 + 0.28 * headMask * gx);

    float neckMask = smoothstep(0.45 * R, 1.4 * R, dy);
    srcY = uFaceCenter.y + (srcY - uFaceCenter.y) * (1.0 - 0.40 * neckMask);

    vec2 wUV = vec2(mix(uv.x, srcX, gx), mix(uv.y, srcY, gx));

    // Voronoi cell using mod and floor for base structure
    float s = 34.0;
    vec2 p = wUV * s;
    vec2 r = vec2(1.0, 1.7320508);
    vec2 h = r * 0.5;
    vec2 a = mod(p, r) - h;
    vec2 b = mod(p - h, r) - h;
    vec2 g = dot(a, a) < dot(b, b) ? a : b;
    vec2 c = (p - g) / s;
    vec3 voronoiCol = texture(uTexture, clamp(vec2(c.x, c.y), 0.0, 1.0)).rgb;

    // Square cell quantization using floor
    vec2 cells = vec2(44.0, 44.0 * uResolution.y / uResolution.x);
    vec2 cellCenter = floor(wUV * cells + 0.5) / cells;
    vec3 squareCol = texture(uTexture, cellCenter).rgb;

    // Blend Voronoi and square using mod and floor, remove hex layer
    float blend = 0.5 + 0.5 * sin(uTime * 0.4);
    vec3 finalCol = mix(squareCol, voronoiCol, blend);

    // Apply gamma correction and ensure visibility
    finalCol = pow(finalCol, vec3(0.85)) * 1.15;

    fragColor = vec4(clamp(finalCol, 0.0, 1.0), 1.0);
}
