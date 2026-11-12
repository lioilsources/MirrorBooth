#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float fract_sin(float x) { return fract(sin(x) * 12345.678); }
float noise(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
vec2 hash(vec2 p) { return vec2(fract_sin(p.x + p.y * 17.0), fract_sin(p.x * 13.0 + p.y)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float t = floor(uTime * 5.0);
    float block_y = floor(uv.y * 15.0);
    float block_x = floor(uv.x * 10.0);
    vec2 block = vec2(block_x, block_y);
    vec2 offset = hash(block + t * 0.7) * 0.02;
    float jump = fract_sin(block_y + t * 1.3);
    float glitch = step(0.65, jump);
    float shift_x = (noise(block + t * 2.1) - 0.5) * 0.1 * glitch;
    vec2 base_uv = vec2(fract(uv.x + shift_x + offset.x), uv.y + offset.y * 0.02);
    float split_r = 0.006 + 0.018 * glitch;
    float split_b = -0.006 - 0.018 * glitch;
    vec3 col;
    col.r = texture(uTexture, vec2(fract(base_uv.x + split_r), base_uv.y)).r;
    col.g = texture(uTexture, base_uv).g;
    col.b = texture(uTexture, vec2(fract(base_uv.x + split_b), base_uv.y)).b;

    float luma = dot(col, vec3(0.299, 0.587, 0.114));
    float pitch = uResolution.x / 110.0;
    float y = FlutterFragCoord().y / pitch + sin(uv.x * 38.0) * 0.7 + (luma - 0.5) * 1.5;
    float line = abs(fract(y) - 0.5) * 2.0;
    float w = 1.0 - luma;
    float ink = smoothstep(w + 0.12, w - 0.12, line);
    vec3 final_col = mix(vec3(0.93, 0.95, 0.88), vec3(0.08, 0.22, 0.16), ink);

    fragColor = vec4(clamp(final_col, 0.0, 1.0), 1.0);
}
