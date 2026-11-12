#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 src = texture(uTexture, uv).rgb;
    float gray = luma(src);

    // Step 1: Apply Shader B's core technique — enhanced edge and hatching using fract and sin
    vec2 faceOffset = (uv - uFaceCenter) * uFaceScale;
    float edgeIntensity = step(0.3, length(faceOffset));

    float n = fract(dot(uv, vec2(123.34, 456.21)) + uTime * 47.0);
    float l = pow(gray, 0.65) * 1.35 + (n - 0.5) * 0.22;

    float angle = sin(uTime * 0.3) * 0.4 + 0.2;
    float hatching = sin(uv.x * 150.0 + uv.y * 120.0 + angle * 10.0);

    float line = abs(fract(hatching * 0.5 + l * 0.3) - 0.5) * 2.0;
    float w = 1.0 - l;
    float ink = mix(0.0, 1.0, smoothstep(w + 0.05, w - 0.05, line));

    vec3 baseColor = mix(vec3(0.95, 0.97, 0.9), vec3(0.1, 0.2, 0.15), ink);
    vec3 sketchBase = baseColor * l;

    // Step 2: Enhance with Shader A's edge detection using step and smoothstep
    vec2 d = 1.8 / uResolution;
    float a = luma(texture(uTexture, uv - d).rgb);
    float b = luma(texture(uTexture, uv + d).rgb);
    float edge = smoothstep(0.05, 0.15, abs(a - b));

    // Step 3: Combine with hatching pattern using fract and mix for paper-like texture
    float pattern = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
    float hatch = step(0.5, sin(uv.y * 15.0 + uTime * 0.5) * 0.5 + 0.5);
    float textureLayer = fract(edge + hatch * 0.7);

    // Step 4: Apply face mask with step to emphasize natural contours
    float faceMask = step(uFaceScale, length(uv - uFaceCenter));
    float finalLuma = mix(gray, textureLayer, 0.7 * faceMask);

    // Final output: blend sketchBase with texture layer using mix and fract for organic sketch
    vec3 finalSketch = mix(sketchBase, vec3(finalLuma), fract(finalLuma * 0.8 + 0.2));
    finalSketch = mix(vec3(0.16), finalSketch, fract(finalLuma * 0.8 + 0.2));

    fragColor = vec4(finalSketch, 1.0);
}
