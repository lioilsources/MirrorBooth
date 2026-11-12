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
    vec2 p = vec2(uv.x * aspect, uv.y) * 13.0;
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    float d1 = 9.0;
    float d2 = 9.0;
    vec2 best = vec2(0.0);
    for (int j = 0; j < 3; j++) {
        for (int i = 0; i < 3; i++) {
            vec2 o = vec2(float(i) - 1.0, float(j) - 1.0);
            vec2 h = hash22(ip + o);
            vec2 pt = o + 0.5 + 0.4 * sin(uTime * 0.6 + 6.2831 * h);
            float d = length(pt - fp);
            if (d < d1) { d2 = d1; d1 = d; best = ip + pt; }
            else if (d < d2) { d2 = d; }
        }
    }
    vec2 c = best / 13.0;
    vec3 col = texture(uTexture, clamp(vec2(c.x / aspect, c.y), 0.0, 1.0)).rgb;
    float s = 34.0;
    vec2 p2 = vec2(uv.x * aspect, uv.y) * s;
    vec2 r = vec2(1.0, 1.7320508);
    vec2 h = r * 0.5;
    vec2 a = mod(p2, r) - h;
    vec2 b = mod(p2 - h, r) - h;
    vec2 g = dot(a, a) < dot(b, b) ? a : b;
    vec2 c2 = (p2 - g) / s;
    vec3 col2 = texture(uTexture, clamp(vec2(c2.x / aspect, c2.y), 0.0, 1.0)).rgb;
    float d = max(abs(g.y), abs(g.y) * 0.5 + abs(g.x) * 0.8660254);
    col2 *= 0.55 + 0.45 * smoothstep(0.5, 0.42, d);
    fragColor = vec4(mix(col, col2, 0.5), 1.0);
}
