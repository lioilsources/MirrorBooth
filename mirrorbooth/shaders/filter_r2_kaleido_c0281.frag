#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 colorShift(float t) {
    float h = fract(t * 0.25);
    float s = 0.8 + 0.2 * sin(h * 6.28318 + 1.0);
    float v = 0.8 + 0.2 * sin(h * 6.28318 + 2.0);
    float c = v * s;
    float x = c * (1.0 - abs(mod(h * 6.0, 2.0) - 1.0));
    float m = v - c;
    return vec3(
        (h < 1.0) ? c + m : (h < 2.0) ? x + m : m,
        (h < 1.0) ? x + m : (h < 2.0) ? c + m : m,
        (h < 1.0) ? m : (h < 2.0) ? m : (h < 3.0) ? c + m : (h < 4.0) ? x + m : m
    );
}

float rand(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 rotate(vec2 v, float a) {
    float s = sin(a), c = cos(a);
    return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

float smoothEdge(float x) {
    return smoothstep(0.2, 0.8, x);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;
    float t = uTime * 0.9;

    vec2 p = uv - center;
    float r = length(p);
    float angle = atan(p.y, p.x);
    float segments = 8.0;
    float snappedAngle = floor(angle * segments / 6.28318 + 0.5) * (6.28318 / segments);
    float distortedAngle = snappedAngle + 0.1 * sin(t * 0.3) * (1.0 - r * 1.5);
    vec2 distortedP = vec2(cos(distortedAngle), sin(distortedAngle)) * r;

    float distortion = 0.02 * (1.0 + sin(t * 0.8 + r * 8.0)) * (1.0 + cos(t * 0.6 + r * 12.0));
    distortedP *= (1.0 + distortion * r);

    vec2 kaleidoUV = center + distortedP;

    float dx = uv.x - center.x;
    float dy = uv.y - center.y;
    float warp = 0.3 * (1.0 - exp(-0.5 * (dx * dx + dy * dy) / (uFaceScale * uFaceScale * 0.25)));
    kaleidoUV = mix(uv, kaleidoUV, warp);

    kaleidoUV = clamp(kaleidoUV, 0.0, 1.0);

    vec3 col = texture(uTexture, kaleidoUV).rgb;

    float pulse = 0.5 + 0.5 * sin(t * 0.7);
    vec3 neon = colorShift(t);
    col = mix(col, neon, 0.4 * pulse);

    vec2 vig = uv * 2.0 - 1.0;
    float vignette = pow(1.0 - dot(vig, vig) * 0.7, 1.2 + 0.2 * sin(t * 0.5));
    col *= mix(0.9, 1.0, vignette);

    // Apply kaleidoscopic folding with polar angle repetition using mod and abs
    float a = atan(uv.y - center.y, uv.x - center.x);
    float wrappedAngle = mod(a, 6.28318 / 8.0);
    float sign = (a < 0.0) ? -1.0 : 1.0;
    float mirroredAngle = sign * (6.28318 / 8.0 - abs(wrappedAngle));
    float radialFactor = length(uv - center) / (uFaceScale * 0.6);
    vec2 mirroredUV = center + vec2(cos(mirroredAngle), sin(mirroredAngle)) * length(uv - center);

    vec3 finalCol = texture(uTexture, mirroredUV).rgb;
    finalCol = mix(col, finalCol, 0.6 * smoothEdge(radialFactor));

    // Add subtle jitter using fract and sin
    float jitter = 0.008 * sin(t * 7.0 + uv.x * 18.0 + uv.y * 22.0);
    vec2 jitterUV = uv + vec2(jitter, jitter * 0.7);
    finalCol = mix(finalCol, texture(uTexture, clamp(jitterUV, 0.0, 1.0)).rgb, 0.2);

    // Final tone: enhanced clarity and glow
    finalCol = pow(finalCol, vec3(0.6));
    finalCol = mix(finalCol, neon, 0.35 * (1.0 - pow(r / uFaceScale, 0.2)));

    fragColor = vec4(clamp(finalCol, 0.0, 1.0), 1.0);
}
