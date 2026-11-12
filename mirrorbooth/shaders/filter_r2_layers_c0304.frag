#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec2 hash22(vec2 p) {
    float n = hash21(p);
    return vec2(n, hash21(p + n + 17.1));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 baseColor = texture(uTexture, uv).rgb;

    // Face-aware displacement using hash, fract, sin, uTime
    vec2 offs = vec2(0.0);
    float spec = 0.0;
    for (int k = 0; k < 2; k++) {
        float sc = k == 0 ? 8.0 : 10.0;
        vec2 p = (vec2(uv.x * (uResolution.x / uResolution.y), uv.y) + (uFaceCenter - vec2(0.5)) * uFaceScale * 0.5) * sc;
        p.y -= uTime * (0.4 + 0.6 * hash21(vec2(floor(p.x), float(k) + 4.0))) * sc * 0.3;
        vec2 id = floor(p);
        vec2 f = fract(p) - 0.5;
        vec2 h = hash22(id + float(k) * 33.0);
        if (h.x > 0.4) {
            vec2 c = (h - 0.5) * 0.55;
            vec2 d = f - c;
            d.y *= 0.65;
            float r = 0.14 + 0.12 * h.y;
            float m = smoothstep(r, r * 0.65, length(d));
            offs -= d * m * 0.45 / sc;
            spec += m * smoothstep(0.05, 0.0, length(d - vec2(-0.04, -0.07)));
        }
    }
    vec2 suv = clamp(uv + vec2(offs.x * (uResolution.y / uResolution.x), offs.y), 0.0, 1.0);
    vec3 col = texture(uTexture, suv).rgb * vec3(0.88, 0.95, 1.02);
    col += spec * 0.7;

    // Dynamic weather overlay: fog and dust using fract, sin, hash, uTime
    float weather = 0.0;
    for (int i = 0; i < 6; i++) {
        float t = uTime + float(i) * 0.4;
        vec2 p = uv * 14.0 + vec2(sin(t * 0.8) * 2.0, cos(t * 0.5) * 1.5);
        p += hash22(vec2(i, 19.0)) * 0.12;
        float f = fract(sin(dot(p, vec2(13.9898, 77.233))) * 43758.5453);
        float r = f * 0.18 + 0.06;
        float d = length(p - vec2(0.5));
        float s = smoothstep(r, r * 0.5, f * (1.0 - d * 0.8));
        weather += s * (0.05 + 0.02 * float(i));
    }
    col += weather * 0.3;

    // Particle trail: replacing sparkPos with dynamic particle system using fract, sin, uTime
    float cw = uResolution.x / 32.0;
    vec2 g = FlutterFragCoord().xy / vec2(cw, cw * 1.25);
    vec2 cell = floor(g);
    vec2 f = fract(g);
    float hcol = hash21(vec2(cell.x, 6.0));
    float head = fract(uTime * (0.18 + 0.28 * hcol) + hcol * 4.5) * (uResolution.y / (cw * 1.25) + 12.0);
    float dist = head - cell.y;
    float trail = dist > 0.0 ? exp(-dist * 0.2) : 0.0;
    float isHead = step(0.0, dist) * step(dist, 1.0);
    float tick = floor(uTime * (3.7 + 6.8 * hash21(cell)));
    vec2 bit = floor(f * vec2(3.0, 4.0));
    float glyph = step(0.5, hash21(bit + cell * 6.5 + tick));
    glyph *= step(0.15, f.x) * step(f.x, 0.85) * step(0.12, f.y) * step(f.y, 0.88);
    float l = dot(baseColor, vec3(0.299, 0.587, 0.114));
    vec3 particleCol = vec3(0.015, 0.3, 0.11) * l;
    particleCol += vec3(0.14, 0.85, 0.38) * glyph * (trail * (0.32 + 1.05 * l) + 0.09 * l);
    particleCol += vec3(0.65, 0.92, 0.75) * glyph * isHead;

    // Add subtle fog and snow using fract, sin, uTime
    float aspect = uResolution.x / uResolution.y;
    float fog = 0.0;
    for (int k = 0; k < 4; k++) {
        float sc = 5.0 + 6.0 * float(k);
        vec2 p = vec2(uv.x * aspect, uv.y) * sc;
        p.y -= uTime * (0.7 + 0.3 * float(k));
        p.x += sin(uTime * 0.6 + p.y * 0.9 + float(k)) * 0.4;
        vec2 id = floor(p);
        vec2 f = fract(p) - 0.5;
        vec2 h = hash22(id + float(k) * 21.0);
        float r = 0.06 + 0.09 * h.x;
        fog += smoothstep(r, r * 0.4, length(f - (h - 0.5) * 0.55)) * (0.8 - 0.2 * float(k));
    }

    // Rain and dust particles using dynamic trail and fract, sin, hash
    float cw2 = uResolution.x / 36.0;
    vec2 g2 = FlutterFragCoord().xy / vec2(cw2, cw2 * 1.3);
    vec2 cell2 = floor(g2);
    vec2 f2 = fract(g2);
    float hcol2 = hash21(vec2(cell2.x, 8.0));
    float rows = uResolution.y / (cw2 * 1.3);
    float head2 = fract(uTime * (0.14 + 0.32 * hcol2) + hcol2 * 5.5) * (rows + 15.0);
    float dist2 = head2 - cell2.y;
    float trail2 = dist2 > 0.0 ? exp(-dist2 * 0.22) : 0.0;
    float isHead2 = step(0.0, dist2) * step(dist2, 1.0);
    float tick2 = floor(uTime * (4.2 + 7.5 * hash21(cell2)));
    vec2 bit2 = floor(f2 * vec2(4.0, 5.0));
    float glyph2 = step(0.5, hash21(bit2 + cell2 * 7.1 + tick2));
    glyph2 *= step(0.13, f2.x) * step(f2.x, 0.87) * step(0.1, f2.y) * step(f2.y, 0.9);
    float l2 = fract(sin(dot(cell2, vec2(14.9898, 76.233))) * 43758.5453);
    vec3 particleCol2 = vec3(0.02, 0.36, 0.14) * l2;
    particleCol2 += vec3(0.18, 1.0, 0.45) * glyph2 * (trail2 * (0.38 + 1.15 * l2) + 0.11 * l2);
    particleCol2 += vec3(0.75, 1.0, 0.85) * glyph2 * isHead2;

    // Final composition: combine base, weather, fog, and particles
    col += fog * 0.25;
    col += particleCol * 0.22;
    col += particleCol2 * 0.22;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
