#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

vec3 duotoneMap(vec3 color, vec3 low, vec3 high) {
    float level = luma(color);
    float t = smoothstep(0.0, 1.0, level);
    return mix(low, high, t);
}

vec3 thermalEffect(vec3 color) {
    float gray = luma(color);
    float t = (gray + 0.5 * sin(uTime * 0.3)) * 0.5;
    return vec3(
        smoothstep(0.0, 0.4, t),
        smoothstep(0.3, 0.6, t),
        smoothstep(0.6, 1.0, t)
    );
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 src = texture(uTexture, uv).rgb;

    // Posterize using floor
    float levels = 12.0;
    vec3 posterized = floor(src * levels) / levels;

    // Apply duotone using mix and smoothstep
    vec3 duotoneColor = duotoneMap(posterized, vec3(0.1, 0.3, 0.6), vec3(0.9, 0.5, 0.1));

    // Thermal camera effect using smoothstep
    vec3 thermal = thermalEffect(posterized);

    // Gradient mapping: use floor to quantize intensity, then map via smoothstep
    float intensity = luma(posterized);
    float quantized = floor(intensity * 10.0) / 10.0;
    float mapped = smoothstep(0.0, 1.0, quantized);

    // Final output: blend thermal and duotone with time-based modulation
    float timeFactor = 0.5 + 0.5 * sin(uTime * 0.8);
    vec3 finalColor = mix(thermal, duotoneColor, timeFactor);

    // Add subtle gradient modulation using floor and smoothstep
    float offset = floor(uTime * 3.0) * 0.1;
    float adjusted = (mapped + offset) * 0.9;
    finalColor = mix(finalColor, vec3(0.2, 0.6, 0.8), smoothstep(0.2, 0.8, adjusted));

    // Take output of Shader B and apply to Shader A's thermal palette logic
    float l = luma(finalColor);
    float noise = (fract(sin(dot(uv * 123.45, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 0.03;
    vec3 graded = vec3(
        smoothstep(0.0, 0.17, l + noise),
        smoothstep(0.17, 0.33, l + noise),
        smoothstep(0.33, 0.5, l + noise)
    );

    // Apply floor to control color banding in duotone transition
    float band = floor(l * 10.0) / 10.0;
    vec3 bandColor = mix(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), band);
    graded = mix(graded, bandColor, smoothstep(0.0, 1.0, band));

    fragColor = vec4(graded, 1.0);
}
