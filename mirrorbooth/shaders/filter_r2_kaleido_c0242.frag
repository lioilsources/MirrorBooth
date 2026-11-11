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
    return smoothstep(0.2, 0.8, x);
}

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter * uFaceScale + (1.0 - uFaceScale) * 0.5;
    vec2 p = uv - center;
    float r = length(p);

    // Apply kaleidoscope folding: 8-fold symmetry using mod and atan
    float angle = atan(p.y, p.x);
    float n = 8.0;
    float foldedAngle = mod(angle + 3.14159, 6.28318 / n) - 3.14159 / n;
    vec2 distortedP = rotate(p, foldedAngle);

    // Radial distortion based on time and face scale for organic flow
    float distortStrength = 0.25 * sin(uTime * 0.7 + r * 4.0) * (1.0 - r * 0.3);
    float radialFactor = 1.0 + distortStrength * r * 2.0;
    distortedP *= radialFactor;

    // Final mirrored UV coordinates with center alignment
    vec2 mirroredUv = distortedP + center;

    // Sample original image with edge clamping
    vec3 color = texture(uTexture, clamp(mirroredUv, 0.0, 1.0)).rgb;

    // Apply dynamic palette with time-driven hue cycles using fract
    float t = uTime * 0.6;
    float hueCycle = fract(t * 0.4);
    float h6 = hueCycle * 6.0;
    float c = 1.0;
    float x = c * (1.0 - abs(mod(h6, 2.0) - 1.0));
    vec3 neon;
    if      (h6 < 1.0) neon = vec3(c, x, 0.0);
    else if (h6 < 2.0) neon = vec3(x, c, 0.0);
    else if (h6 < 3.0) neon = vec3(0.0, c, x);
    else if (h6 < 4.0) neon = vec3(0.0, x, c);
    else if (h6 < 5.0) neon = vec3(x, 0.0, c);
    else               neon = vec3(c, 0.0, x);

    // Dynamic glow intensity based on radial position and time
    float glowIntensity = (1.0 - r) * (0.5 + 0.3 * sin(uTime * 1.2 + r * 6.0));
    float edgeGlow = smoothEdge(r * 1.2) * (1.0 - smoothEdge(r * 0.8));
    float finalGlow = glowIntensity * edgeGlow;

    // Blend base color with neon glow using vibrant overlay
    vec3 finalColor = color * (1.0 + 0.5 * finalGlow) + neon * finalGlow * 2.0;

    // Add subtle chromatic bloom with radial falloff
    float bloom = 0.1 * (1.0 - r * 0.7) * (1.0 - r * 0.6);
    finalColor += vec3(bloom, 0.0, 0.0) * 0.4;
    finalColor += vec3(0.0, 0.0, bloom) * 0.4;

    // Vignette with soft radial fade and time-synced pulse
    float vignette = 1.0 - 2.0 * r * r;
    float pulseVignette = 0.15 * sin(uTime * 1.3 + r * 8.0);
    finalColor *= (vignette + pulseVignette * 0.25);

    // Final soft glow around the face center
    float centerGlow = 0.15 * smoothEdge(1.0 - r * 0.6) * (0.4 + 0.4 * sin(uTime * 0.6));
    finalColor += vec3(centerGlow, centerGlow * 0.3, centerGlow) * 0.3;

    // Transfer: Use luminance-based color grading from the other filter
    float l = luma(finalColor);
    l = smoothstep(0.05, 0.95, l);
    vec3 lo = vec3(0.1, 0.05, 0.38);
    vec3 mid = vec3(0.93, 0.18, 0.5);
    vec3 hi = vec3(1.0, 0.92, 0.45);
    finalColor = l < 0.5 ? mix(lo, mid, l * 2.0) : mix(mid, hi, l * 2.0 - 2.0 * 0.5);

    fragColor = vec4(clamp(finalColor, 0.0, 1.0), 1.0);
}
