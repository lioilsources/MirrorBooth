#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

vec3 neonGlow(float t) {
    return vec3(
        0.8 + 0.7 * sin(t * 2.3 + 0.2),
        0.2 + 0.8 * sin(t * 2.3 + 2.4),
        1.3 + 0.6 * sin(t * 2.3 + 4.7)
    ) * 2.5;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float px = floor(uResolution.x / 100.0);
    vec2 cell = floor(FlutterFragCoord().xy / px);
    vec2 f = fract(FlutterFragCoord().xy / px);

    // Sample the original color at the center of each cell
    vec3 color = texture(uTexture, (cell + 0.5) * px / uResolution).rgb;
    float brightness = luma(color);

    // Use fract to create a periodic variation in the threshold
    float threshold = smoothstep(0.0, 1.0, fract(brightness + uTime * 0.03));

    // Use mod to generate a staggered, randomized-looking pattern across the grid
    float pattern = mod(cell.x * 0.8 + cell.y * 1.2, 2.0);

    // Control dot size using brightness and the mod pattern
    float dotSize = step(threshold, brightness * 0.6 + 0.4 * pattern);

    // Final color: dark brown dots on a light beige background
    vec3 baseColor = vec3(0.22, 0.14, 0.08);
    vec3 highlightColor = vec3(0.92, 0.86, 0.72);
    vec3 finalColor = mix(baseColor, highlightColor, dotSize);

    // Add subtle texture variation using fract and smoothstep for softness
    float softness = smoothstep(0.2, 0.8, fract(f.x * 0.4 + f.y * 0.6));
    finalColor = mix(finalColor, vec3(0.33, 0.25, 0.17), softness * 0.2);

    // Transfer: Apply neonGlow as a pulsing tint on the halftone output
    float pulse = 1.0 + 0.8 * sin(uTime * 2.4);
    finalColor = mix(finalColor, neonGlow(uTime * 1.6), pulse * 0.3);

    fragColor = vec4(finalColor, 1.0);
}
