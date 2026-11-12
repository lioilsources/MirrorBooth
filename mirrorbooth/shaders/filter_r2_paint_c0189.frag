#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 st = 2.5 / uResolution;
    vec3 best = vec3(0.0);
    float bestVar = 1e9;

    // Step 1: Apply Kuwahara-style averaging with 4 quadrants (Shader B's technique)
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

    // Step 2: Add watercolor bleeding effect (Shader A's technique)
    vec3 src = texture(uTexture, uv).rgb;
    float edge = length(src - best) * 12.0;
    float bleed = smoothstep(0.4, 0.8, edge);

    // Step 3: Simulate paper texture and soft bleeding
    vec2 cell = floor(uv * 16.0);
    float paper = fract(dot(cell, vec2(123.34, 456.21)));
    vec3 paperColor = vec3(0.96, 0.93, 0.89) * (0.9 + 0.1 * paper);
    vec3 wet = mix(best, src, 0.6);
    wet = mix(wet, paperColor, 0.25 * bleed);

    // Step 4: Apply dynamic distortion from shader B's transfer technique
    vec2 p = uv - 0.5;
    float s = max(max(abs(p.x), abs(p.y)) * 2.0, 0.0005);
    float t = fract(uTime * 0.3);
    float k = log2(1.0 / s) + t;
    float n = floor(k);
    float zoom = exp2(n - t);
    vec2 q = p * zoom;
    vec3 col = texture(uTexture, clamp(q + 0.5, 0.0, 1.0)).rgb;
    float e = max(abs(q.x), abs(q.y)) * 2.0;
    col *= 0.5 + 0.5 * smoothstep(1.0, 0.92, e);
    col *= 1.0 - 0.2 * smoothstep(0.65, 0.5, e);

    // Step 5: Blend Kuwahara + watercolor with dynamic distortion
    vec3 final = mix(wet, col, 0.4);

    // Step 6: Enhance saturation and tone
    float l = dot(final, vec3(0.299, 0.587, 0.114));
    final = mix(vec3(l), final, 1.6);
    final = 1.0 - (1.0 - final) * 0.9;

    // Final output with slight paper grain
    final = mix(final, paperColor, 0.1 * (1.0 - l));

    fragColor = vec4(clamp(final, 0.0, 1.0), 1.0);
}
