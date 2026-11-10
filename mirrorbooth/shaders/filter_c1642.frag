#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 rotate(vec2 v, float a) {
    float s = sin(a), c = cos(a);
    return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

float smoothEdge(float x) {
    return smoothstep(0.1, 0.9, x);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;
    float scale = uFaceScale;

    // 8-fold kaleidoscope symmetry for dynamic, flowing mirror effect
    float angle = atan(uv.y - center.y, uv.x - center.x);
    float octAngle = floor(angle / (3.14159265 / 4.0) + 4.0) * (3.14159265 / 4.0);
    float r = length(uv - center);
    vec2 reflected = center + vec2(cos(octAngle), sin(octAngle)) * r;

    // Organic swirl with time-driven fluid motion and radial depth
    float distToFace = length(uv - center);
    float swirlStrength = sin(uTime * 4.0 + distToFace * 12.0) * 0.25;
    float swirlAngle = swirlStrength * (1.0 - distToFace * 0.6);
    vec2 swirlOffset = vec2(
        -sin(swirlAngle) * r,
        cos(swirlAngle) * r
    );
    vec2 swirlUV = center + swirlOffset;

    // Face-aware warping with soft falloff and dynamic focus
    float faceMask = exp(-pow(distToFace / scale, 2.0) * 10.0);
    vec2 warpUV = mix(uv, swirlUV, faceMask * 0.95);

    // Base color from warped UV
    vec3 col = texture(uTexture, warpUV).rgb;

    // Neon pulse: vibrant, flowing waves in electric cyan, magenta, and violet
    float pulse = 0.5 + 0.5 * sin(uTime * 3.6 + r * 12.0);
    float wave1 = sin(uTime * 3.4 + uv.x * 24.0 + uv.y * 20.0);
    float wave2 = sin(uTime * 3.1 - uv.x * 20.0 + uv.y * 24.0);
    float wave3 = sin(uTime * 2.9 + uv.x * 18.0 - uv.y * 22.0);
    vec3 neon = vec3(
        1.0 + 0.9 * wave1,
        0.6 + 0.8 * wave2,
        1.5 + 1.0 * wave3
    );
    col = mix(col, neon, pulse * 0.9);

    // Chromatic ripple with dynamic color shift and flowing motion
    float chromaOffset = sin(uTime * 1.6 + uv.x * 14.0 + uv.y * 13.0) * 0.012;
    vec3 shifted = vec3(
        texture(uTexture, warpUV + vec2(chromaOffset, 0.0)).r,
        texture(uTexture, warpUV + vec2(0.0, -chromaOffset)).g,
        texture(uTexture, warpUV + vec2(-chromaOffset, 0.0)).b
    );
    col = mix(col, shifted, 0.45);

    // Dynamic glowing halo with animated diffusion and motion blur
    vec2 px = 1.0 / uResolution;
    vec3 glow = vec3(0.0);
    float blurFactor = 1.2 + 0.4 * sin(uTime * 1.7);
    for (int i = -5; i <= 5; i++) {
        for (int j = -5; j <= 5; j++) {
            vec2 offset = vec2(float(i), float(j)) * px * blurFactor;
            float weight = 1.0 - 0.1 * (abs(float(i)) + abs(float(j)));
            glow += texture(uTexture, warpUV + offset).rgb * weight;
        }
    }
    glow /= 121.0;

    // Motion-glow intensity modulated by time, distance, and pulse
    float motionGlow = sin(uTime * 3.4 + distToFace * 16.0) * 0.5 + 0.5;
    float radialGlow = smoothEdge(r * 1.8);
    float finalGlow = motionGlow * radialGlow * pulse;
    col = mix(col, glow, 0.9 * finalGlow);

    // Final color grading: enhanced neon punch, cinematic glow, and subtle warmth
    col *= vec3(1.7, 1.5, 2.3);
    col = clamp(col, 0.0, 1.0);

    // Soft vignette with luminance-based glow and dynamic depth
    float vignette = 1.0 - 2.0 * r * r;
    col *= mix(0.9, 1.1, smoothstep(0.0, 0.5, r));

    // Subtle edge glow on high-contrast areas with synced motion
    vec2 dxy = vec2(1.0, 0.0) * px;
    float edge = abs(texture(uTexture, warpUV).r - texture(uTexture, warpUV + dxy).r);
    edge += abs(texture(uTexture, warpUV).g - texture(uTexture, warpUV + dxy).g);
    edge += abs(texture(uTexture, warpUV).b - texture(uTexture, warpUV + dxy).b);
    float edgeIntensity = 0.9 + 0.5 * sin(uTime * 3.7);
    col += vec3(0.5, 0.8, 1.4) * edge * 0.5 * edgeIntensity;

    // Final animated radial flare with pulse sync and glow
    float flare = 1.0 + 0.4 * sin(uTime * 2.5 + r * 7.0);
    col += vec3(0.3, 0.6, 1.2) * flare * smoothEdge(r * 0.6);

    fragColor = vec4(col, 1.0);
}
