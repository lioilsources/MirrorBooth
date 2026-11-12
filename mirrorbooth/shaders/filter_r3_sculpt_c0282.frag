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

    float dx = uv.x - uFaceCenter.x;
    float dy = uv.y - uFaceCenter.y;

    // Gaussian windows confine the effect to the face, preserving background
    float gy = exp(-(dy * dy) / (2.0 * uFaceScale * uFaceScale));
    float gx = exp(-(dx * dx * aspect * aspect) / (uFaceScale * uFaceScale));
    float weight = gy * gx;

    // Apply subtle facial reshaping: slimmer cheeks, smaller nose, bigger eyes, fuller lips
    // Use a radial warp based on face center and scale to gently reshape features
    float radial = length(vec2(dx, dy * aspect));
    float scale = 1.0 + 0.08 * weight * (1.0 - radial / (uFaceScale * 1.5)); // Slight inward pull near face center

    // Warp UVs only in the central face region to simulate subtle reshaping
    vec2 warpedUV = uFaceCenter + vec2(dx * scale, dy * scale);

    // Sample with warping, but keep edges sharp and natural
    vec2 wUV = clamp(warpedUV, 0.0, 1.0);

    // Apply a soft, localized color correction and detail enhancement for natural beauty
    vec3 col = texture(uTexture, wUV).rgb;

    // Enhance eyes: slightly brighten and saturate the central region (transferred from other filter)
    vec2 q = faceQ(uv);
    float side = q.x < 0.0 ? -1.0 : 1.0;
    vec2 c = vec2(0.30 * side, -0.20);
    float lid = ell(q, c, vec2(0.17, 0.08)) * smoothstep(-0.10, -0.20, q.y);
    col = mix(col, col * vec3(0.55, 0.35, 0.85), lid * 0.7);

    // Fuller lips: brighten and slightly expand the lower lip region
    float lipMask = smoothstep(0.1, 0.05, uv.y - uFaceCenter.y + 0.15);
    float lipBoost = 1.0 + 0.15 * lipMask * weight;
    col = mix(col, col * lipBoost, 0.2);

    // Subtly reduce cheek prominence: pull cheeks inward
    float cheekMask = 1.0 - smoothstep(0.0, 0.2, abs(uv.x - uFaceCenter.x));
    float cheekReduce = 1.0 - 0.1 * cheekMask * weight;
    col = mix(col, col * cheekReduce, 0.15);

    // Final color clamp and output
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
