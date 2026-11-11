#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float fractSin(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
vec2 noise21(vec2 p) { return vec2(fractSin(p), fractSin(p + 17.45)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float t = floor(uTime * 5.0);
    float row = floor(uv.y * 18.0);
    float base = fractSin(vec2(row, t));
    float jump = step(0.6, base);
    float offset = (fractSin(vec2(row + 1.0, t + 0.5)) - 0.5) * 0.15 * jump;
    vec2 shifted = vec2(fract(uv.x + offset), uv.y);

    vec3 rgb;
    rgb.r = texture(uTexture, vec2(shifted.x + 0.02, shifted.y)).r;
    rgb.g = texture(uTexture, shifted).g;
    rgb.b = texture(uTexture, vec2(shifted.x - 0.02, shifted.y)).b;

    float scale = 1.0 / (uFaceScale * 2.0 + 0.5);
    vec2 grid = floor(uv * scale * 12.0);
    float block = fractSin(grid + t * 0.7);
    vec2 blockPos = (grid + 0.5) / (scale * 12.0);
    vec3 blockColor = texture(uTexture, blockPos).rgb;
    float mask = smoothstep(0.1, 0.3, fractSin(grid + t * 1.3));
    blockColor *= 0.6 + 0.4 * mask;

    fragColor = vec4(clamp(rgb + blockColor * 0.25, 0.0, 1.0), 1.0);
}
