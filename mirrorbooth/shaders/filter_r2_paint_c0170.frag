#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float hash21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
vec2 hash22(vec2 p) { float n = hash21(p); return vec2(n, hash21(p + n + 17.1)); }
float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 px = FlutterFragCoord().xy;
    vec2 cellp = floor(px / 12.0);
    vec2 wob = (hash22(cellp) - 0.5) * 0.006;
    vec2 fpx = fract(px / 12.0);
    vec2 wob2 = (hash22(cellp + vec2(0.0, 1.0)) - 0.5) * 0.006;
    vec2 w = mix(wob, wob2, smoothstep(0.0, 1.0, fpx.y));

    // Kuwahara filter: sample in 4 quadrants around the pixel
    vec3 sum = vec3(0.0);
    float count = 0.0;
    vec2 offset = vec2(3.0) / uResolution;

    // Quadrant 1: top-left
    vec3 q1 = texture(uTexture, uv - offset + w).rgb;
    sum += q1;
    count += 1.0;

    // Quadrant 2: top-right
    vec3 q2 = texture(uTexture, uv + vec2(offset.x, -offset.y) + w).rgb;
    sum += q2;
    count += 1.0;

    // Quadrant 3: bottom-left
    vec3 q3 = texture(uTexture, uv + vec2(-offset.x, offset.y) + w).rgb;
    sum += q3;
    count += 1.0;

    // Quadrant 4: bottom-right
    vec3 q4 = texture(uTexture, uv + offset + w).rgb;
    sum += q4;
    count += 1.0;

    vec3 avg = sum / count;

    // Apply watercolor bleed effect: blend with surrounding color based on edge strength
    vec3 src = texture(uTexture, uv + w).rgb;
    float edge = length(src - avg) * 8.0;
    float bleed = smoothstep(0.3, 0.7, edge);

    // Add paper texture and softening
    float paper = hash21(floor(px / 3.0));
    vec3 paperColor = vec3(0.97, 0.94, 0.91) * (0.9 + 0.1 * paper);
    vec3 final = mix(avg, src, 0.6);
    final = mix(final, paperColor, 0.2 * bleed);

    // Transfer: Add distortion and seam effect from other filter
    vec2 q = abs(uv - 0.5);
    vec2 suv = vec2(0.5 - q.x * 0.9, 0.62 - q.y * 1.1);
    vec3 col = texture(uTexture, clamp(suv, 0.0, 1.0)).rgb;
    float seam = min(q.x * uResolution.x, q.y * uResolution.y);
    col *= 0.8 + 0.2 * smoothstep(0.0, 3.0, seam);

    // Blend in the transferred distortion
    final = mix(final, col, 0.2);

    // Final tone and saturation
    final = 1.0 - (1.0 - final) * 0.9;
    final = mix(final, vec3(luma(final)), 0.1);

    fragColor = vec4(clamp(final, 0.0, 1.0), 1.0);
}
