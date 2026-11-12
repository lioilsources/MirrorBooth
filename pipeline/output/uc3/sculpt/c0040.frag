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
    float distToCheekL = length(d - cheekL);
    float distToCheekR = length(d - cheekR);
    float distToNose = length(d - noseTip);
    float distToEyeL = length(d - eyeL);
    float distToEyeR = length(d - eyeR);
    float distToLip = length(d - lipCenter);

    // Slim cheeks: pull inward based on distance
    vec2 warp = vec2(0.0);
    warp += (d - cheekL) * (0.10 * scale / (1.0 + distToCheekL * 1.5));
    warp += (d - cheekR) * (0.10 * scale / (1.0 + distToCheekR * 1.5));

    // Shrink nose: pull toward center
    warp += (d - noseTip) * (0.15 * scale / (1.0 + distToNose * 2.0));

    // Enlarge eyes: push outward with a gentle gradient
    warp += (d - eyeL) * (0.25 * scale / (1.0 + distToEyeL * 1.0));
    warp += (d - eyeR) * (0.25 * scale / (1.0 + distToEyeR * 1.0));

    // Fuller lips: push upward from center
    warp += (d - lipCenter) * (0.20 * scale / (1.0 + distToLip * 1.0));

    // Apply warp with smooth falloff
    float falloff = 1.0 - smoothstep(0.0, 1.0, length(d) / (1.5 * scale));
    warp *= falloff;

    // Re-scale x to account for aspect
    d += warp;
    d.x /= aspect;

    return center + d;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float R = uFaceScale;

    // Apply face-centered warping
    vec2 warpedUV = faceWarp(uv, uFaceCenter, R);

    // Clamp to valid texture range
    warpedUV = clamp(warpedUV, 0.0, 1.0);

    // Sample texture
    vec3 col = texture(uTexture, warpedUV).rgb;

    // Slight brightness boost for natural glow
    col = pow(col, vec3(0.97));

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
