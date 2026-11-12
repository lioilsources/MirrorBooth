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

// Chibi: each eye gets its own gentle magnifying lens (unlike doll's single
// band), keeping the effect subtle — pretty, not grotesque.
vec2 eyeLens(vec2 d, vec2 eye, float R) {
    vec2 k = d - eye;
    float sigma = 0.26 * R;
    float w = exp(-dot(k, k) / (sigma * sigma));
    // Sampling closer to the eye center magnifies it.
    return k * (1.0 - 0.20 * w) + eye - d;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float aspect = uResolution.x / uResolution.y;
    float R = uFaceScale;

    vec2 d = uv - uFaceCenter;
    d.x *= aspect;

    // Apply subtle facial reshaping based on faceQ for natural retouch
    vec2 q = faceQ(uv);

    // Slimmer cheeks: compress horizontally near cheeks (x ~ ±0.4)
    float cheekComp = ell(q, vec2(-0.4, 0.0), vec2(0.1, 0.2));
    float cheekComp2 = ell(q, vec2(0.4, 0.0), vec2(0.1, 0.2));
    d.x *= (1.0 - 0.05 * (cheekComp + cheekComp2));

    // Smaller nose: pull nose tip (0, 0.05) inward slightly
    float nosePull = ell(q, vec2(0.0, 0.05), vec2(0.1, 0.1));
    d.y += 0.03 * nosePull * R;

    // Fuller lips: push mouth area (0, 0.35) outward
    float mouthPush = ell(q, vec2(0.0, 0.35), vec2(0.15, 0.1));
    d.y -= 0.04 * mouthPush * R;

    // Bigger eyes: use magnifying lens effect from Chibi filter, but more refined
    vec2 eyeL = vec2(-0.32 * R, -0.30 * R);
    vec2 eyeR = vec2(0.32 * R, -0.30 * R);
    d += eyeLens(d, eyeL, R) + eyeLens(d, eyeR, R);

    // Final warped UV
    vec2 src = d;
    src.x /= aspect;
    vec2 wUV = clamp(uFaceCenter + src, 0.0, 1.0);

    vec3 col = texture(uTexture, wUV).rgb;

    // Add subtle brightness boost for natural glow
    col = pow(clamp(col, 0.0, 1.0), vec3(0.95));

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
