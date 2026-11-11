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
    vec3 base = texture(uTexture, uv).rgb;

    // Apply Shader B's core effect: particle trail with glowing glyphs
    float cw = uResolution.x / 34.0;
    vec2 g = FlutterFragCoord().xy / vec2(cw, cw * 1.35);
    vec2 cell = floor(g);
    vec2 f = fract(g);
    float hcol = hash21(vec2(cell.x, 7.0));
    float rows = uResolution.y / (cw * 1.35);
    float head = fract(uTime * (0.12 + 0.3 * hcol) + hcol * 5.0) * (rows + 14.0);
    float dist = head - cell.y;
    float trail = dist > 0.0 ? exp(-dist * 0.2) : 0.0;
    float isHead = step(0.0, dist) * step(dist, 1.0);
    float tick = floor(uTime * (4.0 + 8.0 * hash21(cell)));
    vec2 bit = floor(f * vec2(4.0, 6.0));
    float glyph = step(0.5, hash21(bit + cell * 7.3 + tick));
    glyph *= step(0.12, f.x) * step(f.x, 0.88) * step(0.08, f.y) * step(f.y, 0.92);
    float l = luma(texture(uTexture, (cell + 0.5) * vec2(cw, cw * 1.35) / uResolution).rgb);
    vec3 col = vec3(0.02, 0.34, 0.12) * l;
    col += vec3(0.15, 1.0, 0.4) * glyph * (trail * (0.35 + 1.1 * l) + 0.1 * l);
    col += vec3(0.7, 1.0, 0.8) * glyph * isHead;

    // Overlay Shader A's weather effect: dynamic snow with sin-based motion
    float aspect = uResolution.x / uResolution.y;
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

    // Blend both effects: base selfie, plus particle trail, plus snow
    vec3 final = base + col * 0.5 + vec3(snow * 0.4, snow * 0.45, snow * 0.55);

    fragColor = vec4(clamp(final, 0.0, 1.0), 1.0);
}
