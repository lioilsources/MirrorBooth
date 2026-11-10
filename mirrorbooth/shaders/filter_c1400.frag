#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return vec3(
        0.8 + 0.4 * sin(t * 1.8 + 0.2),
        0.5 + 0.5 * sin(t * 1.8 + 2.5),
        1.0 + 0.3 * sin(t * 1.8 + 4.8)
    ) * 3.0;
}

vec3 flowWaves(vec2 uv, float t) {
    float wave1 = sin(uv.x * 18.0 + t * 1.4) * 0.5 + 0.5;
    float wave2 = cos(uv.y * 16.0 + t * 1.2) * 0.5 + 0.5;
    float wave3 = sin(uv.x * 12.0 + uv.y * 10.0 + t * 1.0) * 0.5 + 0.5;
    return vec3(wave1, wave2, wave3) * 2.0;
}

float kaleidoTransform(vec2 uv, float n, float t, float radius, out vec2 outUV) {
    float angle = 2.0 * 3.14159 / n;
    float a = atan(uv.y, uv.x) + t * 0.8;
    float c = floor(a / angle);
    float d = mod(a, angle);
    float r = length(uv);
    float theta = d / angle;
    float k = (1.0 - theta) * 0.6 + theta * 0.4;

    float flow = 0.5 * sin(d * 8.0 + t * 1.7) * (1.0 - 0.4 * sin(r * 5.0 + t * 1.1));
    float wave = 0.4 * sin(r * 6.0 + t * 1.3) * (1.0 - 0.7 * sin(t * 0.9));
    float distortion = flow * (1.0 + wave);

    float newR = r * (1.0 - distortion * k);
    float newAngle = d + 0.5 * sin(t * 1.1 + d * 6.0);
    vec2 newUV = vec2(cos(newAngle), sin(newAngle)) * newR;

    outUV = newUV;
    return newR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;

    float t = uTime * 0.8;
    float symmetry = 12.0 + 14.0 * sin(t * 0.5);
    float radius = 0.35 + 0.2 * sin(t * 0.35);
    float mask = smoothstep(0.0, uFaceScale * 0.8, length(uv - center));

    vec2 centered = uv - center;
    float distToFace = length(centered);

    // High-frequency kaleidoscopic warping with smooth flow
    vec2 warpedUV;
    float newR = kaleidoTransform(centered, symmetry, t, radius, warpedUV);
    float scale = 1.0 + 1.2 * (1.0 - mask) * (1.0 + 0.7 * sin(t * 0.7));
    vec2 finalUV = center + (warpedUV * (newR / length(centered))) * scale;

    // Sample with warping
    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    // Overlay flowing neon waves across the entire screen
    vec3 wave = flowWaves(uv, t);
    col = mix(col, wave, 0.6 * mask);

    // Intense pulsing neon glow from the center outward
    vec3 glow = neonGlow(t);
    col = mix(col, glow, 0.8 * (1.0 - mask));

    // Soft, glowing edge around the face with motion
    float edgeGlow = 0.7 * (1.0 - mask) * smoothstep(0.0, 0.08, distToFace / uFaceScale);
    col = mix(col, vec3(1.0, 0.6, 1.4), edgeGlow);

    // Subtle motion blur with radial jitter
    float blur = 0.01 + 0.015 * sin(t * 0.9);
    vec2 px = blur / uResolution;
    vec2 offsetDir = vec2(sin(t * 0.7), cos(t * 0.8)) * 0.7;
    vec3 blurAccum = vec3(0.0);
    for (int i = -3; i <= 3; i++) {
        for (int j = -3; j <= 3; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = finalUV + offsetDir * (float(i) + float(j)) * 0.3 * blur;
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    col = mix(col, blurAccum / 49.0, 0.35);

    // Boost saturation and add a vibrant tone curve
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 3.5);
    col = pow(col, vec3(0.55));

    // Dynamic neon tint with phase shifting
    float pulse = 0.8 + 0.6 * sin(t * 2.1);
    col = mix(col, neonGlow(t * 1.4), pulse);

    // Chromatic aberration with swirling effect
    float aberration = 0.025 * sin(t * 3.2 + 6.0 * uv.x + 4.0 * uv.y);
    col.r = texture(uTexture, uv + vec2(aberration, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-aberration * 0.8, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, aberration * 0.6)).b;

    // Final enhancement: bright glow and chromatic bloom
    col = clamp(col, 0.0, 1.0);
    col = mix(col, vec3(1.2, 1.0, 1.5), 0.25);

    // Add dynamic neon halo around the face with radial pulses
    float halo = 0.4 * sin(t * 1.5) * (1.0 - smoothstep(0.0, 0.03, distToFace / uFaceScale));
    col = mix(col, neonGlow(t * 1.2), halo);

    // Add subtle flicker and grain for analog feel
    float noise = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
    float flicker = 0.03 * (noise - 0.5);
    col += vec3(flicker);

    // Final color grading: deep contrast, neon saturation boost
    col = pow(col, vec3(0.7));
    col = mix(col, vec3(1.0, 0.7, 1.2), 0.3 * (1.0 - mask));

    fragColor = vec4(col, 1.0);
}
