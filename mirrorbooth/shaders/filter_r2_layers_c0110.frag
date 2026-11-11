#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float hash21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
vec2 hash22(vec2 p) { float n = hash21(p); return vec2(n, hash21(p + n + 17.1)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 baseColor = texture(uTexture, uv).rgb;

    // Apply motion distortion from Shader B's core technique
    float aspect = uResolution.x / uResolution.y;
    vec2 offs = vec2(0.0);
    float spec = 0.0;
    for (int k = 0; k < 2; k++) {
        float sc = k == 0 ? 7.0 : 12.0;
        vec2 p = vec2(uv.x * aspect, uv.y) * sc;
        vec2 id = floor(p);
        p.y -= uTime * (0.35 + 0.5 * hash21(vec2(id.x, float(k) + 3.0))) * sc * 0.25;
        id = floor(p);
        vec2 f = fract(p) - 0.5;
        vec2 h = hash22(id + float(k) * 31.0);
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
    vec2 suv = clamp(uv + vec2(offs.x / aspect, offs.y), 0.0, 1.0);
    vec3 col = baseColor * vec3(0.86, 0.93, 1.0);
    col += spec * 0.8;

    // Add weather and particle overlay using Shader A's core techniques
    float time = uTime * 0.7;
    float cw = uResolution.x / 34.0;
    vec2 g = FlutterFragCoord().xy / vec2(cw, cw * 1.35);
    vec2 cell = floor(g);
    vec2 f = fract(g);
    float hcol = hash21(vec2(cell.x, 7.0));
    float rows = uResolution.y / (cw * 1.35);
    float head = fract(time * (0.12 + 0.3 * hcol) + hcol * 5.0) * (rows + 14.0);
    float dist = head - cell.y;
    float trail = dist > 0.0 ? exp(-dist * 0.2) : 0.0;
    float isHead = step(0.0, dist) * step(dist, 1.0);
    float tick = floor(time * (4.0 + 8.0 * hash21(cell)));
    vec2 bit = floor(f * vec2(4.0, 6.0));
    float glyph = step(0.5, hash21(bit + cell * 7.3 + tick));
    glyph *= step(0.12, f.x) * step(f.x, 0.88) * step(0.08, f.y) * step(f.y, 0.92);
    float l = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
    vec3 particleCol = vec3(0.02, 0.34, 0.12) * l;
    particleCol += vec3(0.15, 1.0, 0.4) * glyph * (trail * (0.35 + 1.1 * l) + 0.1 * l);
    particleCol += vec3(0.7, 1.0, 0.8) * glyph * isHead;

    // Apply rain streaks with randomized motion
    float rainStrength = 0.1;
    vec2 rainOffset = vec2(0.0);
    for (int i = 0; i < 3; i++) {
        float speed = 0.3 + 0.4 * float(i);
        float phase = float(i) * 0.5;
        vec2 pos = uv * 15.0 + vec2(0.0, time * speed + phase);
        float t = fract(sin(dot(pos, vec2(12.9898, 78.233))) * 43758.5453);
        float drop = step(0.4, t);
        float streak = 0.1 + 0.2 * sin(time * 1.2 + float(i) * 0.7);
        rainOffset += vec2(0.0, -streak * drop * 0.01) * (1.0 + float(i) * 0.2);
    }
    vec2 rainUV = uv + rainOffset;
    vec3 rainCol = vec3(0.3, 0.6, 0.8) * rainStrength * 0.8;
    col += texture(uTexture, rainUV).rgb * rainCol * 0.7;

    // Add snow particles with floating motion
    float snowStrength = 0.08;
    vec2 snowPos = uv * 20.0;
    vec2 snowCell = floor(snowPos);
    float snowNoise = hash21(snowCell + time * 0.1);
    float snow = step(0.85, snowNoise);
    vec2 snowOffset = vec2(0.0, -0.01 * snow * (1.0 + 0.5 * sin(time * 0.8))) * 0.02;
    vec2 snowUV = uv + snowOffset;
    vec3 snowCol = vec3(1.0, 1.0, 1.0) * snowStrength * 0.6;
    col += texture(uTexture, snowUV).rgb * snowCol * 0.4;

    // Add fog haze with time modulation
    float fogStrength = 0.05;
    float fog = 0.5 + 0.5 * sin(time * 0.4 + uv.x * 2.0);
    fog = smoothstep(0.4, 0.6, fog);
    fog = pow(fog, 1.5);
    col = mix(col, vec3(0.8, 0.9, 1.0), fog * 0.4);

    // Add dust/sparks with flickering points
    float sparkStrength = 0.03;
    vec2 sparkPos = uv * 10.0;
    vec2 sparkCell = floor(sparkPos);
    float sparkNoise = fract(sin(dot(sparkCell, vec2(12.9898, 78.233))) * 43758.5453);
    float spark = step(0.9, sparkNoise);
    float sparkFlicker = 0.5 + 0.5 * sin(time * 3.0 + sparkCell.x * 0.7 + sparkCell.y * 0.5);
    spark *= sparkFlicker;
    vec3 sparkCol = vec3(1.0, 0.7, 0.3) * sparkStrength * 1.5;
    col += sparkCol * spark;

    // Blend particle overlay from Shader A’s technique
    col += particleCol * 0.2;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
