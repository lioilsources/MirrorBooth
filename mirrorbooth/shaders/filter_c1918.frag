#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return vec3(
        0.9 + 0.5 * sin(t * 1.7 + 0.1),
        0.3 + 0.6 * sin(t * 1.7 + 2.3),
        1.1 + 0.4 * sin(t * 1.7 + 4.6)
    ) * 2.8;
}

vec3 flowWaves(vec2 uv, float t) {
    float wave1 = sin(uv.x * 20.0 + t * 1.5) * 0.5 + 0.5;
    float wave2 = cos(uv.y * 18.0 + t * 1.3) * 0.5 + 0.5;
    float wave3 = sin(uv.x * 14.0 + uv.y * 12.0 + t * 1.1) * 0.5 + 0.5;
    return vec3(wave1, wave2, wave3) * 2.0;
}

float kaleidoTransform(vec2 uv, float n, float t, float radius, out vec2 outUV) {
    float angle = 2.0 * 3.14159 / n;
    float a = atan(uv.y, uv.x) + t * 0.7;
    float c = floor(a / angle);
    float d = mod(a, angle);
    float r = length(uv);
    float theta = d / angle;
    float k = (1.0 - theta) * 0.5 + theta * 0.5;

    float flow = 0.6 * sin(d * 9.0 + t * 1.6) * (1.0 - 0.5 * sin(r * 5.0 + t * 1.2));
    float wave = 0.3 * sin(r * 7.0 + t * 1.4) * (1.0 - 0.8 * sin(t * 0.8));
    float distortion = flow * (1.0 + wave);

    float newR = r * (1.0 - distortion * k);
    float newAngle = d + 0.4 * sin(t * 1.0 + d * 7.0);
    vec2 newUV = vec2(cos(newAngle), sin(newAngle)) * newR;

    outUV = newUV;
    return newR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;

    float t = uTime * 0.9;
    float symmetry = 8.0 + 12.0 * sin(t * 0.45);
    float radius = 0.3 + 0.2 * sin(t * 0.4);
    float mask = smoothstep(0.0, uFaceScale * 0.7, length(uv - center));

    vec2 centered = uv - center;
    float distToFace = length(centered);

    // Apply kaleidoscopic warping with strong motion and flow
    vec2 warpedUV;
    float newR = kaleidoTransform(centered, symmetry, t, radius, warpedUV);
    float scale = 1.0 + 1.3 * (1.0 - mask) * (1.0 + 0.8 * sin(t * 0.8));
    vec2 finalUV = center + (warpedUV * (newR / length(centered))) * scale;

    // Sample warped texture
    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    // Overlay flowing neon waves across the entire screen
    vec3 wave = flowWaves(uv, t);
    col = mix(col, wave, 0.5 * mask);

    // Intense pulsing neon glow from the center outward
    vec3 glow = neonGlow(t * 1.2);
    float pulse = 0.8 + 0.7 * sin(t * 2.0);
    col = mix(col, glow, pulse * (1.0 - mask) * 0.8);

    // Soft glowing edge around the face with swirling motion
    float edgeGlow = 0.6 * (1.0 - mask) * smoothstep(0.0, 0.07, distToFace / uFaceScale);
    float swirl = 0.4 * sin(t * 1.8 + 4.0 * uv.x + 3.0 * uv.y);
    col = mix(col, vec3(1.0, 0.5, 1.3) * (1.0 + swirl), edgeGlow);

    // Subtle motion blur with radial jitter and trail
    float blur = 0.01 + 0.012 * sin(t * 1.0);
    vec2 px = blur / uResolution;
    vec2 offsetDir = vec2(sin(t * 0.6), cos(t * 0.9)) * 0.6;
    vec3 blurAccum = vec3(0.0);
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = finalUV + offsetDir * (float(i) + float(j)) * 0.4 * blur;
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    col = mix(col, blurAccum / 25.0, 0.3);

    // Boost saturation and add vibrant tone curve
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 4.0);
    col = pow(col, vec3(0.5));

    // Dynamic neon tint with phase shifting and color swirl
    float phase = 0.7 + 0.5 * sin(t * 2.3);
    vec3 tint = neonGlow(t * 1.5);
    col = mix(col, tint, phase * 0.7);

    // Chromatic aberration with swirling, glowing trails
    float aberration = 0.03 * sin(t * 3.0 + 5.0 * uv.x + 4.0 * uv.y);
    col.r = texture(uTexture, uv + vec2(aberration, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-aberration * 0.7, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, aberration * 0.5)).b;

    // Final glow and bloom enhancement
    col = clamp(col, 0.0, 1.0);
    col = mix(col, vec3(1.3, 1.1, 1.6), 0.3);

    fragColor = vec4(col, 1.0);
}
