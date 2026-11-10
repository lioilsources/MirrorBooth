#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return vec3(
        0.8 + 0.6 * sin(t * 2.3 + 0.3),
        0.2 + 0.8 * sin(t * 2.3 + 2.6),
        1.2 + 0.7 * sin(t * 2.3 + 5.0)
    ) * 4.0;
}

vec3 flowField(vec2 uv, float t) {
    float wave1 = sin(uv.x * 20.0 + t * 1.9) * 0.5 + 0.5;
    float wave2 = cos(uv.y * 18.0 + t * 1.7) * 0.5 + 0.5;
    float wave3 = sin(uv.x * 14.0 + uv.y * 12.0 + t * 1.5) * 0.5 + 0.5;
    float wave4 = sin(uv.x * 16.0 + t * 1.3) * 0.5 + 0.5;
    float wave5 = sin(uv.x * 24.0 + uv.y * 10.0 + t * 2.0) * 0.5 + 0.5;
    return vec3(wave1, wave2, wave3) * (1.0 + wave4 * 0.7 + wave5 * 0.3) * 2.8;
}

float kaleidoscopeWarp(vec2 uv, float segments, float t, float radius, out vec2 outUV) {
    vec2 centered = uv - 0.5;
    float r = length(centered);
    float a = atan(centered.y, centered.x) + t * 0.9;
    float angle = 2.0 * 3.14159 / segments;
    float seg = floor(a / angle);
    float rem = mod(a, angle);
    
    // Dynamic segment shifting with flow
    float shift = 0.5 * sin(t * 1.8 + seg * 0.7);
    float newAngle = rem + (angle * (1.0 - (mod(seg + shift + 1.0, segments) / segments)));
    
    // Radial flow distortion with pulsing waves
    float flow = 0.5 * sin(rem * 10.0 + t * 2.5) * (1.0 - 0.4 * sin(r * 8.0 + t * 1.4));
    float wave = 0.5 * sin(r * 12.0 + t * 1.7) * (1.0 - 0.6 * sin(t * 1.2));
    float distortion = flow * (1.0 + wave);
    
    float newR = r * (1.0 - distortion * 0.4);
    vec2 newUV = vec2(cos(newAngle), sin(newAngle)) * newR;
    outUV = 0.5 + newUV;
    return newR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 faceCenter = uFaceCenter;
    float faceDist = length(uv - faceCenter);
    float faceMask = smoothstep(0.0, uFaceScale * 0.7, faceDist);

    // Dynamic kaleidoscopic symmetry with swirling motion
    float segments = 16.0 + 10.0 * sin(uTime * 0.6);
    float radius = 0.3 + 0.2 * sin(uTime * 0.4);
    vec2 warpedUV;
    float newR = kaleidoscopeWarp(uv, segments, uTime, radius, warpedUV);

    // Smooth flow field for motion across the screen
    vec2 flowOffset = vec2(
        sin(uTime * 1.1 + uv.y * 10.0) * 0.015,
        cos(uTime * 1.3 + uv.x * 10.0) * 0.015
    );
    vec2 finalUV = warpedUV + flowOffset;

    // Sample warped texture
    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    // Overlay flowing neon waves across entire frame
    vec3 wave = flowField(uv, uTime);
    col = mix(col, wave, 0.7 * (1.0 - faceMask));

    // Intense pulsing neon glow from center outward
    vec3 glow = neonGlow(uTime);
    col = mix(col, glow, 0.9 * (1.0 - faceMask));

    // Swirling edge glow with ripple and phase shift
    float edgeGlow = 0.8 * (1.0 - faceMask) * smoothstep(0.0, 0.07, faceDist / (uFaceScale * 0.6));
    float ripple = 0.5 * sin(faceDist * 8.0 + uTime * 2.1) * (1.0 - 0.8 * faceMask);
    col = mix(col, vec3(1.5, 0.7, 2.0), edgeGlow * (1.0 + ripple));

    // Motion blur with radial phase shifting and shimmer
    float blur = 0.012 + 0.018 * sin(uTime * 1.2);
    vec2 px = blur / uResolution;
    vec2 dir = vec2(sin(uTime * 0.6), cos(uTime * 0.8)) * 0.5;
    vec3 blurAccum = vec3(0.0);
    for (int i = -3; i <= 3; i++) {
        for (int j = -3; j <= 3; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = finalUV + dir * (float(i) + float(j)) * 0.3 * 0.1;
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    col = mix(col, blurAccum / 49.0, 0.4);

    // Extreme saturation boost and vibrant tone curve
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 5.0);
    col = pow(clamp(col, 0.0, 1.0), vec3(0.55));

    // Dynamic chromatic aberration with swirling dispersion
    float aberration = 0.028 * sin(uTime * 4.0 + 5.0 * uv.x + 3.0 * uv.y + 2.0 * uTime);
    col.r = texture(uTexture, uv + vec2(aberration, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-aberration * 0.7, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, aberration * 0.5)).b;

    // Final bloom and radiant glow enhancement
    col = clamp(col, 0.0, 1.0);
    col += 0.6 * vec3(1.6, 1.4, 2.2);

    fragColor = vec4(col, 1.0);
}
