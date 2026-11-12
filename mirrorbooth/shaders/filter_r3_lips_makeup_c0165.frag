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

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float aspect = uResolution.x / uResolution.y;
    float R = uFaceScale;

    // Lips: glossy red lipstick with highlight
    vec2 mouthCenter = vec2(uFaceCenter.x, uFaceCenter.y + 0.42 * R);
    vec2 d = uv - mouthCenter;
    d.x *= aspect;
    vec2 k = d;
    k.x *= 0.65;
    float sigma = 0.22 * R;
    float lipMask = exp(-dot(k, k) / (sigma * sigma));
    vec2 highlightOffset = vec2(0.0, -0.03 * R);
    vec2 highlightPos = mouthCenter + highlightOffset;
    vec2 h = uv - highlightPos;
    h.x *= aspect;
    float gloss = exp(-dot(h, h) / (0.05 * R * 0.05 * R)) * 0.7;
    vec3 lipColor = mix(vec3(0.1, 0.0, 0.0), vec3(1.0, 0.0, 0.0), lipMask);
    lipColor += vec3(0.3, 0.0, 0.0) * gloss;
    lipColor = mix(lipColor, vec3(0.9, 0.2, 0.2), lipMask * 0.8);

    // Eyeliner and eyeshadow — dark, defined lines around eyes
    vec2 eyeCenterL = vec2(uFaceCenter.x - 0.3 * R, uFaceCenter.y - 0.1 * R);
    vec2 eyeCenterR = vec2(uFaceCenter.x + 0.3 * R, uFaceCenter.y - 0.1 * R);
    vec2 eL = uv - eyeCenterL;
    eL.x *= aspect;
    vec2 eR = uv - eyeCenterR;
    eR.x *= aspect;
    float leftEyeMask = exp(-dot(eL, eL) / (0.18 * R * 0.18 * R));
    float rightEyeMask = exp(-dot(eR, eR) / (0.18 * R * 0.18 * R));
    float eyeOutline = max(leftEyeMask, rightEyeMask);
    vec3 eyeColor = vec3(0.0, 0.0, 0.0) * eyeOutline * 0.9;

    // Transfer: Rosy blush on cheeks from other filter (using the scar/stripe noise pattern)
    vec2 q = faceQ(uv);
    vec2 a = vec2(0.15, -0.05);
    vec2 b = vec2(0.55, 0.35);
    vec2 ab = b - a;
    float t = clamp(dot(q - a, ab) / dot(ab, ab), 0.0, 1.0);
    vec2 p = a + ab * t;
    float dist = length(q - p);
    float wob = 0.008 * sin(t * 40.0);
    float scar = 1.0 - smoothstep(0.010, 0.022, abs(dist + wob));
    float rim = (1.0 - smoothstep(0.02, 0.06, dist)) * (1.0 - scar);
    vec3 blushColor = vec3(0.9, 0.4, 0.5) * rim * 0.6;
    vec3 baseColor = texture(uTexture, uv).rgb;
    baseColor = mix(baseColor, blushColor, scar * 0.7);

    // Blend lips, eyes, and blush
    baseColor = mix(baseColor, lipColor, lipMask * 0.9);
    baseColor = mix(baseColor, eyeColor, eyeOutline * 0.8);

    fragColor = vec4(clamp(baseColor, 0.0, 1.0), 1.0);
}
