#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

// face coordinates: eyes ~ (+-0.30, -0.15), nose ~ (0, 0.05), mouth ~ (0, 0.35)
vec2 faceQ(vec2 uv) { vec2 q = (uv - uFaceCenter) / uFaceScale; q.x *= uResolution.x / uResolution.y; return q; }
float ell(vec2 q, vec2 c, vec2 r) { return 1.0 - smoothstep(0.6, 1.0, length((q - c) / r)); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y); }
float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

// One strong magnifying lens per ear at the sides of the head.
vec2 earLens(vec2 d, vec2 ear, float R) {
    vec2 k = d - ear;
    float sigma = 0.34 * R;
    float w = exp(-dot(k, k) / (sigma * sigma));
    return k * (1.0 - 0.45 * w) + ear - d;
}

// Apply jelly wobble from Shader A to the output of Shader B
vec2 jellyWobble(vec2 uv, vec2 center, float scale) {
    float aspect = uResolution.x / uResolution.y;
    vec2 d = (uv - center) * vec2(aspect, 1.0);
    float dist = length(d);
    float influence = exp(-dist * dist / (0.3 * scale * scale));
    float wobble = 0.15 * influence * sin(2.0 * 3.14159 * dist / (0.4 * scale));
    d.x += wobble * aspect;
    return center + d / vec2(aspect, 1.0);
}

// Transfer: Funhouse-style cubic warp from the other filter (applied before morphing)
vec2 funhouseWarp(vec2 uv, vec2 center, float scale) {
    vec2 d = (uv - center) / scale;
    d.x *= uResolution.x / uResolution.y;
    float r = length(d);
    float mask = exp(-r * r * 2.0);
    float wave = 0.5 * mask * (1.0 + cos(12.0 * d.x + 9.0 * d.y + 3.0 * scale));
    float stretch = 1.0 + wave * (1.0 + r * 0.8);
    d *= stretch;
    d.x /= uResolution.x / uResolution.y;
    return center + d * scale;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 q = faceQ(uv);

    // Apply funhouse warp (transferred from other filter) to the input
    vec2 src = funhouseWarp(uv, uFaceCenter, uFaceScale);
    vec3 col = texture(uTexture, clamp(src, 0.0, 1.0)).rgb;

    // Apply jelly wobble from Shader A to the input of Shader B
    vec2 wobbleUV = jellyWobble(uv, uFaceCenter, uFaceScale);
    col = mix(col, texture(uTexture, wobbleUV).rgb, 0.3);

    // Apply lens distortion from Shader A
    vec2 d = uv - uFaceCenter;
    d.x *= uResolution.x / uResolution.y;
    vec2 earL = vec2(-0.85 * uFaceScale, -0.02 * uFaceScale);
    vec2 earR = vec2(0.85 * uFaceScale, -0.02 * uFaceScale);
    vec2 distorted = d + earLens(d, earL, uFaceScale) + earLens(d, earR, uFaceScale);
    distorted.x /= uResolution.x / uResolution.y;
    vec2 wUV = clamp(uFaceCenter + distorted, 0.0, 1.0);
    col = mix(col, texture(uTexture, wUV).rgb, 0.3);

    // Animal morphing: snout
    float snout = ell(q, vec2(0.0, 0.05), vec2(0.45, 0.25));
    float snoutMask = 1.0 - smoothstep(0.5, 0.8, length((q - vec2(0.0, 0.05)) / vec2(0.45, 0.25)));
    col = mix(col, vec3(0.3, 0.2, 0.1), snoutMask * 0.5);

    // Fur texture
    float fur = noise(vec2(q.x * 30.0, q.y * 90.0)) * 0.6 + noise(q * 140.0) * 0.4;
    col = mix(col, col * vec3(0.85, 0.65, 0.45) * (0.7 + 0.6 * fur), snout * 0.7);

    // Cat or snake eyes — from Shader B
    float side = q.x < 0.0 ? -1.0 : 1.0;
    vec2 d_eye = q - vec2(0.30 * side, -0.15);
    float eye = 1.0 - smoothstep(0.8, 1.0, length(d_eye / vec2(0.12, 0.07)));
    float slit = 1.0 - smoothstep(0.012, 0.022, abs(d_eye.x));
    vec3 eyeColor = mix(vec3(0.75, 0.70, 0.10), vec3(0.02), slit);
    col = mix(col, eyeColor, eye * 0.9);

    // Whiskers — from Shader B
    float wh = 0.0;
    for (int i = 0; i < 3; i++) {
        float y = 0.20 + float(i) * 0.05;
        float yy = y + (abs(q.x) - 0.12) * (float(i) - 1.0) * 0.25;
        wh = max(wh, (1.0 - smoothstep(0.003, 0.008, abs(q.y - yy))) * step(0.12, abs(q.x)) * step(abs(q.x), 0.62));
    }
    col = mix(col, vec3(0.05), wh * 0.9);

    // Animal ears
    float earLeft = ell(q, vec2(-0.45, -0.40), vec2(0.25, 0.30));
    float earRight = ell(q, vec2(0.45, -0.40), vec2(0.25, 0.30));
    float ears = earLeft + earRight;
    col = mix(col, vec3(0.4, 0.3, 0.2), ears * 0.5);

    // Final face mask
    float face = ell(q, vec2(0.0, 0.0), vec2(0.70, 0.95));
    col = mix(col, vec3(0.08, 0.05, 0.05), ell(q, vec2(0.0, 0.14), vec2(0.09, 0.06)) * 0.6);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
