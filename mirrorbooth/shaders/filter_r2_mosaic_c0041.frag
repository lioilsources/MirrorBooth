#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

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

    // Apply square cell quantization using floor
    vec2 cells = vec2(44.0, 44.0 * uResolution.y / uResolution.x);
    vec2 cellCenter = floor(uv * cells + 0.5) / cells;
    vec3 quantizedCol = texture(uTexture, cellCenter).rgb;

    // Blend Voronoi result with square quantized color
    float blend = smoothstep(0.02, 0.09, d2 - d1);
    col = mix(quantizedCol, col, blend);

    // Apply hexagonal grid via mod and round for visual variation
    float s = 34.0;
    vec2 p_hex = vec2(uv.x * aspect, uv.y) * s;
    vec2 r = vec2(1.0, 1.7320508);
    vec2 h = r * 0.5;
    vec2 a = mod(p_hex, r) - h;
    vec2 b = mod(p_hex - h, r) - h;
    vec2 g = dot(a, a) < dot(b, b) ? a : b;
    vec2 c_hex = (p_hex - g) / s;
    vec3 hexCol = texture(uTexture, clamp(vec2(c_hex.x / aspect, c_hex.y), 0.0, 1.0)).rgb;

    // Final blend: use mod for Voronoi and floor for square, with round for hex
    float strength = 0.6 + 0.4 * sin(uTime * 0.3);
    col = mix(col, hexCol, strength);

    col = pow(col, vec3(0.85)) * 1.15;
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
