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

    // Use fract to create a smooth, periodic threshold variation
    float threshold = smoothstep(0.0, 1.0, fract(brightness * 0.7 + uTime * 0.05));

    // Use mod to generate a randomized offset pattern across the grid
    float pattern = mod(cell.x * 1.7 + cell.y * 0.9, 1.0);

    // Control dot size using brightness and a mod-based offset
    float dotSize = step(threshold, brightness * 0.5 + 0.5 * pattern);

    // Apply the edge softening effect from the other filter: radial blur based on face distance
    float dist = abs(uv.y - uFaceCenter.y);
    float amt = smoothstep(0.12, 0.42, dist);
    vec2 rad = amt * 9.0 / uResolution;

    // Add multiple samples around the center to simulate halftone dot diffusion
    vec3 acc = texture(uTexture, uv).rgb;
    for (int i = 0; i < 12; i++) {
        float a = 2.3999632 * float(i);
        float r = sqrt((float(i) + 0.5) / 12.0);
        acc += texture(uTexture, uv + vec2(cos(a), sin(a)) * r * rad).rgb;
    }
    vec3 col = acc / 13.0;

    // Final color: dark gray dots on a light off-white background
    vec3 baseColor = vec3(0.15, 0.15, 0.15);
    vec3 highlightColor = vec3(0.95, 0.95, 0.95);
    vec3 finalColor = mix(baseColor, highlightColor, dotSize);

    // Add subtle noise using fract and smoothstep for soft dithering
    float softness = smoothstep(0.1, 0.9, fract(f.x * 0.5 + f.y * 0.3));
    finalColor = mix(finalColor, vec3(0.25, 0.25, 0.25), softness * 0.15);

    // Apply color correction from the other filter to preserve skin tones
    col = mix(vec3(luma(col)), col, 1.45);
    col = (col - 0.5) * 1.12 + 0.5;

    // Final output blends the halftone pattern with the corrected color
    fragColor = vec4(mix(finalColor, col, dotSize), 1.0);
}
