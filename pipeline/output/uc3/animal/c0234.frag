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

// Replace the center-pulling zoom with a radial stretch (animal morphing effect)
vec2 distortFace(vec2 uv) {
    vec2 d = uv - uFaceCenter;
    float r = length(d);
    float R = uFaceScale * 1.2;
    if (r > 0.0 && r < R) {
        float stretch = 1.0 + 0.5 * (1.0 - r / R) * (1.0 - r / R);
        d *= stretch;
        return uFaceCenter + d;
    }
    return uv;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 q = faceQ(uv);

    // Apply radial stretch distortion instead of center-pulling zoom
    vec2 src = distortFace(uv);
    vec3 col = texture(uTexture, clamp(src, 0.0, 1.0)).rgb;

    // Animal morphing: snout (elongated and sharper)
    float snout = ell(q, vec2(0.0, 0.05), vec2(0.35, 0.20));
    float snoutMask = 1.0 - smoothstep(0.4, 0.75, length((q - vec2(0.0, 0.05)) / vec2(0.35, 0.20)));
    col = mix(col, vec3(0.25, 0.18, 0.12), snoutMask * 0.6);

    // Fur texture with higher contrast and directional noise
    float fur = noise(vec2(q.x * 40.0, q.y * 100.0)) * 0.5 + noise(q * 160.0) * 0.5;
    col = mix(col, col * vec3(0.8, 0.6, 0.4) * (0.7 + 0.8 * fur), snout * 0.8);

    // Cat or snake eyes — enhanced with vertical slit and dynamic color
    float side = q.x < 0.0 ? -1.0 : 1.0;
    vec2 d = q - vec2(0.30 * side, -0.15);
    float eye = 1.0 - smoothstep(0.7, 1.0, length(d / vec2(0.12, 0.06)));
    float slit = 1.0 - smoothstep(0.01, 0.018, abs(d.x));
    vec3 eyeColor = mix(vec3(0.8, 0.7, 0.1), vec3(0.05, 0.15, 0.05), slit);
    col = mix(col, eyeColor, eye * 0.95);

    // Whiskers — more defined, thinner, and aligned with snout
    float wh = 0.0;
    for (int i = 0; i < 3; i++) {
        float y = 0.18 + float(i) * 0.04;
        float yy = y + (abs(q.x) - 0.10) * (float(i) - 1.0) * 0.2;
        wh = max(wh, (1.0 - smoothstep(0.002, 0.006, abs(q.y - yy))) * step(0.10, abs(q.x)) * step(abs(q.x), 0.60));
    }
    col = mix(col, vec3(0.0), wh * 0.9);

    // Animal ears — pointed and rotated slightly outward
    float earLeft = ell(q, vec2(-0.45, -0.35), vec2(0.20, 0.25));
    float earRight = ell(q, vec2(0.45, -0.35), vec2(0.20, 0.25));
    float ears = earLeft + earRight;
    col = mix(col, vec3(0.4, 0.3, 0.2), ears * 0.6);

    // Final face mask
    float face = ell(q, vec2(0.0, 0.0), vec2(0.75, 1.0));
    col = mix(col, vec3(0.05, 0.03, 0.02), ell(q, vec2(0.0, 0.14), vec2(0.08, 0.05)) * 0.6);

    // Transfer sock and nose detail with deeper shadows
    float sock = max(ell(q, vec2(-0.30, -0.15), vec2(0.15, 0.14)), ell(q, vec2(0.30, -0.15), vec2(0.15, 0.14)));
    float nose = ell(q, vec2(0.0, 0.12), vec2(0.06, 0.09));
    col = mix(col, vec3(0.01), max(sock, nose) * face);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
