#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 distortedUV(vec2 uv, vec2 center, float scale) {
    float aspect = uResolution.x / uResolution.y;
    vec2 d = (uv - center) * vec2(aspect, 1.0);

    float r = length(d);
    vec2 w = d;

    if (r < scale && r > 0.0) {
        float ratio = r / scale;
        float factor = pow(ratio, 0.45);
        w *= (1.0 + 0.8 * factor);
    }

    return center + w / vec2(aspect, 1.0);
}

float ell(vec2 q, vec2 c, vec2 r) {
    return 1.0 - smoothstep(0.6, 1.0, length((q - c) / r));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 q = (uv - uFaceCenter) / uFaceScale;
    q.x *= uResolution.x / uResolution.y;

    // Non-linear magnification around face center
    float r = length(q);
    float R = 1.0;
    vec2 wQ = q;
    if (r < R && r > 0.0) {
        float scale = pow(r / R, 0.55);
        wQ = q * scale;
        wQ = mix(wQ, q, smoothstep(0.8 * R, R, r));
    }

    // Exaggerate features: mouth, eyes, nose
    float mouth = ell(wQ, vec2(0.0, 0.35), vec2(0.30, 0.25));
    float eyes = ell(wQ, vec2(-0.30, -0.15), vec2(0.15, 0.15)) + ell(wQ, vec2(0.30, -0.15), vec2(0.15, 0.15));
    float nose = ell(wQ, vec2(0.0, 0.05), vec2(0.15, 0.25));

    float exaggeration = 1.0 + 2.0 * (mouth + eyes + nose) * (1.0 - exp(-r * 3.0));
    wQ *= exaggeration;

    wQ.x /= uResolution.x / uResolution.y;
    vec2 wUV = uFaceCenter + wQ * uFaceScale;
    wUV = clamp(wUV, 0.0, 1.0);

    // Sample texture with exaggerated features
    vec3 col = texture(uTexture, wUV).rgb;

    // Skin tone correction and red tint
    float l = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(l), col, 0.35);
    col = pow(clamp(col, 0.0, 1.0), vec3(0.85)) * vec3(0.98, 0.97, 1.03);

    // Deep red-eye effect on mouth
    vec2 m = vec2(uFaceCenter.x, uFaceCenter.y + 0.42 * uFaceScale);
    vec2 dm = uv - m;
    dm.x *= uResolution.x / uResolution.y * 0.6;
    float sigma = 0.22 * uFaceScale;
    float w = exp(-dot(dm, dm) / (sigma * sigma));
    float dark = 0.35 + 0.65 * smoothstep(0.55, 0.15, l);
    col = mix(col, vec3(0.60, 0.05, 0.08), 0.9 * w * dark);

    // Vignette and contrast
    vec2 d_vig = uv - vec2(0.5);
    d_vig.x *= uResolution.x / uResolution.y;
    float vig = smoothstep(0.42, 0.9, length(d_vig));
    col = mix(col, vec3(0.08, 0.0, 0.02), vig);
    col = mix(vec3(0.5), col, 1.1);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
