#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

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
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float time = uTime * 0.25;

    // Kaleidoscope with 6-fold symmetry and flowing motion
    float angle = atan(p.y, p.x);
    float n = 6.0;
    float snappedAngle = floor(angle * n / 6.28318 + 0.5) * (6.28318 / n);
    
    // Dynamic swirl based on time and radial position
    float swirl = sin(time * 0.5) * 0.1 + cos(time * 0.3 + r * 3.0) * 0.05;
    float distortedAngle = snappedAngle + swirl;
    vec2 distortedP = rotate(p, distortedAngle);

    // Radial flow distortion: stronger near center, softer at edges
    float distortStrength = 0.4 * sin(time * 0.8 + r * 4.0) * (1.0 - r * 0.5);
    float radialFactor = 1.0 + distortStrength * r * 3.0;
    distortedP *= radialFactor;

    // Mirror coordinates with smooth blending across 6 sections
    vec2 mirroredUv = distortedP + center;

    // High-quality sampling with slight jitter for dynamic feel
    vec3 color = texture(uTexture, mirroredUv).rgb;

    // Neon color cycle: smooth hue transition with vibrant pulses
    float hueCycle = fract((angle / 6.28318 + time * 0.3) * 1.2);
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

    // Dynamic glow intensity: pulses with time and follows facial features
    float pulse = 0.5 + 0.5 * sin(time * 1.3 + r * 10.0);
    float glowIntensity = pulse * (1.0 - r * 0.7);

    // Edge glow with soft radial falloff and animated ripple
    float edgeGlow = smoothEdge(r * 1.5) * (1.0 - smoothEdge(r * 0.8));
    float ripple = 0.4 * sin(time * 1.2 + r * 12.0 + uv.x * 6.0 + uv.y * 4.0);
    float finalGlow = glowIntensity * edgeGlow * (1.0 + ripple * 0.6);

    // Blend neon glow with base image using vibrant overlay
    vec3 finalColor = color * (1.0 + 0.7 * finalGlow) + neon * finalGlow * 3.0;

    // Add chromatic bloom with color separation for neon depth
    float bloom = 0.2 * smoothEdge(r * 1.7) * (1.0 - r * 0.3);
    finalColor += vec3(bloom, 0.0, 0.0) * 0.6;
    finalColor += vec3(0.0, 0.0, bloom) * 0.6;

    // Vignette for focus and depth
    float vignette = 1.0 - 3.0 * r * r;
    finalColor *= vignette;

    // Final touch: subtle glow around face center (soft focus effect)
    float centerGlow = 0.3 * smoothEdge(1.0 - r * 0.6) * sin(time * 0.4 + r * 8.0);
    finalColor += vec3(centerGlow, centerGlow * 0.5, centerGlow) * 0.5;

    fragColor = vec4(clamp(finalColor, 0.0, 1.0), 1.0);
}
