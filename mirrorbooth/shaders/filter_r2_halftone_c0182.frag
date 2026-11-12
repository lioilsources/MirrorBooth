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
    vec2 p = uv - 0.5;
    float s = max(max(abs(p.x), abs(p.y)) * 2.0, 0.0005);
    float t = fract(uTime * 0.25);
    float k = log2(1.0 / s) + t;
    float n = floor(k);
    float zoom = exp2(n - t);
    vec2 q = p * zoom;
    vec3 col = texture(uTexture, clamp(q + 0.5, 0.0, 1.0)).rgb;
    float e = max(abs(q.x), abs(q.y)) * 2.0;
    col *= 0.55 + 0.45 * smoothstep(1.0, 0.93, e);
    col *= 1.0 - 0.25 * smoothstep(0.62, 0.5, e);

    float brightness = luma(col);
    float px = floor(uResolution.x / 100.0);
    vec2 cell = floor(FlutterFragCoord().xy / px);
    vec2 f = fract(FlutterFragCoord().xy / px);

    float dither = fract(brightness * 2.0 + uTime * 0.02 + f.x * 0.7 + f.y * 0.3);
    float pattern = mod(cell.x * 0.7 + cell.y * 1.1, 2.0);
    float threshold = step(0.5, dither);
    float dot = step(0.4, brightness * (0.6 + 0.4 * pattern));
    float size = smoothstep(0.1, 0.9, fract(brightness * 3.0 + uTime * 0.01));
    vec3 baseColor = vec3(0.22, 0.14, 0.08);
    vec3 highlightColor = vec3(0.92, 0.86, 0.72);
    vec3 finalColor = mix(baseColor, highlightColor, dot * size);
    float softness = smoothstep(0.2, 0.8, fract(f.x * 0.5 + f.y * 0.8));
    finalColor = mix(finalColor, vec3(0.33, 0.25, 0.17), softness * 0.2);

    fragColor = vec4(finalColor, 1.0);
}
