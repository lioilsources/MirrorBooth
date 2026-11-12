#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 faceQ(vec2 uv) { vec2 q = (uv - uFaceCenter) / uFaceScale; q.x *= uResolution.x / uResolution.y; return q; }
float ell(vec2 q, vec2 c, vec2 r) { return 1.0 - smoothstep(0.6, 1.0, length((q - c) / r)); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y); }
float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 q = faceQ(uv);
    vec3 baseColor = texture(uTexture, uv).rgb;

    // Apply Shader B's core red lipstick and blush logic
    float lips = ell(q, vec2(0.0, 0.35), vec2(0.24, 0.10));
    float red = smoothstep(0.0, 0.12, baseColor.r - baseColor.g);
    vec3 tint = vec3(0.75, 0.05, 0.18) * (0.6 + lum(baseColor));
    baseColor = mix(baseColor, tint, lips * red * 0.75);
    baseColor += lips * red * pow(lum(baseColor), 3.0) * 0.6;

    float blush = ell(q, vec2(-0.40, 0.18), vec2(0.20, 0.13)) + ell(q, vec2(0.40, 0.18), vec2(0.20, 0.13));
    baseColor = mix(baseColor, baseColor * vec3(1.12, 0.88, 0.92), blush * 0.5);

    // Transfer: Apply Shader A's glossy lip distortion and warping technique to enhance realism
    vec2 d = q - vec2(0.0, 0.35);
    float w = exp(-dot(d / vec2(0.30, 0.18), d / vec2(0.30, 0.18)));
    vec2 src = q - d * 0.55 * w;
    src.x /= uResolution.x / uResolution.y;
    vec3 distortedLip = texture(uTexture, clamp(uFaceCenter + src * uFaceScale, 0.0, 1.0)).rgb;
    baseColor = mix(baseColor, distortedLip, smoothstep(0.0, 0.1, 0.35 - q.y) * 0.5);

    // Apply Shader A's glossy red lipstick with highlight
    vec2 mouthCenter = vec2(uFaceCenter.x, uFaceCenter.y + 0.42 * uFaceScale);
    vec2 dLip = uv - mouthCenter;
    dLip.x *= uResolution.x / uResolution.y;
    vec2 k = dLip;
    k.x *= 0.65;
    float sigma = 0.22 * uFaceScale;
    float lipMask = exp(-dot(k, k) / (sigma * sigma));
    vec2 highlightOffset = vec2(0.0, -0.03 * uFaceScale);
    vec2 highlightPos = mouthCenter + highlightOffset;
    vec2 h = uv - highlightPos;
    h.x *= uResolution.x / uResolution.y;
    float gloss = exp(-dot(h, h) / (0.05 * uFaceScale * 0.05 * uFaceScale)) * 0.7;
    vec3 lipColor = mix(vec3(0.1, 0.0, 0.0), vec3(1.0, 0.0, 0.0), lipMask);
    lipColor += vec3(0.3, 0.0, 0.0) * gloss;
    lipColor = mix(lipColor, vec3(0.9, 0.2, 0.2), lipMask * 0.8);
    baseColor = mix(baseColor, lipColor, lipMask * 0.9);

    // Apply Shader B's deeper eyeshadow with gradient (from Shader A)
    float eyeShadow = ell(q, vec2(-0.30, -0.15), vec2(0.25, 0.15)) * (1.0 - smoothstep(0.0, 0.03, abs(q.y + 0.15)));
    float shadowGradient = smoothstep(0.0, 0.05, abs(q.y + 0.15));
    baseColor = mix(baseColor, vec3(0.05, 0.05, 0.15), eyeShadow * 0.7 * shadowGradient);

    // Apply Shader A's dark eyeliner and eyeshadow with sharp definition
    vec2 eyeCenterL = vec2(uFaceCenter.x - 0.3 * uFaceScale, uFaceCenter.y - 0.1 * uFaceScale);
    vec2 eyeCenterR = vec2(uFaceCenter.x + 0.3 * uFaceScale, uFaceCenter.y - 0.1 * uFaceScale);
    vec2 eL = uv - eyeCenterL;
    eL.x *= uResolution.x / uResolution.y;
    vec2 eR = uv - eyeCenterR;
    eR.x *= uResolution.x / uResolution.y;
    float leftEyeMask = exp(-dot(eL, eL) / (0.18 * uFaceScale * 0.18 * uFaceScale));
    float rightEyeMask = exp(-dot(eR, eR) / (0.18 * uFaceScale * 0.18 * uFaceScale));
    float eyeOutline = max(leftEyeMask, rightEyeMask);
    vec3 eyeColor = vec3(0.0, 0.0, 0.0) * eyeOutline * 0.9;
    baseColor = mix(baseColor, eyeColor, eyeOutline * 0.8);

    // Final blend: Apply Shader A's glossy highlight with noise variation (from Shader B's concept)
    float lipGloss = ell(q, vec2(0.0, 0.35), vec2(0.15, 0.08)) * (1.0 - smoothstep(0.0, 0.05, abs(q.y - 0.35)));
    float noiseGloss = noise(q * 10.0 + uFaceCenter * 5.0) * 0.3;
    baseColor = mix(baseColor, vec3(1.0, 0.8, 0.8), (lipGloss + noiseGloss) * 0.7);

    // Apply Shader A's radial glow and distortion to enhance overall glossy effect
    float aspect = uResolution.x / uResolution.y;
    vec2 dDistort = uv - uFaceCenter;
    dDistort.x *= aspect;
    float r = length(dDistort);
    float R = uFaceScale * 1.2;
    vec2 wUV = uv;
    if (r < R && r > 0.0) {
        float glow = smoothstep(0.0, 0.1, R - r) * 0.3;
        vec2 dn = dDistort * pow(r / R, 0.65);
        dn = mix(dn, dDistort, smoothstep(0.9 * R, R, r));
        dn.x /= aspect;
        wUV = uFaceCenter + dn;
        baseColor = mix(baseColor, vec3(1.0, 0.9, 0.8), glow);
    }

    fragColor = vec4(clamp(baseColor, 0.0, 1.0), 1.0);
}
