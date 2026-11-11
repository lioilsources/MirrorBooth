#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float hash21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
vec2 hash22(vec2 p) { float n = hash21(p); return vec2(n, hash21(p + n + 17.1)); }
float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 base = texture(uTexture, uv).rgb;

    // Apply face-aware particle motion from Shader B: dynamic offset based on face center and scale
    vec2 offs = vec2(0.0);
    float spec = 0.0;
    for (int k = 0; k < 2; k++) {
        float sc = k == 0 ? 6.0 : 10.0;
        vec2 p = (vec2(uv.x * (uResolution.x / uResolution.y), uv.y) + (uFaceCenter - vec2(0.5)) * uFaceScale * 0.5) * sc;
        p.y -= uTime * (0.4 + 0.4 * hash21(vec2(floor(p.x), float(k) + 4.0))) * sc * 0.2;
        vec2 id = floor(p);
        vec2 f = fract(p) - 0.5;
        vec2 h = hash22(id + float(k) * 33.0);
        if (h.x > 0.4) {
            vec2 c = (h - 0.5) * 0.5;
            vec2 d = f - c;
            d.y *= 0.75;
            float r = 0.12 + 0.1 * h.y;
            float m = smoothstep(r, r * 0.55, length(d));
            offs -= d * m * 0.6 / sc * 2.5;
            spec += m * smoothstep(0.05, 0.0, length(d - vec2(-0.06, -0.07)));
        }
    }
    vec2 suv = clamp(uv + vec2(offs.x * (uResolution.y / uResolution.x), offs.y), 0.0, 1.0);
    vec3 col = texture(uTexture, suv).rgb * vec3(0.88, 0.94, 1.02);
    col += spec * 0.7;

    // Weather overlay: rain with sin-based motion and time-driven randomness from Shader A
    float rain = 0.0;
    float aspect = uResolution.x / uResolution.y;
    vec2 p = uv * vec2(18.0 * aspect, 18.0);
    p.y += uTime * 0.7;
    p.x += sin(uTime * 0.6 + p.y * 1.1 + fract(p.y)) * 0.18;
    vec2 id = floor(p);
    vec2 f = fract(p) - 0.5;
    float h = hash21(id + 39.0);
    float r = 0.02 + 0.07 * h;
    float strength = smoothstep(r, r * 0.4, length(f - (h - 0.5) * 0.8));
    rain += strength * (0.9 - 0.3 * fract(uTime * 0.28));

    // Dust particles using fract(sin(...)) for organic movement from Shader A
    float dust = 0.0;
    vec2 d = uv * vec2(16.0, 16.0);
    d.x += sin(uTime * 0.35 + d.y * 0.85) * 0.22;
    d.y += uTime * 0.28;
    vec2 di = floor(d);
    vec2 df = fract(d) - 0.5;
    float dval = fract(sin(dot(di, vec2(19.0, 43.0)) + uTime * 0.45) * 77.0);
    float dsize = 0.01 + 0.05 * dval;
    dust += smoothstep(dsize, dsize * 0.5, length(df)) * (0.7 + 0.3 * dval);

    // Fog effect with time-based density variation from Shader A
    float fog = 0.0;
    float ftime = uTime * 0.12;
    float fbase = fract(sin(uv.x * 25.0 + ftime * 0.45) * 49.0) + fract(sin(uv.y * 21.0 + ftime * 0.65) * 55.0);
    fog += 0.14 * (fbase * 0.5 + 0.5);

    // Combine all effects: base image with weather overlay and face-aware dynamics
    vec3 weather = vec3(rain * 0.5, rain * 0.6, rain * 0.7) + vec3(dust * 0.28, dust * 0.18, dust * 0.12) + vec3(fog * 0.22);
    col += weather;

    // Particle trail using face-scale and motion, replacing sparkPos with particle dynamics from Shader B
    float cw = uResolution.x / 32.0;
    vec2 g = FlutterFragCoord().xy / vec2(cw, cw * 1.28);
    vec2 cell = floor(g);
    vec2 f2 = fract(g);
    float hcol = hash21(vec2(cell.x, 6.0));
    float rows = uResolution.y / (cw * 1.28);
    float head = fract(uTime * (0.13 + 0.28 * hcol) + hcol * 4.5) * (rows + 12.0);
    float dist = head - cell.y;
    float trail = dist > 0.0 ? exp(-dist * 0.19) : 0.0;
    float isHead = step(0.0, dist) * step(dist, 1.0);
    float tick = floor(uTime * (3.8 + 7.2 * hash21(cell)));
    vec2 bit = floor(f2 * vec2(3.5, 5.5));
    float glyph = step(0.5, hash21(bit + cell * 7.0 + tick));
    glyph *= step(0.14, f2.x) * step(f2.x, 0.86) * step(0.1, f2.y) * step(f2.y, 0.9);
    float l = luma(base);
    vec3 particleCol = vec3(0.015, 0.3, 0.11) * l;
    particleCol += vec3(0.14, 0.85, 0.38) * glyph * (trail * (0.3 + 1.05 * l) + 0.09 * l);
    particleCol += vec3(0.65, 0.92, 0.75) * glyph * isHead;

    col += particleCol;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
