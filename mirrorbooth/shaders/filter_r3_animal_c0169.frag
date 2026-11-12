#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 faceQ(vec2 uv) {
    vec2 q = (uv - uFaceCenter) / uFaceScale;
    q.x *= uResolution.x / uResolution.y;
    return q;
}

float ell(vec2 q, vec2 c, vec2 r) {
    return 1.0 - smoothstep(0.6, 1.0, length((q - c) / r));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

float lum(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

vec2 jellyWobble(vec2 uv, vec2 center, float scale) {
    float aspect = uResolution.x / uResolution.y;
    vec2 d = (uv - center) * vec2(aspect, 1.0);
    float dist = length(d);
    float influence = exp(-dist * dist / (0.3 * scale * scale));
    float wobble = 0.15 * influence * sin(2.0 * 3.14159 * dist / (0.4 * scale));
    d.x += wobble * aspect;
    return center + d / vec2(aspect, 1.0);
}

vec2 earLens(vec2 d, vec2 ear, float R) {
    vec2 k = d - ear;
    float sigma = 0.34 * R;
    float w = exp(-dot(k, k) / (sigma * sigma));
    return k * (1.0 - 0.45 * w) + ear - d;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 q = faceQ(uv);

    // Apply jelly wobble from Shader A to the input of Shader B
    vec2 src = jellyWobble(uv, uFaceCenter, uFaceScale);
    vec3 col = texture(uTexture, clamp(src, 0.0, 1.0)).rgb;

    // Apply lens distortion from Shader A to the output of Shader B
    vec2 d = uv - uFaceCenter;
    d.x *= uResolution.x / uResolution.y;
    vec2 earL = vec2(-0.85 * uFaceScale, -0.02 * uFaceScale);
    vec2 earR = vec2(0.85 * uFaceScale, -0.02 * uFaceScale);
    vec2 distorted = d + earLens(d, earL, uFaceScale) + earLens(d, earR, uFaceScale);
    distorted.x /= uResolution.x / uResolution.y;
    vec2 wUV = clamp(uFaceCenter + distorted, 0.0, 1.0);
    col = mix(col, texture(uTexture, wUV).rgb, 0.3);

    // Morph intensity based on face scale
    float morph = uFaceScale * 0.5;

    // Cat or snake eyes with dynamic shape (Shader A's logic, enhanced)
    float leftEye = 1.0 - smoothstep(0.8, 1.0, length(q - vec2(-0.30, -0.15) * 0.8));
    float rightEye = 1.0 - smoothstep(0.8, 1.0, length(q - vec2(0.30, -0.15) * 0.8));
    float catEye = (leftEye + rightEye) * 0.5;
    float snakeEye = (leftEye + rightEye) * 0.5 * (1.0 - 0.5 * (1.0 - abs(q.y + 0.15) / 0.2));
    float eye = mix(catEye, snakeEye, 0.5);

    // Dynamic eye color: green for cat, yellow for snake
    vec3 eyeColor = mix(vec3(0.0, 0.8, 0.0), vec3(0.9, 0.9, 0.0), 0.5);
    col = mix(col, eyeColor, eye * 0.9);

    // Snout: elongated nose with dynamic shape (Shader A's logic)
    float snout = 1.0 - smoothstep(0.4, 0.6, length(q - vec2(0.0, 0.12)));
    col = mix(col, vec3(0.85, 0.45, 0.55), snout * morph * 0.7);

    // Fur texture via noise (Shader A's logic, combined with Shader B's)
    float fur = noise(q * 15.0 + vec2(0.0, 1.0) * sin(uv.y * 2.0 + 1.0)) * 0.8;
    col = mix(col, vec3(0.5, 0.3, 0.2) * (0.8 + fur), morph * 0.5);

    // Whiskers: dynamic, directional lines (Shader A's logic)
    float whiskers = 0.0;
    for (int i = 0; i < 3; i++) {
        float y = 0.20 + float(i) * 0.05;
        float yy = y + (abs(q.x) - 0.12) * (float(i) - 1.0) * 0.25;
        whiskers = max(whiskers, (1.0 - smoothstep(0.003, 0.008, abs(q.y - yy))) * step(0.12, abs(q.x)) * step(abs(q.x), 0.62));
    }
    col = mix(col, vec3(0.05), whiskers * 0.9);

    // Animal ears: dynamic placement and size based on face scale (Shader A's logic)
    float ears = 0.0;
    for (int i = 0; i < 2; i++) {
        float s = float(i) * 2.0 - 1.0;
        vec2 earPos = vec2(s * 0.35, -0.25) * (1.0 + uFaceScale * 0.2);
        float earDist = length(q - earPos);
        float earShape = 1.0 - smoothstep(0.1, 0.15, earDist);
        ears += earShape * (0.3 + uFaceScale * 0.1);
    }
    col = mix(col, vec3(0.7, 0.5, 0.2), ears * 0.6);

    // Final blending with jelly-wobbled base (Shader B's morphing logic)
    float snoutMask = 1.0 - smoothstep(0.5, 0.8, length((q - vec2(0.0, 0.05)) / vec2(0.45, 0.25)));
    col = mix(col, vec3(0.3, 0.2, 0.1), snoutMask * 0.5);

    // Fur texture (Shader B's version)
    float furB = noise(vec2(q.x * 30.0, q.y * 90.0)) * 0.6 + noise(q * 140.0) * 0.4;
    col = mix(col, col * vec3(0.85, 0.65, 0.45) * (0.7 + 0.6 * furB), snout * 0.7);

    // Cat or snake eyes (Shader B's version)
    float eyeLeft = ell(q, vec2(-0.30, -0.15), vec2(0.10, 0.10));
    float eyeRight = ell(q, vec2(0.30, -0.15), vec2(0.10, 0.10));
    float eyes = eyeLeft + eyeRight;
    vec3 eyeColorB = vec3(0.0, 0.8, 0.0); // Cat green
    col = mix(col, eyeColorB, eyes * 0.6);

    // Whiskers (Shader B's version)
    float whiskersB = 0.0;
    whiskersB += ell(q, vec2(-0.15, 0.0), vec2(0.15, 0.01));
    whiskersB += ell(q, vec2(0.15, 0.0), vec2(0.15, 0.01));
    whiskersB += ell(q, vec2(-0.20, 0.05), vec2(0.10, 0.01));
    whiskersB += ell(q, vec2(0.20, 0.05), vec2(0.10, 0.01));
    col = mix(col, vec3(0.0, 0.0, 0.0), whiskersB * 0.8);

    // Animal ears (Shader B's version)
    float earLeft = ell(q, vec2(-0.45, -0.40), vec2(0.25, 0.30));
    float earRight = ell(q, vec2(0.45, -0.40), vec2(0.25, 0.30));
    float earsB = earLeft + earRight;
    col = mix(col, vec3(0.4, 0.3, 0.2), earsB * 0.5);

    // Final face mask (Shader B's version)
    float face = ell(q, vec2(0.0, 0.0), vec2(0.70, 0.95));
    col = mix(col, vec3(0.08, 0.05, 0.05), ell(q, vec2(0.0, 0.14), vec2(0.09, 0.06)) * 0.6);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
