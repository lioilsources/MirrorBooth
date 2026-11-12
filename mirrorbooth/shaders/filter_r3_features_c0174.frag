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
    vec3 col = texture(uTexture, uv).rgb;

    // Base distortion using face center and scale for overall feature amplification
    vec2 d = uv - uFaceCenter;
    d.x *= uResolution.x / uResolution.y;
    float r = length(d);
    float R = uFaceScale;

    vec2 wUV = uv;
    if (r < R && r > 0.0) {
        vec2 dn = d * pow(r / R, 0.55);
        dn = mix(dn, d, smoothstep(0.8 * R, R, r));
        dn.x /= uResolution.x / uResolution.y;
        wUV = clamp(uFaceCenter + dn, 0.0, 1.0);
    }

    // Feature exaggeration via distance-based influence from faceQ coordinates
    float lips = ell(q, vec2(0.0, 0.35), vec2(0.24, 0.10));
    float nose = ell(q, vec2(0.0, 0.05), vec2(0.15, 0.12));
    float eyes = ell(q, vec2(-0.30, -0.15), vec2(0.12, 0.10)) + ell(q, vec2(0.30, -0.15), vec2(0.12, 0.10));

    // Apply exaggerated stretch only to regions where features exist
    vec2 stretch = vec2(0.0);
    if (nose > 0.5) {
        stretch.y += 0.3 * nose * R;
        stretch.x += 0.2 * nose * R * (q.x > 0.0 ? 1.0 : -1.0);
    }
    if (lips > 0.5) {
        stretch.x += 0.4 * lips * R;
        stretch.y -= 0.1 * lips * R;
    }
    if (eyes > 0.5) {
        stretch.x += 0.2 * eyes * R * (q.x < 0.0 ? 1.0 : -1.0);
    }

    // Apply final distortion to UVs based on feature exaggeration
    vec2 d2 = (uv - uFaceCenter) * vec2(uResolution.x / uResolution.y, 1.0);
    d2 += stretch;
    vec2 finalUV = uFaceCenter + d2 / vec2(uResolution.x / uResolution.y, 1.0);
    finalUV = clamp(finalUV, 0.0, 1.0);

    // Sample both base and exaggerated areas
    vec3 baseCol = texture(uTexture, wUV).rgb;
    vec3 featureCol = texture(uTexture, finalUV).rgb;

    // Blend exaggerated features with base image
    float blendFactor = max(nose, max(lips, eyes));
    col = mix(baseCol, featureCol, blendFactor * 0.7);

    // Add color tint to lips with dynamic intensity
    float red = smoothstep(0.0, 0.12, col.r - col.g);
    vec3 tint = vec3(0.75, 0.05, 0.18) * (0.6 + lum(col));
    col = mix(col, tint, lips * red * 0.75);
    col += lips * red * pow(lum(col), 3.0) * 0.6;

    // Add subtle blush effect on cheeks using noise-based variation
    float blush = ell(q, vec2(-0.40, 0.18), vec2(0.20, 0.13)) + ell(q, vec2(0.40, 0.18), vec2(0.20, 0.13));
    float noiseBlush = noise(q * 5.0) * 0.2;
    col = mix(col, col * vec3(1.12, 0.88, 0.92), (blush + noiseBlush) * 0.5);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
