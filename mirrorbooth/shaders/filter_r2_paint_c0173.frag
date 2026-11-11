#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float hash21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
vec2 hash22(vec2 p) { float n = hash21(p); return vec2(n, hash21(p + n + 17.1)); }
float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 st = 2.2 / uResolution;
    vec3 best = vec3(0.0);
    float bestVar = 1e9;

    // Kuwahara-style sampling with 4 directional quadrants
    for (int q = 0; q < 4; q++) {
        vec2 dir = vec2(q == 0 || q == 2 ? -1.0 : 1.0, q < 2 ? -1.0 : 1.0);
        vec3 m = vec3(0.0);
        vec3 s2 = vec3(0.0);
        for (int j = 0; j < 3; j++) {
            for (int i = 0; i < 3; i++) {
                vec3 c = texture(uTexture, uv + dir * vec2(float(i), float(j)) * st).rgb;
                m += c;
                s2 += c * c;
            }
        }
        m /= 9.0;
        s2 = abs(s2 / 9.0 - m * m);
        float v = s2.r + s2.g + s2.b;
        if (v < bestVar) { bestVar = v; best = m; }
    }

    // Apply Kuwahara result as base
    vec3 col = pow(best, vec3(0.92)) * 1.08;

    // Add dynamic swirling warping for organic brush motion
    vec2 center = uFaceCenter;
    float scale = uFaceScale;
    float distToFace = length(uv - center);
    float swirlStrength = sin(uTime * 4.0 + distToFace * 12.0) * 0.25;
    float swirlAngle = swirlStrength * (1.0 - distToFace * 0.6);
    vec2 swirlOffset = vec2(
        -sin(swirlAngle) * length(uv - center),
        cos(swirlAngle) * length(uv - center)
    );
    vec2 swirlUV = center + swirlOffset;
    vec3 warpedColor = texture(uTexture, swirlUV).rgb;
    col = mix(col, warpedColor, 0.3);

    // Watercolor bleeding effect using noise-driven diffusion
    vec2 paper = uv * 100.0;
    float paperNoise = hash21(floor(paper));
    float bleed = (0.5 + 0.5 * sin(uTime * 0.4 + paperNoise * 3.0)) * 0.15;
    vec3 paperColor = vec3(0.98, 0.92, 0.85);
    col += (paperColor - col) * bleed;

    // Apply oil paint brush stroke with dynamic direction and multiple samples
    float brushSize = 1.5 + 0.5 * sin(uTime * 0.3);
    float brushStrength = 0.35;
    vec2 brushDir = normalize(vec2(cos(uTime * 0.7), sin(uTime * 0.7)));
    vec2 offset = brushDir * brushSize / uResolution;
    vec2 baseUV = uv;
    vec3 strokeColor = vec3(0.0);
    for (int i = 0; i < 4; i++) {
        vec2 sampleUV = baseUV + offset * float(i);
        strokeColor += texture(uTexture, sampleUV).rgb;
    }
    strokeColor /= 4.0;
    col = mix(col, strokeColor, brushStrength);

    // Final adjustment: apply hexagonal grid sampling from Shader B for texture variation
    float aspect = uResolution.x / uResolution.y;
    float s = 34.0;
    vec2 p = vec2(uv.x * aspect, uv.y) * s;
    vec2 r = vec2(1.0, 1.7320508);
    vec2 h = r * 0.5;
    vec2 a = mod(p, r) - h;
    vec2 b = mod(p - h, r) - h;
    vec2 g = dot(a, a) < dot(b, b) ? a : b;
    vec2 c = (p - g) / s;
    vec2 hexUV = clamp(vec2(c.x / aspect, c.y), 0.0, 1.0);
    vec3 hexColor = texture(uTexture, hexUV).rgb;
    col = mix(col, hexColor, 0.3);

    // Boost saturation and finalize
    float l = lum(col);
    col = mix(vec3(l), col, 1.55);

    // Apply dynamic brush blur: simulate brush stroke softening
    vec2 p2 = uv - 0.5;
    float s2 = max(max(abs(p2.x), abs(p2.y)) * 2.5, 0.0001);
    float t = fract(uTime * 0.3);
    float k = log2(1.0 / s2) + t;
    float n = floor(k);
    float blur = exp2(n - t) * 0.5;
    vec2 q = p2 * blur;
    vec3 col2 = texture(uTexture, clamp(q + 0.5, 0.0, 1.0)).rgb;
    float e = max(abs(q.x), abs(q.y)) * 3.0;
    col2 *= 0.5 + 0.5 * smoothstep(1.0, 0.85, e);
    col2 *= 1.0 - 0.3 * smoothstep(0.7, 0.6, e);

    // Blend with brush blur
    col = mix(col, col2, 0.25);

    // Final color correction: increase contrast and add subtle hue shift
    col = 1.0 - (1.0 - col) * 0.85;
    col = mix(col, vec3(lum(col)), 0.15);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
