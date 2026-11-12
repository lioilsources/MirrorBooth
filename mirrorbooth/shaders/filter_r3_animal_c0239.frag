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

// Transfer the jelly wobble distortion from the other filter: gelatinous side wobble
vec2 jellyWobble(vec2 uv, vec2 center, float scale) {
    float aspect = uResolution.x / uResolution.y;
    vec2 d = (uv - center) * vec2(aspect, 1.0);

    // Define two wobble zones near the left and right sides of the face
    vec2 leftOffset = vec2(-0.6 * scale, 0.15 * scale);
    vec2 rightOffset = vec2(0.6 * scale, 0.15 * scale);

    float distLeft = length(d - leftOffset);
    float distRight = length(d - rightOffset);

    // Gaussian falloff for localized effect
    float influenceLeft = exp(-distLeft * distLeft / (0.3 * scale * scale));
    float influenceRight = exp(-distRight * distRight / (0.3 * scale * scale));

    // Sinusoidal wobble with time-independent frequency (no uTime used)
    float wobbleLeft = 0.15 * influenceLeft * sin(2.0 * 3.14159 * distLeft / (0.4 * scale));
    float wobbleRight = 0.15 * influenceRight * sin(2.0 * 3.14159 * distRight / (0.4 * scale));

    // Apply displacement: more horizontal, less vertical for a jelly-like wiggle
    d.x += (wobbleLeft + wobbleRight) * aspect;
    d.y += (wobbleLeft + wobbleRight) * 0.4;

    return center + d / vec2(aspect, 1.0);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 q = faceQ(uv);

    // Apply jelly wobble distortion from the other filter
    vec2 src = jellyWobble(uv, uFaceCenter, uFaceScale);
    vec3 col = texture(uTexture, clamp(src, 0.0, 1.0)).rgb;

    // Animal morphing: snout
    float snout = ell(q, vec2(0.0, 0.05), vec2(0.45, 0.25));
    float snoutMask = 1.0 - smoothstep(0.5, 0.8, length((q - vec2(0.0, 0.05)) / vec2(0.45, 0.25)));
    col = mix(col, vec3(0.3, 0.2, 0.1), snoutMask * 0.5);

    // Fur texture
    float fur = noise(vec2(q.x * 30.0, q.y * 90.0)) * 0.6 + noise(q * 140.0) * 0.4;
    col = mix(col, col * vec3(0.85, 0.65, 0.45) * (0.7 + 0.6 * fur), snout * 0.7);

    // Cat or snake eyes — from Shader B
    float side = q.x < 0.0 ? -1.0 : 1.0;
    vec2 d = q - vec2(0.30 * side, -0.15);
    float eye = 1.0 - smoothstep(0.8, 1.0, length(d / vec2(0.12, 0.07)));
    float slit = 1.0 - smoothstep(0.012, 0.022, abs(d.x));
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

    // Transfer the sock and nose detail from the other filter: subtle skin tone shift and darkened features
    float sock = max(ell(q, vec2(-0.30, -0.15), vec2(0.17, 0.15)), ell(q, vec2(0.30, -0.15), vec2(0.17, 0.15)));
    float nose = ell(q, vec2(0.0, 0.10), vec2(0.07, 0.10));
    col = mix(col, vec3(0.02), max(sock, nose) * face);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
