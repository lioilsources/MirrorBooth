#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float px = floor(uResolution.x / 80.0);
    vec2 cell = floor(FlutterFragCoord().xy / px);
    vec2 f = fract(FlutterFragCoord().xy / px);

    // Sample the original color at the center of each cell
    vec3 color = texture(uTexture, (cell + 0.5) * px / uResolution).rgb;
    float brightness = luma(color);

    // Use fract to create a periodic dithering pattern
    float dither = fract(brightness * 3.0 + uTime * 0.03 + f.x * 0.6 + f.y * 0.4);

    // Use mod to generate a staggered, randomized-looking pattern across the grid
    float pattern = mod(cell.x * 0.9 + cell.y * 1.3, 2.0);

    // Use step to determine if a dot should be rendered based on brightness and dither
    float threshold = step(0.6, dither);
    float dot = step(0.5, brightness * (0.7 + 0.3 * pattern));

    // Control dot size using smoothstep and fract for soft transitions
    float size = smoothstep(0.2, 0.8, fract(brightness * 4.0 + uTime * 0.015));

    // Final color: dark gray dots on a light gray background
    vec3 baseColor = vec3(0.18, 0.18, 0.18);
    vec3 highlightColor = vec3(0.9, 0.9, 0.9);
    vec3 finalColor = mix(baseColor, highlightColor, dot * size);

    // Add subtle texture variation using fract and smoothstep for softness
    float softness = smoothstep(0.3, 0.7, fract(f.x * 0.4 + f.y * 0.9));
    finalColor = mix(finalColor, vec3(0.25, 0.25, 0.25), softness * 0.15);

    fragColor = vec4(finalColor, 1.0);
}
