#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

// Helper: transform UV to face space
vec2 faceQ(vec2 uv) {
    vec2 q = (uv - uFaceCenter) / uFaceScale;
    q.x *= uResolution.x / uResolution.y;
    return q;
}

// Soft circular mask with smooth falloff
float ell(vec2 q, vec2 c, vec2 r) {
    return 1.0 - smoothstep(0.6, 1.0, length((q - c) / r));
}

// Noise for subtle texture variation
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

// Luminance for color balance
float lum(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 q = faceQ(uv);

    // Base image
    vec3 baseColor = texture(uTexture, uv).rgb;

    // === Lip Makeup (Glossy Red with Highlight) ===
    // Apply Shader A's lip logic with Shader B's gloss effect
    float lips = ell(q, vec2(0.0, 0.42), vec2(0.24, 0.12));
    float red = smoothstep(0.0, 0.12, baseColor.r - baseColor.g);
    vec3 lipTint = vec3(0.75, 0.05, 0.18) * (0.6 + lum(baseColor));
    vec3 lipBase = mix(baseColor, lipTint, lips * red * 0.75);
    lipBase += lips * red * pow(lum(baseColor), 3.0) * 0.6;

    // Gloss highlight
    vec2 highlightPos = vec2(uFaceCenter.x, uFaceCenter.y + 0.42 * uFaceScale - 0.03 * uFaceScale);
    vec2 h = uv - highlightPos;
    h.x *= uResolution.x / uResolution.y;
    float gloss = exp(-dot(h, h) / (0.05 * uFaceScale * 0.05 * uFaceScale)) * 0.7;
    vec3 glossColor = vec3(0.9, 0.2, 0.2) * 0.8;
    lipBase = mix(lipBase, glossColor, gloss * lips * 0.8);

    // Blend lips into base
    baseColor = mix(baseColor, lipBase, lips * 0.9);

    // === Rosy Blush on Cheeks (Shader B's logic) ===
    vec2 leftCheek = vec2(uFaceCenter.x - 0.35 * uFaceScale, uFaceCenter.y + 0.10 * uFaceScale);
    vec2 rightCheek = vec2(uFaceCenter.x + 0.35 * uFaceScale, uFaceCenter.y + 0.10 * uFaceScale);
    vec2 c = uv - leftCheek;
    c.x *= uResolution.x / uResolution.y;
    float leftBlush = exp(-dot(c, c) / (0.25 * uFaceScale * 0.25 * uFaceScale));
    c = uv - rightCheek;
    c.x *= uResolution.x / uResolution.y;
    float rightBlush = exp(-dot(c, c) / (0.25 * uFaceScale * 0.25 * uFaceScale));
    float blushMask = max(leftBlush, rightBlush);
    vec3 blushColor = vec3(0.9, 0.7, 0.8) * blushMask * 0.8;
    baseColor = mix(baseColor, blushColor, blushMask * 0.7);

    // === Dark Eyeliner & Eyeshadow (Shader B's logic) ===
    vec2 eyeCenterL = vec2(uFaceCenter.x - 0.30 * uFaceScale, uFaceCenter.y - 0.10 * uFaceScale);
    vec2 eyeCenterR = vec2(uFaceCenter.x + 0.30 * uFaceScale, uFaceCenter.y - 0.10 * uFaceScale);
    vec2 eL = uv - eyeCenterL;
    eL.x *= uResolution.x / uResolution.y;
    vec2 eR = uv - eyeCenterR;
    eR.x *= uResolution.x / uResolution.y;
    float leftEyeMask = exp(-dot(eL, eL) / (0.18 * uFaceScale * 0.18 * uFaceScale));
    float rightEyeMask = exp(-dot(eR, eR) / (0.18 * uFaceScale * 0.18 * uFaceScale));
    float eyeOutline = max(leftEyeMask, rightEyeMask);
    vec3 eyeColor = vec3(0.0, 0.0, 0.0) * eyeOutline * 0.9;
    baseColor = mix(baseColor, eyeColor, eyeOutline * 0.8);

    fragColor = vec4(clamp(baseColor, 0.0, 1.0), 1.0);
}
