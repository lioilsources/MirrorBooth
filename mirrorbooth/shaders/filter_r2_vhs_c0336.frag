#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 curvedWarp(vec2 uv, float intensity) {
    vec2 c = uv - 0.5;
    float r2 = dot(c, c);
    c *= 1.0 + intensity * r2 * (1.0 - r2);
    return c + 0.5;
}

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // CRT screen curvature with time-varying distortion
    float curve = 0.12 + 0.03 * sin(uTime * 0.5);
    vec2 distortedUV = curvedWarp(uv, curve);

    // Shadow mask: RGB stripe pattern with vertical frequency and jitter
    float mask = mod(uv.y * uResolution.y * 3.0 + uTime * 10.0, 1.0) < 0.33 ? 1.0 : 0.0;
    vec3 baseColor = texture(uTexture, distortedUV).rgb * mask;

    // Chroma bleed: lateral color shift with dynamic phase and amplitude
    float offset = 0.003 * sin(uTime * 2.0 + uv.y * 5.0);
    float r = texture(uTexture, distortedUV + vec2(offset, 0.0)).r;
    float g = texture(uTexture, distortedUV).g;
    float b = texture(uTexture, distortedUV - vec2(offset, 0.0)).b;
    vec3 colorShift = vec3(r, g, b);

    // Scanlines: horizontal intensity modulation based on FlutterFragCoord().y
    float scan = 0.6 + 0.4 * sin(FlutterFragCoord().y * 3.14159 * 0.5);
    vec3 scanline = colorShift * scan;

    // Add subtle tracking error: horizontal wobble modulated by time and vertical position
    float wobble = 0.005 * sin(uTime * 1.3 + uv.y * 2.0);
    vec2 wobbledUV = distortedUV + vec2(wobble, 0.0);
    vec3 tracking = texture(uTexture, wobbledUV).rgb;

    // Blend tracking and scanline effects
    vec3 finalColor = mix(scanline, tracking, 0.3);

    // Apply dynamic noise pattern for tape grain
    float noise = fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453);
    finalColor += (noise - 0.5) * 0.03;

    // Phosphor glow: soft emission on bright regions with blue bias
    float bright = lum(finalColor);
    finalColor += 0.05 * bright * vec3(0.0, 0.0, 0.1);

    // Vignette: asymmetric darkening with edge falloff
    vec2 v = uv - 0.5;
    float dist = length(v * vec2(1.0, 0.8));
    float vignette = pow(clamp(1.0 - dist * 2.0, 0.0, 1.0), 1.2);
    finalColor *= vignette;

    // Final color grading: warm tone, contrast boost, and fade to blue at top
    finalColor *= 1.1;
    finalColor = mix(finalColor, vec3(0.9, 0.85, 0.95), 0.1 * uv.y);
    finalColor = pow(clamp(finalColor, 0.0, 1.0), vec3(0.95));

    fragColor = vec4(finalColor, 1.0);
}
