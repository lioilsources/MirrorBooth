#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonColor(float t, float offset) {
    float h = fract(t * 0.4 + offset);
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

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;
    float faceRadius = uFaceScale * 0.5;

    // Enhanced kaleidoscope: 8-fold symmetry with dynamic swirling and radial flow
    vec2 p = uv - center;
    float angle = atan(p.y, p.x);
    float r = length(p);
    float segments = 8.0;
    float snappedAngle = floor(angle * segments / 6.28318 + 0.5) * (6.28318 / segments);
    
    // Smooth time-based swirl with radial falloff
    float swirl = 0.15 * sin(uTime * 0.4 + r * 3.0) * (1.0 - r * 1.2);
    float distortedAngle = snappedAngle + swirl;
    vec2 distortedP = vec2(cos(distortedAngle), sin(distortedAngle)) * r;

    // Add flowing radial distortion with time and position modulation
    float flow = 0.03 * (1.0 + sin(uTime * 0.9 + r * 10.0)) * (1.0 + cos(uTime * 0.7 + r * 15.0));
    distortedP *= (1.0 + flow * r * 1.5);

    // Add secondary distortion for fluid motion
    float ripple = 0.01 * sin(uTime * 1.1 + r * 8.0 + distortedAngle * 4.0);
    distortedP += vec2(cos(distortedAngle + uTime * 0.5), sin(distortedAngle + uTime * 0.5)) * ripple;

    vec2 kaleidoUV = center + distortedP;

    // Smooth warp toward face center with dynamic falloff and pulsing
    float dx = uv.x - center.x;
    float dy = uv.y - center.y;
    float warp = 0.4 * (1.0 - exp(-0.4 * (dx * dx + dy * dy) / (faceRadius * faceRadius)));
    float pulseWarp = 0.5 + 0.5 * sin(uTime * 0.6 + r * 5.0);
    kaleidoUV = mix(uv, kaleidoUV, warp * pulseWarp);

    // Clamp to valid range
    kaleidoUV = clamp(kaleidoUV, 0.0, 1.0);

    // High-quality sampling with 4-tap antialiasing for smooth edges
    vec2 texel = 1.0 / uResolution;
    vec3 col = vec3(0.0);
    col += texture(uTexture, kaleidoUV + vec2(0.0, 0.0) * texel).rgb;
    col += texture(uTexture, kaleidoUV + vec2(1.0, 1.0) * texel).rgb;
    col += texture(uTexture, kaleidoUV + vec2(-1.0, 1.0) * texel).rgb;
    col += texture(uTexture, kaleidoUV + vec2(1.0, -1.0) * texel).rgb;
    col /= 4.0;

    // Neon color grading with layered pulsing and flowing hue
    float pulse = 0.6 + 0.4 * sin(uTime * 0.8);
    float hueOffset = uTime * 0.3;
    vec3 neon = neonColor(uTime * 0.4, hueOffset);
    vec3 neonBlend = mix(col, neon, 0.5 * pulse);

    // Add dynamic edge glow with radial falloff and time modulation
    float radialGlow = 1.0 - smoothstep(0.25, 0.7, r);
    float edgePulse = 0.5 + 0.5 * sin(uTime * 1.3 + r * 12.0);
    float glowStrength = radialGlow * edgePulse * 0.7;
    vec3 glow = neon * glowStrength;

    // Enhance luminance and add bloom-like glow with soft threshold
    float brightness = 0.7 + 0.3 * pow(length(col), 0.7);
    col = mix(col, vec3(1.0), 0.12 * (1.0 - brightness));

    // Final color with soft bloom, contrast boost, and glow bleed
    vec3 finalCol = col + glow;
    finalCol = pow(finalCol, vec3(0.75));
    finalCol = mix(finalCol, vec3(1.0), 0.1 * (1.0 - pow(length(finalCol), 2.0)));

    // Animated vignette with flowing edge
    vec2 vig = uv * 2.0 - 1.0;
    float vignette = pow(1.0 - dot(vig, vig) * 0.65, 1.3 + 0.15 * sin(uTime * 0.6));
    finalCol *= mix(0.92, 1.0, vignette);

    // Subtle color bleed for neon feel and chromatic shimmer
    float chroma = 0.15 * (1.0 - pow(length(finalCol), 1.6));
    finalCol = mix(finalCol, vec3(1.0), chroma);

    // Final output with slight chromatic aberration for extra neon flair
    vec3 rgb = finalCol;
    rgb.r = mix(rgb.r, texture(uTexture, kaleidoUV + vec2(0.005, 0.0)).r, 0.1);
    rgb.g = mix(rgb.g, texture(uTexture, kaleidoUV + vec2(-0.003, 0.003)).g, 0.1);
    rgb.b = mix(rgb.b, texture(uTexture, kaleidoUV + vec2(0.002, -0.004)).b, 0.1);

    fragColor = vec4(clamp(rgb, 0.0, 1.0), 1.0);
}
