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

// Chibi eye lens effect: subtle magnifying lens on each eye
vec2 eyeLens(vec2 d, vec2 eye, float R) {
    vec2 k = d - eye;
    float sigma = 0.26 * R;
    float w = exp(-dot(k, k) / (sigma * sigma));
    return k * (1.0 - 0.20 * w) + eye - d;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float aspect = uResolution.x / uResolution.y;
    float R = uFaceScale;

    vec2 d = uv - uFaceCenter;
    d.x *= aspect;

    vec2 eyeL = vec2(-0.32 * R, -0.30 * R);
    vec2 eyeR = vec2(0.32 * R, -0.30 * R);

    // Apply eye lens distortion to the original uv
    vec2 src = d + eyeLens(d, eyeL, R) + eyeLens(d, eyeR, R);
    src.x /= aspect;
    vec2 wUV = clamp(uFaceCenter + src, 0.0, 1.0);

    // Sample the distorted texture
    vec3 c0 = texture(uTexture, wUV).rgb;

    // Soft blur and glow for skin
    vec2 px = 4.0 / uResolution;
    vec3 acc = vec3(0.0);
    float wsum = 0.0;
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec3 s = texture(uTexture, uv + vec2(float(i), float(j)) * px).rgb;
            float w = exp(-dot(s - c0, s - c0) * 40.0);
            acc += s * w;
            wsum += w;
        }
    }
    vec3 blurred = acc / wsum;

    // Face mask: define facial regions with soft edges
    vec2 q = faceQ(uv);
    float face = ell(q, vec2(0.0, 0.05), vec2(0.62, 0.85)) * (1.0 - ell(q, vec2(0.0, 0.35), vec2(0.22, 0.09)));
    float glow = face * 0.7;

    // Apply smooth glowing skin and soft beauty filter
    vec3 col = mix(c0, blurred, face * 0.85);
    col = mix(col, col * vec3(1.04, 1.0, 0.97), face * 0.5);

    // Add subtle glow effect
    vec3 glowColor = vec3(1.0, 0.95, 0.85);
    col += glow * glowColor * 0.2;

    // Light freckles via noise-based texture
    vec2 freckleUV = uv * 20.0;
    float freckle = smoothstep(0.92, 0.98, noise(freckleUV));
    col = mix(col, vec3(0.95, 0.75, 0.65), freckle * 0.1);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
