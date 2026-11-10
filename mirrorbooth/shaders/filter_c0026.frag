#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

float rand(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 neonColor(float t) {
    vec3 c = vec3(
        0.5 + 0.5 * sin(t * 0.5 + 0.0),
        0.5 + 0.5 * sin(t * 0.5 + 2.0),
        0.5 + 0.5 * sin(t * 0.5 + 4.0)
    );
    return c * (0.8 + 0.2 * sin(t * 2.0));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // Kaleidoscope effect: mirror across 8 axes around center
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float angle = atan(p.y, p.x);
    float radius = length(p);
    float segments = 8.0;
    float newAngle = mod(angle * segments, 6.2831853) / segments;
    vec2 newP = vec2(cos(newAngle), sin(newAngle)) * radius;
    vec2 kaleidoUV = newP + center;

    // Smoothly animated distortion using time and noise
    float noise = rand(uv * 10.0 + uTime * 0.5);
    float distortion = 0.01 * (0.5 + 0.5 * sin(uTime * 1.5 + noise * 3.14159));
    vec2 distortedUV = kaleidoUV + vec2(
        sin(uTime * 1.0 + noise * 10.0) * distortion,
        cos(uTime * 1.2 + noise * 12.0) * distortion
    );

    // Sample with distortion and clamp
    vec3 col = texture(uTexture, clamp(distortedUV, 0.0, 1.0)).rgb;

    // Apply neon glow: enhance midtones, saturate, add glow
    float l = lum(col);
    vec3 glow = neonColor(uTime * 0.7);
    vec3 neon = mix(col, glow, 0.4 * (l * 1.5 - 0.5));
    neon = mix(col, neon, 0.8);

    // Dynamic color shift based on time and position
    float pulse = 0.7 + 0.3 * sin(uTime * 1.8);
    vec3 shift = vec3(
        0.5 + 0.5 * sin(uTime * 0.8 + uv.x * 4.0),
        0.5 + 0.5 * sin(uTime * 0.9 + uv.y * 5.0),
        0.5 + 0.5 * sin(uTime * 1.0 + (uv.x + uv.y) * 3.0)
    );
    neon = mix(neon, shift, 0.2 * pulse);

    // Smooth flowing motion: radial ripple effect
    float r = length(uv - center);
    float ripple = 0.02 * sin(uTime * 2.0 - r * 10.0 + noise * 5.0);
    neon += vec3(ripple);

    // Add subtle edge glow
    float edge = 1.0 - smoothstep(0.0, 0.05, min(uv.x, min(uv.y, min(1.0 - uv.x, 1.0 - uv.y))));
    neon += glow * edge * 0.5;

    // Final output with clean edge
    fragColor = vec4(clamp(neon, 0.0, 1.0), 1.0);
}
