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
    return mix(
        mix(fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453),
            fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453), f.x),
        mix(fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453),
            fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453), f.x), f.y
    );
}

float lum(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 q = faceQ(uv);

    // Step 1: Apply non-linear distortion from Shader A (magnify around face center)
    vec2 d = q;
    float r = length(d);
    float R = 1.0;
    vec2 wQ = d;
    if (r < R && r > 0.0) {
        float scale = pow(r / R, 0.55);
        wQ = d * scale;
        wQ = mix(wQ, d, smoothstep(0.8 * R, R, r));
    }

    // Step 2: Apply feature exaggeration from Shader B (nose, mouth, eyes) using faceQ
    float mouth = ell(q, vec2(0.0, 0.35), vec2(0.30, 0.25));
    float eyes = ell(q, vec2(-0.30, -0.15), vec2(0.15, 0.15)) + ell(q, vec2(0.30, -0.15), vec2(0.15, 0.15));
    float nose = ell(q, vec2(0.0, 0.05), vec2(0.15, 0.25));

    // Step 3: Combine exaggeration with non-linear amplification
    float exaggeration = 1.0 + 2.0 * (mouth + eyes + nose) * (1.0 - exp(-r * 3.0));
    wQ *= exaggeration;

    // Step 4: Map back to texture coordinates with aspect correction
    wQ.x /= uResolution.x / uResolution.y;
    vec2 wUV = uFaceCenter + wQ * uFaceScale;
    wUV = clamp(wUV, 0.0, 1.0);

    // Step 5: Sample base image with exaggerated distortion
    vec3 baseCol = texture(uTexture, wUV).rgb;

    // Step 6: Apply additional feature-specific stretch based on exaggeration (from Shader B)
    vec2 stretch = vec2(0.0);
    if (nose > 0.5) {
        stretch.y += 0.3 * nose * uFaceScale;
        stretch.x += 0.2 * nose * uFaceScale * (q.x > 0.0 ? 1.0 : -1.0);
    }
    if (mouth > 0.5) {
        stretch.x += 0.4 * mouth * uFaceScale;
        stretch.y -= 0.1 * mouth * uFaceScale;
    }
    if (eyes > 0.5) {
        stretch.x += 0.2 * eyes * uFaceScale * (q.x < 0.0 ? 1.0 : -1.0);
    }

    // Step 7: Final UV adjustment with feature stretch
    vec2 d2 = (uv - uFaceCenter) * vec2(uResolution.x / uResolution.y, 1.0);
    d2 += stretch;
    vec2 finalUV = uFaceCenter + d2 / vec2(uResolution.x / uResolution.y, 1.0);
    finalUV = clamp(finalUV, 0.0, 1.0);

    // Step 8: Sample exaggerated features
    vec3 featureCol = texture(uTexture, finalUV).rgb;

    // Step 9: Blend base and exaggerated features
    float blendFactor = max(nose, max(mouth, eyes));
    vec3 col = mix(baseCol, featureCol, blendFactor * 0.7);

    // Step 10: Add dynamic color tint to lips
    float red = smoothstep(0.0, 0.12, col.r - col.g);
    vec3 tint = vec3(0.75, 0.05, 0.18) * (0.6 + lum(col));
    col = mix(col, tint, mouth * red * 0.75);
    col += mouth * red * pow(lum(col), 3.0) * 0.6;

    // Step 11: Add subtle blush with noise variation
    float blush = ell(q, vec2(-0.40, 0.18), vec2(0.20, 0.13)) + ell(q, vec2(0.40, 0.18), vec2(0.20, 0.13));
    float noiseBlush = noise(q * 5.0) * 0.2;
    col = mix(col, col * vec3(1.12, 0.88, 0.92), (blush + noiseBlush) * 0.5);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
