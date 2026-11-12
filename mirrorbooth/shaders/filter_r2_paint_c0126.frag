#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 px = 2.0 / uResolution;
    vec3 center = texture(uTexture, uv).rgb;

    // Kuwahara-inspired hexagonal grid sampling
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

    // Bilateral blur for oil paint effect
    vec3 accum = vec3(0.0);
    float wTotal = 0.0;
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            vec3 s = texture(uTexture, uv + vec2(float(i), float(j)) * px).rgb;
            float d = length(s - center);
            float w = exp(-d * d * 18.0);
            accum += s * w;
            wTotal += w;
        }
    }
    vec3 col = accum / wTotal;

    // Blend with hex grid color for texture variation
    col = mix(col, hexColor, 0.3);

    // Boost saturation
    float l = lum(col);
    col = mix(vec3(l), col, 1.55);

    // Apply watercolor bleeding effect from other filter: simulate edge softness and paper absorption
    vec2 q = abs(uv - 0.5);
    vec2 suv = vec2(0.5 - q.x * 0.9, 0.62 - q.y * 1.1);
    vec3 bleedColor = texture(uTexture, clamp(suv, 0.0, 1.0)).rgb;
    float seam = min(q.x * uResolution.x, q.y * uResolution.y);
    float bleedFactor = 0.8 + 0.2 * smoothstep(0.0, 3.0, seam);
    col = mix(col, bleedColor, 0.2 * bleedFactor);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
