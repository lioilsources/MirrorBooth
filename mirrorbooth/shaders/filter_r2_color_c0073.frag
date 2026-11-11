#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

vec3 gradientMap(vec3 color) {
    float intensity = luma(color);
    float quantized = floor(intensity * 8.0) / 8.0;
    float t = smoothstep(0.0, 1.0, quantized);
    return vec3(
        smoothstep(0.0, 0.3, t),
        smoothstep(0.3, 0.6, t),
        smoothstep(0.6, 1.0, t)
    );
}

vec3 negativeEffect(vec3 color) {
    return vec3(1.0) - color;
}

vec3 posterizeEffect(vec3 color) {
    float levels = 16.0;
    return floor(color * levels) / levels;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;
    vec3 src = texture(uTexture, uv).rgb;

    // Posterize using floor
    vec3 p = posterizeEffect(src);

    // Apply gradient mapping using mix, smoothstep, and floor
    vec3 grad = gradientMap(p);

    // Thermal effect using smoothstep and mix
    float gray = luma(p);
    float t = (gray + 0.5 * sin(uTime * 0.5)) * 0.5;
    vec3 thermal = vec3(
        smoothstep(0.0, 0.4, t),
        smoothstep(0.3, 0.6, t),
        smoothstep(0.6, 1.0, t)
    );

    // Negative using mix with inverse
    vec3 neg = mix(vec3(1.0), p, 0.6);

    // Final blend with time-based modulation using smoothstep and floor
    float timeCycle = floor(uTime * 2.0) * 0.2;
    float blendFactor = smoothstep(0.2, 0.8, (timeCycle + 0.5));
    vec3 finalColor = mix(thermal, grad, blendFactor);

    // Add subtle color shift using floor and smoothstep
    float intensity = luma(p);
    float quantized = floor(intensity * 10.0) / 10.0;
    float offset = smoothstep(0.0, 1.0, quantized);
    finalColor = mix(finalColor, vec3(0.8, 0.3, 0.1), offset * 0.3);

    fragColor = vec4(finalColor, 1.0);
}
