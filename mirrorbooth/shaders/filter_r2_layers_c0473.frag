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

vec2 rand(vec2 p) {
    return vec2(hash(p), hash(p + vec2(1.0, 2.0)));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 baseColor = texture(uTexture, uv).rgb;

    // Apply Shader B's core technique: dynamic offsetting and streaks
    vec2 offs = vec2(0.0);
    float spec = 0.0;
    for (int k = 0; k < 2; k++) {
        float sc = k == 0 ? 7.0 : 12.0;
        vec2 p = vec2(uv.x * (uResolution.x / uResolution.y), uv.y) * sc;
        vec2 id = floor(p);
        p.y -= uTime * (0.35 + 0.5 * hash(vec2(id.x, float(k) + 3.0))) * sc * 0.25;
        id = floor(p);
        vec2 f = fract(p) - 0.5;
        vec2 h = rand(id + float(k) * 31.0);
        if (h.x > 0.45) {
            vec2 c = (h - 0.5) * 0.5;
            vec2 d = f - c;
            d.y *= 0.7;
            float r = 0.16 + 0.1 * h.y;
            float m = smoothstep(r, r * 0.6, length(d));
            offs -= d * m * 0.5 / sc * 3.0;
            spec += m * smoothstep(0.06, 0.0, length(d - vec2(-0.05, -0.06)));
        }
    }
    vec2 suv = clamp(uv + vec2(offs.x / (uResolution.x / uResolution.y), offs.y), 0.0, 1.0);
    vec3 color = baseColor * vec3(0.86, 0.93, 1.0);
    color += spec * 0.8;

    // Apply Shader A's face-aware warping for weather effects
    vec2 d = uv - uFaceCenter;
    d.x *= uResolution.x / uResolution.y;
    float r = length(d);
    float R = max(uFaceScale * 1.5, 0.2);
    float fall = 1.0 - smoothstep(0.0, R, r);
    float ang = 2.4 * sin(uTime * 0.8) * fall;
    float s = sin(ang);
    float c = cos(ang);
    d = vec2(c * d.x - s * d.y, s * d.x + c * d.y);
    d.x /= uResolution.x / uResolution.y;
    vec2 warpedUv = uFaceCenter + d;
    vec3 warpedColor = texture(uTexture, clamp(warpedUv, 0.0, 1.0)).rgb;

    // Weather overlay: rain, snow, fog, dust, sparks using hash, fract, sin, uTime
    float effect = 0.0;
    for (int i = 0; i < 6; i++) {
        float t = uTime + float(i) * 0.4;
        vec2 p = uv * 18.0 + vec2(sin(t * 0.6), cos(t * 0.7)) * 1.8;
        p += rand(vec2(float(i), 12.0)) * 0.07;
        float f = fract(sin(dot(p, vec2(13.45, 56.78))) * 23456.78);
        float size = f * 0.07 + 0.02;
        float d = length(p - vec2(0.5));
        float s = smoothstep(size, size * 0.6, f * (1.0 - d * 0.7));
        effect += s * (0.02 + 0.015 * float(i));
    }
    color += effect * 0.25;

    // Particle system: sparks with motion trails using hash, fract, sin, uTime
    float cw = uResolution.x / 50.0;
    vec2 g = FlutterFragCoord().xy / vec2(cw, cw * 1.2);
    vec2 cell = floor(g);
    vec2 f = fract(g);
    float hcol = hash(vec2(cell.x, 10.0));
    float rows = uResolution.y / (cw * 1.2);
    float head = fract(uTime * (0.15 + 0.25 * hcol) + hcol * 6.0) * (rows + 12.0);
    float dist = head - cell.y;
    float trail = dist > 0.0 ? exp(-dist * 0.25) : 0.0;
    float isHead = step(0.0, dist) * step(dist, 1.0);
    float tick = floor(uTime * (3.5 + 5.0 * hash(cell)));
    vec2 bit = floor(f * vec2(5.0, 7.0));
    float glyph = step(0.5, hash(bit + cell * 6.5 + tick));
    glyph *= step(0.3, f.x) * step(f.x, 0.7) * step(0.2, f.y) * step(f.y, 0.8);
    float l = dot(baseColor, vec3(0.299, 0.587, 0.114));
    vec3 particleCol = vec3(0.01, 0.15, 0.05) * l;
    particleCol += vec3(0.15, 0.9, 0.25) * glyph * (trail * (0.4 + 0.8 * l) + 0.08 * l);
    particleCol += vec3(0.8, 1.0, 0.9) * glyph * isHead;

    // Final blend: base + weather + particles
    color += particleCol;

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
