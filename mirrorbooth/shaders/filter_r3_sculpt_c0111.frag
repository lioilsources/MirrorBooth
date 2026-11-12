#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

// face coordinates: eyes ~ (+-0.30, -0.15), nose ~ (0, 0.05), mouth ~ (0, 0.35)
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

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 q = faceQ(uv);

    // Apply subtle facial reshaping: slimmer cheeks, smaller nose, bigger eyes, fuller lips
    vec2 d = q - vec2(0.0, 0.05); // nose center
    float w = exp(-dot(d / vec2(0.16, 0.20), d / vec2(0.16, 0.20)));
    vec2 src = q - d * (-0.15 * w); // pull nose and surrounding area inward

    // Eye area: expand slightly for bigger eyes
    vec2 eyeOffset = vec2(0.0, -0.15);
    float eyeW = smoothstep(0.0, 0.05, length(q - eyeOffset));
    src += eyeOffset * (0.05 * eyeW);

    // Lip area: push upward for fuller lips
    vec2 lipOffset = vec2(0.0, 0.35);
    float lipW = smoothstep(0.0, 0.04, length(q - lipOffset));
    src += lipOffset * (0.03 * lipW);

    // Scale back to texture space
    src.x /= uResolution.x / uResolution.y;
    vec2 warpedUV = uFaceCenter + src * uFaceScale;

    // Gaussian windows for localized effect: confine warping to face
    float dx = uv.x - uFaceCenter.x;
    float dy = uv.y - uFaceCenter.y;
    float gy = exp(-(dy * dy) / (2.0 * uFaceScale * uFaceScale));
    float gx = exp(-(dx * dx * (uResolution.x / uResolution.y) * (uResolution.x / uResolution.y)) / (uFaceScale * uFaceScale));
    float warpFactor = 1.0 + 0.18 * gy * gx;
    vec2 wUV = clamp(vec2(uv.x * warpFactor, uv.y), 0.0, 1.0);

    // Light 3x3 bilateral smooth on warped sample (from Shader B)
    vec2 px = 1.5 / uResolution;
    vec3 center = texture(uTexture, wUV).rgb;
    vec3 accum = vec3(0.0);
    float wTotal = 0.0;
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec3 s = texture(uTexture, clamp(wUV + vec2(float(i), float(j)) * px, 0.0, 1.0)).rgb;
            float d = length(s - center);
            float w = exp(-d * d * 12.0);
            accum += s * w;
            wTotal += w;
        }
    }
    vec3 col = mix(center, accum / wTotal, 0.5);

    // Final color with subtle enhancement
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
