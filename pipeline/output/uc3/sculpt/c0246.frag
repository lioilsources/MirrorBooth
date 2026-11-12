#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

// Subtle facial retouch: slimmer cheeks, smaller nose, bigger eyes, fuller lips
// using a non-uniform warp field based on face geometry and scale
vec2 faceWarp(vec2 uv, vec2 center, float scale) {
    vec2 d = uv - center;
    float aspect = uResolution.x / uResolution.y;
    d.x *= aspect;

    // Define key facial landmarks relative to face scale
    vec2 cheekL = vec2(-0.40 * scale, -0.10 * scale);
    vec2 cheekR = vec2(0.40 * scale, -0.10 * scale);
    vec2 noseTip = vec2(0.0, 0.15 * scale);
    vec2 eyeL = vec2(-0.32 * scale, -0.30 * scale);
    vec2 eyeR = vec2(0.32 * scale, -0.30 * scale);
    vec2 lipCenter = vec2(0.0, 0.45 * scale);

    // Warp: pull cheeks inward, shrink nose, expand eyes, push lips outward
    vec2 warp = vec2(0.0);
    float distToCheekL = length(d - cheekL);
    float distToCheekR = length(d - cheekR);
    float distToNose = length(d - noseTip);
    float distToEyeL = length(d - eyeL);
    float distToEyeR = length(d - eyeR);
    float distToLip = length(d - lipCenter);

    warp += (d - cheekL) * (0.10 * scale / (1.0 + distToCheekL * 1.5));
    warp += (d - cheekR) * (0.10 * scale / (1.0 + distToCheekR * 1.5));
    warp += (d - noseTip) * (0.15 * scale / (1.0 + distToNose * 2.0));
    warp += (d - eyeL) * (0.25 * scale / (1.0 + distToEyeL * 1.0));
    warp += (d - eyeR) * (0.25 * scale / (1.0 + distToEyeR * 1.0));
    warp += (d - lipCenter) * (0.20 * scale / (1.0 + distToLip * 1.0));

    // Apply warp with smooth falloff
    float falloff = 1.0 - smoothstep(0.0, 1.0, length(d) / (1.5 * scale));
    warp *= falloff;

    d += warp;
    d.x /= aspect;

    return center + d;
}

// Transfer: Eye enhancement via localized warping (from other filter)
float eyeBandWarp(vec2 uv, vec2 center, float scale) {
    float aspect = uResolution.x / uResolution.y;
    vec2 e = vec2(center.x, center.y - 0.35 * scale);
    vec2 d = uv - e;
    d.x *= aspect;

    vec2 k = d;
    k.x *= 0.6;
    float sigma = 0.35 * scale;
    float w = exp(-dot(k, k) / (sigma * sigma));

    // Amplify eye area distortion slightly
    return 1.0 + 0.15 * w;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float R = uFaceScale;

    // Apply face-centered warping for facial reshaping
    vec2 warpedUV = faceWarp(uv, uFaceCenter, R);

    // Transfer: enhance eyes with localized warping (from other filter)
    float eyeWarpFactor = eyeBandWarp(uv, uFaceCenter, R);
    warpedUV += (uv - uFaceCenter) * (eyeWarpFactor - 1.0) * 0.1;

    // Clamp to valid texture range
    warpedUV = clamp(warpedUV, 0.0, 1.0);

    // Sample texture
    vec3 col = texture(uTexture, warpedUV).rgb;

    // Slight brightness boost for natural glow
    col = pow(col, vec3(0.97));

    // Final adjustment: mild desaturation with soft pink tint (from other filter)
    float l = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(l), col, 0.8) + vec3(0.04, 0.01, 0.03);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
