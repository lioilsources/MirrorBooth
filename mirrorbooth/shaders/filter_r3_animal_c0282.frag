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

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453),
                   fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453), f.x),
           mix(fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453),
                   fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453), f.x), f.y);
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

    vec3 col = texture(uTexture, uv).rgb;

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

    // Cat or snake eyes
    float side = q.x < 0.0 ? -1.0 : 1.0;
    vec2 d_eye = q - vec2(0.30 * side, -0.15);
    float eye = 1.0 - smoothstep(0.8, 1.0, length(d_eye / vec2(0.12, 0.07)));
    float slit = 1.0 - smoothstep(0.012, 0.022, abs(d_eye.x));
    vec3 eyeColor = mix(vec3(0.75, 0.70, 0.10), vec3(0.02), slit);
    col = mix(col, eyeColor, eye * 0.9);

    // Whiskers
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

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
