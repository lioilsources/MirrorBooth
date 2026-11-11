#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 center = texture(uTexture, uv).rgb;

    // Accumulate neighbors with exponential weight
    vec3 accum = vec3(0.0);
    float wTotal = 0.0;
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec3 s = texture(uTexture, uv + vec2(float(i), float(j)) * 2.0 / uResolution).rgb;
            float d = length(s - center);
            float w = exp(-d * d * 10.0);
            accum += s * w;
            wTotal += w;
        }
    }
    vec3 smoothed = accum / wTotal;
    vec3 col = mix(center, smoothed, 0.6);

    // Bloom via exponential glow on bright areas
    float bright = lum(max(col - 0.6, 0.0));
    float glow = exp(bright * 4.0 - 1.0) * 0.3;
    col += vec3(glow);

    // Warm tone shift with power curve
    col *= vec3(1.08, 1.02, 0.92);
    col = pow(clamp(col, 0.0, 1.0), vec3(0.95));

    // Vignette with smooth radial falloff
    vec2 vig = uv * 2.0 - 1.0;
    float dist = length(vig);
    float vignette = smoothstep(0.6, 1.0, dist);
    col *= mix(1.0, 0.8, vignette);

    // Light rays with time-based wave
    vec2 rayDir = uv - 0.5;
    float rayDist = length(rayDir);
    float rayIntensity = pow(1.0 - rayDist, 2.0) * 0.8;
    float rayPattern = sin(rayDist * 15.0 + uTime * 0.6) * 0.5 + 0.5;
    col += vec3(rayIntensity * rayPattern * 0.5);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
