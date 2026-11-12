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
    vec3 base = texture(uTexture, uv).rgb;
    
    // Apply Shader B's core effect: snow overlay with motion
    vec3 col = mix(vec3(luma(base)), base, 0.8) * vec3(0.9, 0.97, 1.08) + 0.03;
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

    // Apply Shader A's particle motion and distortion
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
    vec3 finalCol = texture(uTexture, suv).rgb * vec3(0.86, 0.93, 1.0);
    finalCol += spec * 0.8;

    // Blend both effects: snow on top of motion distortion
    fragColor = vec4(mix(col, finalCol, 0.6), 1.0);
}
