#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float hash21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
vec2 hash22(vec2 p) { float n = hash21(p); return vec2(n, hash21(p + n + 17.1)); }
float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 px = FlutterFragCoord().xy;
    vec2 cellp = floor(px / 9.0);
    vec2 wob = (hash22(cellp) - 0.5) * 0.004;
    vec2 fpx = fract(px / 9.0);
    vec2 wob2 = (hash22(cellp + vec2(1.0, 0.0)) - 0.5) * 0.004;
    vec2 w = mix(wob, wob2, smoothstep(0.0, 1.0, fpx.x));
    vec3 acc = vec3(0.0);
    for (int i = 0; i < 8; i++) {
        float a = 0.7853982 * float(i);
        acc += texture(uTexture, uv + w + vec2(cos(a), sin(a)) * 5.0 / uResolution).rgb;
    }
    vec3 blur = acc / 8.0;
    vec3 src = texture(uTexture, uv + w).rgb;
    vec3 col = floor(blur * 7.0 + 0.5) / 7.0;
    col = mix(col, blur, 0.45);
    col = mix(vec3(luma(col)), col, 1.35);
    float edge = clamp(length(src - blur) * 6.0, 0.0, 1.0);
    col *= 1.0 - 0.45 * edge;
    float paper = hash21(floor(px / 2.0));
    col = mix(col, vec3(0.98, 0.96, 0.9), 0.14 + 0.08 * paper);
    col = 1.0 - (1.0 - col) * 0.92;
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
