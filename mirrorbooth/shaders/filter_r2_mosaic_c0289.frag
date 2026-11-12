#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float R = uFaceScale;

    float dx = uv.x - uFaceCenter.x;
    float dy = uv.y - uFaceCenter.y;

    float gx = exp(-(dx * dx) / (1.8 * R * R));
    float headMask = smoothstep(0.45 * R, -0.2 * R, dy);
    float srcY = uFaceCenter.y + dy * (1.0 + 0.35 * headMask);
    float srcX = uFaceCenter.x + dx * (1.0 + 0.28 * headMask * gx);
    float neckMask = smoothstep(0.45 * R, 1.4 * R, dy);
    srcY = uFaceCenter.y + (srcY - uFaceCenter.y) * (1.0 - 0.40 * neckMask);
    srcY = mix(uv.y, srcY, gx);
    srcX = mix(uv.x, srcX, gx);

    vec2 wUV = clamp(vec2(srcX, srcY), 0.0, 1.0);

    // Voronoi cell using mod and round
    float s = 48.0;
    vec2 p = wUV * s;
    vec2 ip = floor(p);
    vec2 fp = fract(p);

    float d1 = 9.0;
    vec2 best = vec2(0.0);
    for (int j = 0; j < 3; j++) {
        for (int i = 0; i < 3; i++) {
            vec2 o = vec2(float(i) - 1.0, float(j) - 1.0);
            vec2 h = vec2(fract(dot(ip + o, vec2(123.34, 456.21))), fract(dot(ip + o + 17.1, vec2(345.12, 234.56))));
            vec2 pt = o + 0.5 + 0.4 * sin(uTime * 0.6 + 6.2831 * h.x);
            float d = length(pt - fp);
            if (d < d1) { d1 = d; best = ip + pt; }
        }
    }

    // Hex grid using mod and round
    vec2 r = vec2(1.0, 1.7320508);
    vec2 h = r * 0.5;
    vec2 a = mod(p, r) - h;
    vec2 b = mod(p - h, r) - h;
    vec2 g = dot(a, a) < dot(b, b) ? a : b;
    vec2 c = (p - g) / s;

    // Final cell with voronoi influence
    vec2 cell = floor(c * 100.0) / 100.0;
    vec3 col = texture(uTexture, vec2(cell.x, cell.y)).rgb;

    // Color modulation by distance
    float d = max(abs(g.y), abs(g.y) * 0.5 + abs(g.x) * 0.8660254);
    col *= 0.55 + 0.45 * smoothstep(0.5, 0.42, d);

    // Apply final hex grid to the voronoi output
    float s2 = 34.0;
    vec2 p2 = uv * s2;
    vec2 r2 = vec2(1.0, 1.7320508);
    vec2 h2 = r2 * 0.5;
    vec2 a2 = mod(p2, r2) - h2;
    vec2 b2 = mod(p2 - h2, r2) - h2;
    vec2 g2 = dot(a2, a2) < dot(b2, b2) ? a2 : b2;
    vec2 c2 = (p2 - g2) / s2;
    vec3 col2 = texture(uTexture, clamp(vec2(c2.x, c2.y), 0.0, 1.0)).rgb;
    float d2 = max(abs(g2.y), abs(g2.y) * 0.5 + abs(g2.x) * 0.8660254);
    col2 *= 0.55 + 0.45 * smoothstep(0.5, 0.42, d2);

    // Mix voronoi and hex results
    fragColor = vec4(mix(col, col2, 0.5), 1.0);
}
