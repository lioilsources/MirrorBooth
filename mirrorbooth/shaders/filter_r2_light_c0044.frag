#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 px = 2.0 / uResolution;
    vec3 center = texture(uTexture, uv).rgb;

    vec3  accum  = vec3(0.0);
    float wTotal = 0.0;
    vec3  glow   = vec3(0.0);

    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            vec3  s = texture(uTexture, uv + vec2(float(i), float(j)) * px).rgb;
            float d = length(s - center);
            float w = exp(-d * d * 12.0);
            accum  += s * w;
            wTotal += w;
            glow   += max(s - 0.8, 0.0) * w;
        }
    }

    vec3 smoothed = accum / wTotal;
    vec3 col = mix(center, smoothed, 0.7);

    // Enhanced light rays using smoothstep for radial falloff
    vec2 rayDir = uv - 0.5;
    float rayLen = length(rayDir);
    float ray = smoothstep(0.2, 0.0, rayLen) * (1.0 - pow(rayLen, 2.0));
    col += ray * 0.3;

    // Bokeh circles: simulated with radial blur and threshold
    float bright = lum(center);
    float bokeh = smoothstep(0.85, 1.0, bright) * pow(1.0 - rayLen, 2.0);
    col += bokeh * 0.5;

    // Final bloom with pow for tone curve
    col += pow(glow, vec3(0.7)) * 0.4;

    // Vignette with mix and max
    vec2 vig = uv * 2.0 - 1.0;
    float vignette = max(0.0, 1.0 - dot(vig, vig) * 1.2);
    col *= mix(0.9, 1.0, vignette);

    // Warm tone and subtle time-based glow pulsation
    col *= vec3(1.05, 1.02, 0.96);
    col = pow(clamp(col, 0.0, 1.0), vec3(0.95 + 0.05 * sin(uTime * 0.5)));

    fragColor = vec4(col, 1.0);
}
