#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 color = texture(uTexture, uv).rgb;
    float lum = luma(color);
    
    // Posterize with floor
    float levels = 8.0;
    float posterized = floor(lum * levels) / levels;
    
    // Thermal camera effect using smoothstep
    vec3 thermal = vec3(
        smoothstep(0.2, 0.4, posterized),
        smoothstep(0.4, 0.6, posterized),
        smoothstep(0.6, 0.8, posterized)
    );
    
    // Duotone mapping using mix
    vec3 lowColor = vec3(0.1, 0.2, 0.4);
    vec3 highColor = vec3(1.0, 0.7, 0.1);
    vec3 finalColor = mix(lowColor, highColor, posterized);
    
    // Add subtle gradient mapping with floor and time modulation
    float gradientOffset = floor(uTime * 2.0) * 0.25;
    float adjustedLum = (posterized + gradientOffset) * 0.9;
    finalColor = mix(finalColor, vec3(0.5, 0.3, 0.1), smoothstep(0.3, 0.7, adjustedLum));
    
    fragColor = vec4(finalColor, 1.0);
}
