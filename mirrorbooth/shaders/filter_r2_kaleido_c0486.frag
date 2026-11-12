#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonPalette(float t) {
    vec3 a = vec3(0.0, 0.8, 1.0);
    vec3 b = vec3(1.0, 0.2, 1.0);
    vec3 c = vec3(1.0, 1.0, 0.5);
    vec3 d = vec3(0.3, 0.5, 1.0);
    return mix(
        mix(a, b, 0.5 + 0.5 * sin(t * 0.7)),
        mix(c, d, 0.5 + 0.5 * sin(t * 1.1)),
        0.5 + 0.5 * sin(t * 0.9)
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

float kaleidoTransform(vec2 uv, float n, float t, float radius, out vec2 outUV) {
    float angle = 2.0 * 3.14159 / n;
    float a = atan(uv.y, uv.x) + t * 0.9;
    float c = floor(a / angle);
    float d = mod(a, angle);
    float r = length(uv);
    float theta = d / angle;
    float k = (1.0 - theta) * 0.7 + theta * 0.3;

    float flow = 0.6 * sin(d * 10.0 + t * 1.8) * (1.0 - 0.3 * sin(r * 6.0 + t * 1.3));
    float wave = 0.5 * sin(r * 8.0 + t * 1.5) * (1.0 - 0.6 * sin(t * 1.0));
    float distortion = flow * (1.0 + wave);

    float newR = r * (1.0 - distortion * k);
    float newAngle = d + 0.6 * sin(t * 1.2 + d * 7.0);
    vec2 newUV = vec2(cos(newAngle), sin(newAngle)) * newR;

    outUV = newUV;
    return newR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;

    float t = uTime * 0.9;
    float symmetry = 16.0 + 12.0 * sin(t * 0.6);
    float radius = 0.4 + 0.25 * sin(t * 0.4);
    float mask = smoothstep(0.0, uFaceScale * 0.7, length(uv - center));

    vec2 centered = uv - center;
    float distToFace = length(centered);

    vec2 warpedUV;
    float newR = kaleidoTransform(centered, symmetry, t, radius, warpedUV);
    float scale = 1.0 + 1.4 * (1.0 - mask) * (1.0 + 0.8 * sin(t * 0.8));
    vec2 finalUV = center + (warpedUV * (newR / length(centered))) * scale;

    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    vec3 neon = neonPalette(t * 1.2);
    float l = dot(col, vec3(0.299, 0.587, 0.114));
    float glow = 1.0 - pow(distToFace / (uFaceScale * 1.2), 0.1);
    float glowIntensity = 1.0 * (1.0 - l) * glow * (0.5 + 0.5 * sin(t * 1.5));
    col = mix(col, neon, glowIntensity * 0.7);

    float bloom = 0.5 * (1.0 - distToFace / uFaceScale) * (1.0 - pow(distToFace / uFaceScale, 0.1));
    col += bloom * neon * 0.8;

    float ripple = 0.35 * sin(t * 6.0 + distToFace * 25.0 + 0.4 * sin(t * 0.6));
    float rippleStrength = 0.6 * step(0.35, distToFace / uFaceScale) * ripple;
    vec2 ripples = vec2(
        sin(t * 3.0 + distToFace * 18.0) * ripple,
        cos(t * 3.3 + distToFace * 18.0) * ripple
    );
    col = mix(col, neon, rippleStrength * 0.5);

    float glitch = 0.012 * sin(t * 4.8 + 10.0 * uv.x + 12.0 * uv.y + 1.5 * sin(t * 1.1));
    col.r = texture(uTexture, uv + vec2(glitch, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-glitch, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, glitch)).b;

    float tint = 0.6 + 0.4 * sin(t * 2.5 + 0.8 * distToFace / uFaceScale);
    col = mix(col, neon, 0.6 * tint * (1.0 - pow(distToFace / uFaceScale, 0.18)));

    float jitter = 0.006 * sin(t * 7.0 + uv.x * 18.0 + uv.y * 22.0);
    vec2 jitterUV = finalUV + vec2(jitter, jitter * 0.7);
    col = mix(col, texture(uTexture, clamp(jitterUV, 0.0, 1.0)).rgb, 0.2 * mask);

    vec2 vig = uv * 2.0 - 1.0;
    float vignette = pow(clamp(1.0 - dot(vig * 0.6, vig * 0.6), 0.0, 1.0), 0.8);
    col *= mix(0.8, 1.0, vignette);

    col = pow(col, vec3(0.6));
    col = mix(col, neon, 0.35 * (1.0 - pow(distToFace / uFaceScale, 0.2)));

    // Transfer: Add the seam effect from the other filter using abs and fract
    vec2 q = abs(uv - 0.5);
    float seam = min(q.x * uResolution.x, q.y * uResolution.y);
    float seamEffect = 0.8 + 0.2 * smoothstep(0.0, 3.0, seam);
    col *= seamEffect;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
