#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonColor(float t) {
    return mix(vec3(0.1, 0.3, 0.8), vec3(1.0, 0.2, 0.8), sin(t * 0.5 + 1.0) * 0.5 + 0.5);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter / uResolution;
    float scale = uFaceScale;

    // Apply kaleidoscope effect: mirror around face center with rotation
    vec2 p = (uv - center) * scale;
    float angle = uTime * 0.5;
    float cosA = cos(angle);
    float sinA = sin(angle);
    vec2 rotated = vec2(p.x * cosA - p.y * sinA, p.x * sinA + p.y * cosA);
    
    // Mirror across 4 quadrants (kaleidoscope with 4-fold symmetry)
    vec2 mirrored = abs(rotated);
    vec2 finalUV = center + mirrored / scale;

    // Sample texture with smooth interpolation
    vec3 col = texture(uTexture, finalUV).rgb;

    // Add flowing motion with time-based distortion
    float flow = sin(uv.x * 10.0 + uTime) * sin(uv.y * 10.0 + uTime * 1.2) * 0.02;
    vec2 distortedUV = finalUV + vec2(flow, -flow) * 0.003;
    col = mix(col, texture(uTexture, distortedUV).rgb, 0.1);

    // Enhance with neon glow and saturation
    float bright = length(col);
    vec3 glow = neonColor(uTime) * pow(bright, 0.5) * 3.0;
    col = mix(col, glow, 0.3);

    // Add vibrant color grading
    col = pow(col, vec3(0.8));
    col = mix(col, vec3(1.0), pow(bright, 1.2) * 0.4);

    // Subtle motion blur for fluidity
    vec2 px = 2.0 / uResolution;
    vec3 blur = vec3(0.0);
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            blur += texture(uTexture, finalUV + offset).rgb;
        }
    }
    blur /= 9.0;
    col = mix(col, blur, 0.15);

    // Final glow and edge enhancement
    float edge = 1.0 - smoothstep(0.1, 0.9, length(col - 0.5));
    col += neonColor(uTime) * edge * 0.5;

    // Soft vignette with motion
    vec2 vig = uv * 2.0 - 1.0;
    float vignette = pow(clamp(1.0 - dot(vig * 0.6, vig * 0.6), 0.0, 1.0), 0.3);
    col *= mix(0.9, 1.0, vignette);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
