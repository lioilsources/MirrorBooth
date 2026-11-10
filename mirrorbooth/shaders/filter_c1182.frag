#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return vec3(
        0.9 + 0.5 * sin(t * 1.8 + 0.2),
        0.7 + 0.5 * sin(t * 1.8 + 2.3),
        1.2 + 0.5 * sin(t * 1.8 + 4.5)
    ) * 2.2;
}

vec3 flowWave(vec2 uv, float t) {
    float f = sin(uv.x * 10.0 + t * 1.2) * sin(uv.y * 10.0 + t * 1.0);
    float s = sin(t * 0.7) * 0.3;
    return vec3(
        0.8 + 0.4 * f,
        0.6 + 0.4 * f,
        1.0 + 0.6 * f
    ) * (1.0 + 0.5 * sin(t * 1.5));
}

float kaleidoscopeWarp(vec2 uv, float segments, float t, float radius, out vec2 outUV) {
    vec2 centered = uv - 0.5;
    float r = length(centered);
    float a = atan(centered.y, centered.x) + t * 0.7;
    float angle = 2.0 * 3.14159 / segments;
    float seg = floor(a / angle);
    float rem = mod(a, angle);
    float newAngle = rem + (angle * (1.0 - (mod(seg + 1.0, segments) / segments)));
    float distortion = 0.4 * sin(rem * 10.0 + t * 2.0) * (1.0 - 0.6 * sin(r * 8.0 + t * 1.3));
    float newR = r * (1.0 - distortion * 0.3);
    vec2 newUV = vec2(cos(newAngle), sin(newAngle)) * newR;
    outUV = 0.5 + newUV;
    return newR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 faceCenter = uFaceCenter;
    float faceDist = length(uv - faceCenter);
    float faceMask = smoothstep(0.0, uFaceScale * 0.5, faceDist);

    // Dynamic kaleidoscopic symmetry and warping
    float segments = 12.0 + 6.0 * sin(uTime * 0.4);
    float radius = 0.25 + 0.1 * sin(uTime * 0.2);
    vec2 warpedUV;
    float newR = kaleidoscopeWarp(uv, segments, uTime, radius, warpedUV);

    // Flowing motion distortion
    vec2 flowOffset = vec2(
        sin(uTime * 0.9 + uv.y * 5.0) * 0.01,
        cos(uTime * 1.1 + uv.x * 5.0) * 0.01
    );
    vec2 finalUV = warpedUV + flowOffset;

    // Sample texture with warping
    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    // Add flowing neon wave overlay
    vec3 wave = flowWave(uv, uTime);
    col = mix(col, wave, 0.6 * (1.0 - faceMask));

    // Intense neon glow around face and edges
    vec3 glow = neonGlow(uTime);
    col = mix(col, glow, 0.7 * (1.0 - faceMask));

    // Dynamic edge glow with ripple
    float edgeGlow = 0.6 * (1.0 - faceMask) * smoothstep(0.0, 0.1, faceDist / (uFaceScale * 0.8));
    float ripple = 0.5 * sin(faceDist * 6.0 + uTime * 1.8) * (1.0 - 0.7 * faceMask);
    col = mix(col, vec3(1.4, 0.7, 1.8), edgeGlow * (1.0 + ripple));

    // Subtle motion blur with jitter
    float blur = 0.012 + 0.008 * sin(uTime * 1.3);
    vec2 px = blur / uResolution;
    vec2 jitter = vec2(sin(uTime * 0.6), cos(uTime * 0.5)) * 0.3;
    vec3 blurAccum = vec3(0.0);
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = finalUV + jitter * (float(i) + float(j)) * 0.5 * 0.1;
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    col = mix(col, blurAccum / 9.0, 0.25);

    // Enhanced saturation and contrast
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 4.0);
    col = pow(col, vec3(0.65));

    // Chromatic aberration with flowing tint
    float aberration = 0.015 * sin(uTime * 2.5 + 2.0 * uv.x + 3.0 * uv.y);
    col.r = texture(uTexture, uv + vec2(aberration, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-aberration, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, aberration)).b;

    // Final color boost and bloom
    col = clamp(col, 0.0, 1.0);
    col = mix(col, vec3(1.2, 1.0, 1.6), 0.3);

    fragColor = vec4(col, 1.0);
}
