#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float aspect = uResolution.x / uResolution.y;

    // Eye band from the other filter: one horizontally stretched bulge above face center
    vec2 e = vec2(uFaceCenter.x, uFaceCenter.y - 0.35 * uFaceScale);
    vec2 d = uv - e;
    d.x *= aspect;

    vec2 k = d;
    k.x *= 0.6;
    float sigma = 0.35 * uFaceScale;
    float w = exp(-dot(k, k) / (sigma * sigma));

    // Apply warping effect to create subtle distortion near eyes (from other filter)
    vec2 src = d * (1.0 - 0.25 * w);
    src.x /= aspect;
    vec2 wUV = clamp(e + src, 0.0, 1.0);

    vec3 col = texture(uTexture, wUV).rgb;
    float c = luma(col);

    // Sketch and engraving effect: lines driven by brightness
    float edge = length(vec2(
        luma(texture(uTexture, uv - vec2(1.5 / uResolution.x, 0.0)).rgb) - luma(texture(uTexture, uv + vec2(1.5 / uResolution.x, 0.0)).rgb),
        luma(texture(uTexture, uv - vec2(0.0, 1.5 / uResolution.y)).rgb) - luma(texture(uTexture, uv + vec2(0.0, 1.5 / uResolution.y)).rgb)
    )) * 5.0;

    // Hatching lines using fract and sin for paper-like texture
    float hatching = smoothstep(0.35, 0.65, abs(fract((uv.x + uv.y) / 7.0) - 0.5) * 2.0);

    // Combine hatching with brightness and edge detection
    float shade = mix(1.0, hatching, step(c, 0.55) * 0.7) * (1.0 - edge);

    // Final color with sketch tone
    fragColor = vec4(mix(vec3(0.16), vec3(0.97), shade), 1.0);
}
