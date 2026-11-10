#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return vec3(
        0.8 + 0.7 * sin(t * 2.3 + 0.2),
        0.2 + 0.8 * sin(t * 2.3 + 2.4),
        1.3 + 0.6 * sin(t * 2.3 + 4.7)
    ) * 2.5;
}

vec3 flowWaves(vec2 uv, float t) {
    float wave1 = sin(uv.x * 18.0 + t * 1.7) * 0.5 + 0.5;
    float wave2 = cos(uv.y * 16.0 + t * 1.5) * 0.5 + 0.5;
    float wave3 = sin(uv.x * 12.0 + uv.y * 10.0 + t * 1.3) * 0.5 + 0.5;
    return vec3(wave1, wave2, wave3) * 2.2;
}

float kaleidoTransform(vec2 uv, float n, float t, float radius, out vec2 outUV) {
    float angle = 2.0 * 3.14159 / n;
    float a = atan(uv.y, uv.x) + t * 0.8;
    float c = floor(a / angle);
    float d = mod(a, angle);
    float r = length(uv);
    float theta = d / angle;
    float k = (1.0 - theta) * 0.6 + theta * 0.4;

    float flow = 0.7 * sin(d * 12.0 + t * 2.0) * (1.0 - 0.4 * sin(r * 7.0 + t * 1.4));
    float wave = 0.4 * sin(r * 9.0 + t * 1.6) * (1.0 - 0.5 * sin(t * 1.1));
    float distortion = flow * (1.0 + wave);

    float newR = r * (1.0 - distortion * k);
    float newAngle = d + 0.7 * sin(t * 1.3 + d * 6.0);
    vec2 newUV = vec2(cos(newAngle), sin(newAngle)) * newR;

    outUV = newUV;
    return newR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;

    float t = uTime * 1.0;
    float symmetry = 12.0 + 10.0 * sin(t * 0.5);
    float radius = 0.3 + 0.2 * sin(t * 0.3);
    float mask = smoothstep(0.0, uFaceScale * 0.6, length(uv - center));

    vec2 centered = uv - center;
    float distToFace = length(centered);

    // Enhanced kaleidoscopic warping with flowing distortions
    vec2 warpedUV;
    float newR = kaleidoTransform(centered, symmetry, t, radius, warpedUV);
    float scale = 1.0 + 1.5 * (1.0 - mask) * (1.0 + 0.9 * sin(t * 0.9));
    vec2 finalUV = center + (warpedUV * (newR / length(centered))) * scale;

    // Sample warped texture
    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    // Add flowing neon waves across the whole frame
    vec3 wave = flowWaves(uv, t);
    col = mix(col, wave, 0.6 * mask);

    // Intense central neon pulse with radial expansion
    vec3 glow = neonGlow(t * 1.4);
    float pulseRadius = 0.35 + 0.3 * sin(t * 0.6);
    float pulseMask = smoothstep(pulseRadius, pulseRadius - 0.1, distToFace / uFaceScale);
    col = mix(col, glow, 1.0 * pulseMask);

    // Glowing halo around face with swirling motion
    float edgeGlow = 0.9 * (1.0 - mask) * smoothstep(0.0, 0.05, distToFace / uFaceScale);
    vec3 haloColor = vec3(1.0, 0.4, 1.8) * (1.0 + 0.5 * sin(t * 1.2));
    col = mix(col, haloColor, edgeGlow);

    // Swirling chromatic aberration with motion
    float aberration = 0.04 * sin(t * 3.5 + 10.0 * uv.x + 6.0 * uv.y + 2.0 * length(uv - center));
    col.r = texture(uTexture, uv + vec2(aberration, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-aberration * 0.6, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, aberration * 0.4)).b;

    // Motion blur with swirling diffusion and radial spread
    float blur = 0.015 + 0.025 * sin(t * 1.1);
    vec2 px = blur / uResolution;
    vec2 swirlDir = vec2(sin(t * 0.7), cos(t * 0.8)) * 0.5;
    vec3 blurAccum = vec3(0.0);
    for (int i = -3; i <= 3; i++) {
        for (int j = -3; j <= 3; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = finalUV + swirlDir * (float(i) + float(j)) * 0.3 * blur;
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    col = mix(col, blurAccum / 49.0, 0.35);

    // Boost saturation and apply glowing tone curve
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 4.5);
    col = pow(col, vec3(0.45));

    // Dynamic neon tint with phase shift and pulsing
    float pulse = 1.0 + 0.8 * sin(t * 2.4);
    col = mix(col, neonGlow(t * 1.6), pulse * 0.6);

    // Final bloom and glow enhancement
    col = clamp(col, 0.0, 1.0);
    col = mix(col, vec3(1.4, 1.2, 1.8), 0.3);

    fragColor = vec4(col, 1.0);
}
