#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float hash21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
vec2 hash22(vec2 p) { float n = hash21(p); return vec2(n, hash21(p + n + 17.1)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
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
    vec3 col = texture(uTexture, suv).rgb * vec3(0.86, 0.93, 1.0);
    col += spec * 0.8;
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
