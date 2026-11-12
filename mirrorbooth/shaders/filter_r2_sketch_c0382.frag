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
    vec2 d = 1.6 / uResolution;

    vec3 src = texture(uTexture, uv).rgb;
    float gray = luma(src);

    // Edge detection using smoothstep and step for engraving-like contrast
    float a = luma(texture(uTexture, uv - d).rgb);
    float b = luma(texture(uTexture, uv + d).rgb);
    float edge = smoothstep(0.06, 0.16, abs(a - b));
    edge = step(0.1, edge);

    // Hatching pattern using fract and sin for paper-like line texture
    float angle = sin(uv.x * 13.0 + uTime * 0.4) * 0.5 + 0.5;
    float hatch = fract(sin(dot(uv, vec2(15.9898, 72.233))) * 43758.5453 + uTime * 0.15);
    float line = step(angle, hatch);

    // Combine edge and hatching using mix and fract for organic sketch texture
    float lines = mix(edge, line, 0.6);
    lines = fract(lines * 1.5 + 0.05);

    // Apply tonal banding using floor and clamp for sketch paper layers
    float n = 6.0;
    float q = floor(clamp(gray, 0.0, 0.999) * n);
    vec3 col = vec3(0.12, 0.14, 0.31);
    if (q > 4.5) { col = vec3(0.97, 0.94, 0.83); }
    else if (q > 3.5) { col = vec3(0.96, 0.72, 0.32); }
    else if (q > 2.5) { col = vec3(0.88, 0.33, 0.31); }
    else if (q > 1.5) { col = vec3(0.38, 0.18, 0.43); }

    // Add subtle variation based on nearby luminance
    vec2 off = vec2(-4.0, -6.0) / uResolution;
    float ls = luma(texture(uTexture, uv + off).rgb);
    float qs = floor(clamp(ls, 0.0, 0.999) * n);
    col *= 1.0 - 0.25 * step(q + 0.5, qs);

    // Face-aware modulation using step and uFaceScale
    float faceMask = step(uFaceScale, length(uv - uFaceCenter));

    // Final color: mix sketch with luminance and apply paper texture
    vec3 sketch = mix(vec3(gray), col, 0.7 * faceMask * lines);
    sketch *= vec3(0.85, 0.8, 0.75);
    sketch = mix(vec3(0.15), vec3(0.94), fract(sketch.r * 0.9 + 0.1));

    fragColor = vec4(sketch, 1.0);
}
