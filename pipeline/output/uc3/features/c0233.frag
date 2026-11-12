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
    vec2 q = (uv - uFaceCenter) / uFaceScale;
    q.x *= uResolution.x / uResolution.y;

    // Apply non-linear magnification from Shader B around face center
    vec2 d = q;
    float r = length(d);
    float R = 1.0;

    vec2 wQ = d;
    if (r < R && r > 0.0) {
        float scale = pow(r / R, 0.55);
        wQ = d * scale;
        wQ = mix(wQ, d, smoothstep(0.8 * R, R, r));
    }

    // Exaggerate facial features using Shader A's logic: mouth, eyes, nose
    float mouth = ell(wQ, vec2(0.0, 0.35), vec2(0.30, 0.25));
    float eyes = ell(wQ, vec2(-0.30, -0.15), vec2(0.15, 0.15)) + ell(wQ, vec2(0.30, -0.15), vec2(0.15, 0.15));
    float nose = ell(wQ, vec2(0.0, 0.05), vec2(0.15, 0.25));

    float exaggeration = 1.0 + 2.0 * (mouth + eyes + nose) * (1.0 - exp(-r * 3.0));
    wQ *= exaggeration;

    // Map back to texture coordinates
    wQ.x /= uResolution.x / uResolution.y;
    vec2 wUV = uFaceCenter + wQ * uFaceScale;
    wUV = clamp(wUV, 0.0, 1.0);

    // Sample base texture with exaggerated features
    vec3 col = texture(uTexture, wUV).rgb;

    // Apply skin tone correction and red tint from Shader B
    float l = lum(col);
    col = mix(vec3(l), col, 0.35);
    col = pow(clamp(col, 0.0, 1.0), vec3(0.85)) * vec3(0.98, 0.97, 1.03);

    // Add deep red tint to mouth region
    vec2 m = vec2(uFaceCenter.x, uFaceCenter.y + 0.42 * uFaceScale);
    vec2 dm = uv - m;
    dm.x *= uResolution.x / uResolution.y * 0.6;
    float sigma = 0.22 * uFaceScale;
    float w = exp(-dot(dm, dm) / (sigma * sigma));
    float dark = 0.35 + 0.65 * smoothstep(0.55, 0.15, l);
    col = mix(col, vec3(0.60, 0.05, 0.08), 0.9 * w * dark);

    // Add deep vignette and contrast lift
    vec2 d_vig = uv - vec2(0.5);
    d_vig.x *= uResolution.x / uResolution.y;
    float vig = smoothstep(0.42, 0.9, length(d_vig));
    col = mix(col, vec3(0.08, 0.0, 0.02), vig);
    col = mix(vec3(0.5), col, 1.1);

    // Apply jellywobble distortion to eyes and nose (Shader A technique)
    vec2 e1 = vec2(uFaceCenter.x - 0.15 * uFaceScale, uFaceCenter.y - 0.1 * uFaceScale);
    vec2 e2 = vec2(uFaceCenter.x + 0.15 * uFaceScale, uFaceCenter.y - 0.1 * uFaceScale);
    vec2 d1 = uv - e1;
    vec2 d2 = uv - e2;
    d1.x *= uResolution.x / uResolution.y;
    d2.x *= uResolution.x / uResolution.y;

    float dist1 = length(d1);
    float dist2 = length(d2);
    float influence1 = exp(-dist1 * dist1 / (0.1 * uFaceScale * uFaceScale));
    float influence2 = exp(-dist2 * dist2 / (0.1 * uFaceScale * uFaceScale));

    float wobble1 = 0.1 * influence1 * sin(2.0 * 3.14159 * dist1 / (0.2 * uFaceScale));
    float wobble2 = 0.1 * influence2 * sin(2.0 * 3.14159 * dist2 / (0.2 * uFaceScale));

    vec2 eyeUV1 = e1 + (d1 + vec2(wobble1 * uResolution.x / uResolution.y, wobble1 * 0.4)) / vec2(uResolution.x / uResolution.y, 1.0);
    vec2 eyeUV2 = e2 + (d2 + vec2(wobble2 * uResolution.x / uResolution.y, wobble2 * 0.4)) / vec2(uResolution.x / uResolution.y, 1.0);

    vec3 eyeCol1 = texture(uTexture, eyeUV1).rgb;
    vec3 eyeCol2 = texture(uTexture, eyeUV2).rgb;

    col = mix(col, eyeCol1, influence1 * 0.5);
    col = mix(col, eyeCol2, influence2 * 0.5);

    // Final step: apply the core distortion from Shader A to magnify features toward face center
    vec2 d_center = uv - uFaceCenter;
    d_center.x *= uResolution.x / uResolution.y;
    float r_center = length(d_center);

    vec2 wUV_final = uv;
    if (r_center < uFaceScale && r_center > 0.0) {
        vec2 dn = d_center * pow(r_center / uFaceScale, 0.55);
        dn = mix(dn, d_center, smoothstep(0.8 * uFaceScale, uFaceScale, r_center));
        dn.x /= uResolution.x / uResolution.y;
        wUV_final = clamp(uFaceCenter + dn, 0.0, 1.0);
    }

    // Final color with exaggerated features and distortion
    vec3 finalCol = texture(uTexture, wUV_final).rgb;
    col = mix(col, finalCol, 0.7);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
