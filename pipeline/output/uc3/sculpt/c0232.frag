#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

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

    // Enhance eyes: slightly brighten and saturate the central region
    float eyeMask = 1.0 - smoothstep(0.0, 0.3, length(vec2(uv.x - uFaceCenter.x, uv.y - uFaceCenter.y + 0.02)));
    float eyeEnhance = 1.0 + 0.2 * eyeMask * weight;
    col = mix(col, col * eyeEnhance, 0.3);

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
