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
    vec2 st = 2.2 / uResolution;
    vec3 best = vec3(0.0);
    float bestVar = 1e9;
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
    vec3 col = pow(best, vec3(0.92)) * 1.08;

    // Replace Kuwahara with oil paint brush stroke effect (replaces the watercolor bleeding)
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

    // Add subtle paper texture and color bleed for watercolor feel
    vec2 paper = uv * 100.0;
    float paperNoise = hash21(floor(paper));
    float bleed = (0.5 + 0.5 * sin(uTime * 0.4 + paperNoise * 3.0)) * 0.15;
    vec3 paperColor = vec3(0.98, 0.92, 0.85);
    col += (paperColor - col) * bleed;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
