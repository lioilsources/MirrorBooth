#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float hash21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
vec2 hash22(vec2 p) { float n = hash21(p); return vec2(n, hash21(p + n + 17.1)); }
float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float aspect = uResolution.x / uResolution.y;
    vec3 col = texture(uTexture, uv).rgb;
    col = mix(vec3(luma(col)), col, 0.8) * vec3(0.9, 0.97, 1.08) + 0.03;
    float snow = 0.0;
    for (int k = 0; k < 3; k++) {
        float sc = 6.0 + 5.0 * float(k);
        vec2 p = vec2(uv.x * aspect, uv.y) * sc;
        p.y -= uTime * (0.6 + 0.25 * float(k));
        p.x += sin(uTime * 0.5 + p.y * 0.8 + float(k)) * 0.35;
        vec2 id = floor(p);
        vec2 f = fract(p) - 0.5;
        vec2 h = hash22(id + float(k) * 19.0);
        float r = 0.05 + 0.08 * h.x;
        snow += smoothstep(r, r * 0.3, length(f - (h - 0.5) * 0.6)) * (0.9 - 0.2 * float(k));
    }
    col += snow;
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
