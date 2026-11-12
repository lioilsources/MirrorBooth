#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 fract_sin(vec2 p) {
    return fract(sin(p * vec2(17.0, 23.0)) * 43758.5453);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float t = floor(uTime * 7.0);
    float block_y = floor(uv.y * 14.0);
    float block_x = floor(uv.x * 10.0);
    float phase = hash(vec2(block_y, t));
    float jitter = (hash(vec2(block_x, t + 11.0)) - 0.5) * 0.15;
    float split = 0.02 + 0.03 * phase;
    vec2 offset = fract_sin(vec2(block_y, t + 3.0)) * 0.04;
    vec2 base_uv = vec2(fract(uv.x + jitter + offset.x), uv.y + offset.y);
    vec3 col;
    col.r = texture(uTexture, vec2(base_uv.x + split, base_uv.y)).r;
    col.g = texture(uTexture, base_uv).g;
    col.b = texture(uTexture, vec2(base_uv.x - split, base_uv.y)).b;
    fragColor = vec4(col, 1.0);
}
