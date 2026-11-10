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

    // High-resolution face centering and distortion
    vec2 p = (uv - center) * scale;
    float angle = uTime * 0.6 + sin(uTime * 0.3) * 0.2;
    float cosA = cos(angle);
    float sinA = sin(angle);
    vec2 rotated = vec2(p.x * cosA - p.y * sinA, p.x * sinA + p.y * cosA);

    // 8-fold kaleidoscope symmetry with smooth folding
    vec2 mirrored = abs(rotated);
    mirrored.x = abs(mirrored.x - 0.5) * 2.0;
    mirrored.y = abs(mirrored.y - 0.5) * 2.0;
    vec2 finalUV = center + mirrored / scale;

    // Primary color sampling with edge-aware interpolation
    vec3 col = texture(uTexture, finalUV).rgb;

    // Dynamic flow field for fluid motion
    float flowX = sin(uv.x * 15.0 + uTime * 1.2) * cos(uv.y * 15.0 + uTime * 0.8) * 0.015;
    float flowY = cos(uv.x * 15.0 + uTime * 1.0) * sin(uv.y * 15.0 + uTime * 1.4) * 0.015;
    vec2 flowUV = finalUV + vec2(flowX, flowY) * 0.005;
    vec3 flowCol = texture(uTexture, flowUV).rgb;

    // Blend with motion for flowing effect
    col = mix(col, flowCol, 0.2);

    // Intensify neon glow with time-varying color and brightness
    float bright = length(col);
    vec3 glow = neonColor(uTime) * pow(bright, 0.4) * 4.0;
    col = mix(col, glow, 0.4);

    // Color grading with enhanced saturation and vibrancy
    col = pow(col, vec3(0.75));
    col = mix(col, vec3(1.0), pow(bright, 1.5) * 0.5);

    // Subtle motion blur with directional bias
    vec2 px = 1.0 / uResolution;
    vec3 blur = vec3(0.0);
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            blur += texture(uTexture, finalUV + offset).rgb;
        }
    }
    blur /= 25.0;
    col = mix(col, blur, 0.2);

    // Edge glow enhancement with dynamic intensity
    float edge = 1.0 - smoothstep(0.2, 0.8, length(col - 0.5));
    col += neonColor(uTime) * edge * 0.6 * (1.0 + sin(uTime * 0.5) * 0.5);

    // Dynamic vignette with motion and softness
    vec2 vig = uv * 2.0 - 1.0;
    float dist = length(vig);
    float vignette = pow(clamp(1.0 - dist * 1.5, 0.0, 1.0), 0.4);
    float motionVignette = 0.8 + 0.2 * sin(uTime * 0.3);
    col *= mix(0.95, 1.0, vignette * motionVignette);

    // Final tone mapping and saturation boost
    col = pow(col, vec3(1.0 / 1.2));
    col = mix(col, vec3(1.0), 0.1);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
