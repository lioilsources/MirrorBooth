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

    // Step 1: Apply Shader B's hatching and ink modulation using fract, sin, and mix
    vec2 faceOffset = (uv - uFaceCenter) * uFaceScale;
    float edgeMask = step(0.3, length(faceOffset));

    float angle = sin(uTime * 0.3) * 0.4 + 0.2;
    float hatching = sin(uv.x * 150.0 + uv.y * 120.0 + angle * 10.0);
    float line = abs(fract(hatching * 0.5 + gray * 0.3) - 0.5) * 2.0;
    float w = 1.0 - gray;
    float ink = mix(0.0, 1.0, smoothstep(w + 0.05, w - 0.05, line));

    vec3 paperColor = vec3(0.95, 0.97, 0.9);
    vec3 inkColor = vec3(0.1, 0.2, 0.15);
    vec3 baseSketch = mix(paperColor, inkColor, ink);

    // Step 2: Enhance with Shader A's edge detection using step and smoothstep
    vec2 d = 1.8 / uResolution;
    float a = luma(texture(uTexture, uv - d).rgb);
    float b = luma(texture(uTexture, uv + d).rgb);
    float edge = smoothstep(0.05, 0.15, abs(a - b));

    // Step 3: Combine with fract-based line modulation and face-aware blending
    float pattern = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
    float lines = step(0.5, sin(uv.y * 15.0 + uTime * 0.5) * 0.5 + 0.5);
    float combinedLines = fract(edge + lines * 0.7);

    // Step 4: Tonal banding using floor and clamp (from Shader A) for sketch layers
    float n = 5.0;
    float q = floor(clamp(gray, 0.0, 0.999) * n);
    vec3 layerColor = vec3(0.13, 0.16, 0.33);
    if (q > 3.5) layerColor = vec3(0.99, 0.95, 0.85);
    else if (q > 2.5) layerColor = vec3(0.98, 0.75, 0.35);
    else if (q > 1.5) layerColor = vec3(0.9, 0.36, 0.33);
    else if (q > 0.5) layerColor = vec3(0.4, 0.2, 0.45);

    // Step 5: Apply subtle variation from nearby pixels (Shader A style)
    vec2 off = vec2(-5.0, -7.0) / uResolution;
    float ls = luma(texture(uTexture, uv + off).rgb);
    float qs = floor(clamp(ls, 0.0, 0.999) * n);
    layerColor *= 1.0 - 0.3 * step(q + 0.5, qs);

    // Step 6: Final mix using mix with combined lines and face mask
    vec3 final = mix(vec3(gray), layerColor, 0.7 * edgeMask * combinedLines);
    final *= vec3(0.8, 0.75, 0.7);

    // Final output: blend base sketch with enhanced tonal and line structure
    fragColor = vec4(mix(baseSketch, final, 0.6), 1.0);
}
