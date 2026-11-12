#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 st = 2.5 / uResolution;
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
    // Replace the original power function with a watercolor bleeding effect
    vec3 col = best;
    // Simulate watercolor bleed by blending with neighboring samples
    vec2 offset = vec2(0.5, 0.5) * st;
    col += texture(uTexture, uv + offset).rgb * 0.15;
    col += texture(uTexture, uv - offset).rgb * 0.15;
    col += texture(uTexture, uv + vec2(-offset.x, offset.y)).rgb * 0.15;
    col += texture(uTexture, uv + vec2(offset.x, -offset.y)).rgb * 0.15;
    col = clamp(col, 0.0, 1.0);
    fragColor = vec4(col, 1.0);
}
