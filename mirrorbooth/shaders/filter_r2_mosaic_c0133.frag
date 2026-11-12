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
    float R = uFaceScale;

    float dx = uv.x - uFaceCenter.x;
    float dy = uv.y - uFaceCenter.y;

    float gx = exp(-(dx * dx * aspect * aspect) / (1.8 * R * R));
    float headMask = smoothstep(0.45 * R, -0.2 * R, dy);
    float srcY = uFaceCenter.y + dy * (1.0 + 0.35 * headMask);
    float srcX = uFaceCenter.x + dx * (1.0 + 0.28 * headMask * gx);
    float neckMask = smoothstep(0.45 * R, 1.4 * R, dy);
    srcY = uFaceCenter.y + (srcY - uFaceCenter.y) * (1.0 - 0.40 * neckMask);
    srcY = mix(uv.y, srcY, gx);
    srcX = mix(uv.x, srcX, gx);

    vec2 wUV = clamp(vec2(srcX, srcY), 0.0, 1.0);

    float s = 48.0;
    vec2 p = vec2(wUV.x * aspect, wUV.y) * s;
    vec2 ip = floor(p);
    vec2 fp = fract(p);

    // Voronoi cell determination using mod and round
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

    // Apply hexagonal grid transformation using mod and round
    vec2 r = vec2(1.0, 1.7320508);
    vec2 h = r * 0.5;
    vec2 a = mod(p, r) - h;
    vec2 b = mod(p - h, r) - h;
    vec2 g = dot(a, a) < dot(b, b) ? a : b;
    vec2 c = (p - g) / s;

    // Final cell position with voronoi influence and hex grid
    vec2 cell = floor(c * 100.0) / 100.0;
    vec3 col = texture(uTexture, clamp(vec2(cell.x / aspect, cell.y), 0.0, 1.0)).rgb;

    // Apply color modulation based on distance to cell center
    float d = max(abs(g.y), abs(g.y) * 0.5 + abs(g.x) * 0.8660254);
    col *= 0.55 + 0.45 * smoothstep(0.5, 0.42, d);

    // Add slight glow and enhance contrast
    col = pow(col, vec3(0.85)) * 1.15;
    col *= smoothstep(0.02, 0.09, d2 - d1);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
