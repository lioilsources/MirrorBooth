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

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter * uFaceScale + (1.0 - uFaceScale) * 0.5;
    vec2 p = uv - center;
    float r = length(p);

    // Apply kaleidoscope folding: 12-fold symmetry with dynamic angle snapping
    float angle = atan(p.y, p.x);
    float n = 12.0;
    float snappedAngle = floor(angle * n / 6.28318 + 0.5) * (6.28318 / n);
    vec2 distortedP = rotate(p, snappedAngle);

    // Radial distortion based on time and face scale for organic flow
    float distortStrength = 0.3 * sin(uTime * 0.6 + r * 5.0) * (1.0 - r * 0.4);
    float radialFactor = 1.0 + distortStrength * r * 2.5;
    distortedP *= radialFactor;

    // Final mirrored UV coordinates with center alignment
    vec2 mirroredUv = distortedP + center;

    // Sample original image with edge clamping
    vec3 color = texture(uTexture, clamp(mirroredUv, 0.0, 1.0)).rgb;

    // Apply dynamic neon palette with time-driven hue cycles
    float t = uTime * 0.8;
    float hueCycle = fract(t * 0.5);
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
    float glowIntensity = (1.0 - r) * (0.6 + 0.4 * sin(uTime * 1.4 + r * 8.0));
    float edgeGlow = smoothEdge(r * 1.3) * (1.0 - smoothEdge(r * 0.7));
    float finalGlow = glowIntensity * edgeGlow;

    // Blend base color with neon glow using vibrant overlay
    vec3 finalColor = color * (1.0 + 0.6 * finalGlow) + neon * finalGlow * 2.5;

    // Add subtle chromatic bloom with radial falloff
    float bloom = 0.15 * (1.0 - r * 0.8) * (1.0 - r * 0.5);
    finalColor += vec3(bloom, 0.0, 0.0) * 0.5;
    finalColor += vec3(0.0, 0.0, bloom) * 0.5;

    // Vignette with soft radial fade and time-synced pulse
    float vignette = 1.0 - 2.5 * r * r;
    float pulseVignette = 0.2 * sin(uTime * 1.5 + r * 10.0);
    finalColor *= (vignette + pulseVignette * 0.3);

    // Final soft glow around the face center
    float centerGlow = 0.2 * smoothEdge(1.0 - r * 0.7) * (0.5 + 0.5 * sin(uTime * 0.7));
    finalColor += vec3(centerGlow, centerGlow * 0.4, centerGlow) * 0.4;

    fragColor = vec4(clamp(finalColor, 0.0, 1.0), 1.0);
}
