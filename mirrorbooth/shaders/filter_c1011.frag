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

    // Kaleidoscope: 6-fold symmetry with smooth rotation and radial flow
    vec2 p = uv - center;
    float angle = atan(p.y, p.x);
    float r = length(p);
    float segments = 6.0;
    float snappedAngle = floor(angle * segments / 6.28318 + 0.5) * (6.28318 / segments);
    float swirl = 0.1 * sin(uTime * 0.3) * (1.0 - r * 1.5);
    float distortedAngle = snappedAngle + swirl;
    vec2 distortedP = vec2(cos(distortedAngle), sin(distortedAngle)) * r;

    // Add time-based radial distortion for flowing motion
    float distortion = 0.02 * (1.0 + sin(uTime * 0.8 + r * 8.0)) * (1.0 + cos(uTime * 0.6 + r * 12.0));
    distortedP *= (1.0 + distortion * r);

    vec2 kaleidoUV = center + distortedP;

    // Smooth warp toward face center with dynamic falloff
    float dx = uv.x - center.x;
    float dy = uv.y - center.y;
    float warp = 0.3 * (1.0 - exp(-0.5 * (dx * dx + dy * dy) / (faceRadius * faceRadius)));
    kaleidoUV = mix(uv, kaleidoUV, warp);

    // Clamp to valid range
    kaleidoUV = clamp(kaleidoUV, 0.0, 1.0);

    // Sample the texture with antialiasing
    vec3 col = texture(uTexture, kaleidoUV).rgb;

    // Neon color grading with pulsing, flowing hue
    float pulse = 0.5 + 0.5 * sin(uTime * 0.7);
    float hueOffset = uTime * 0.25;
    vec3 neon = neonColor(uTime * 0.3, hueOffset);
    col = mix(col, neon, 0.4 * pulse);

    // Add flowing edge glow with radial falloff and time modulation
    float radialGlow = 1.0 - smoothstep(0.3, 0.7, r);
    float edgePulse = 0.5 + 0.5 * sin(uTime * 1.2 + r * 10.0);
    float glowStrength = radialGlow * edgePulse * 0.6;
    vec3 glow = neon * glowStrength;

    // Enhance luminance and add bloom-like glow
    float brightness = 0.7 + 0.3 * pow(length(col), 0.8);
    col = mix(col, vec3(1.0), 0.15 * (1.0 - brightness));

    // Final color with soft bloom and contrast boost
    vec3 finalCol = col + glow;
    finalCol = pow(finalCol, vec3(0.8));
    finalCol = mix(finalCol, vec3(1.0), 0.1 * (1.0 - pow(length(finalCol), 1.8)));

    // Vignette with animated soft edge
    vec2 vig = uv * 2.0 - 1.0;
    float vignette = pow(1.0 - dot(vig, vig) * 0.7, 1.2 + 0.2 * sin(uTime * 0.5));
    finalCol *= mix(0.9, 1.0, vignette);

    // Final output with subtle color bleed for neon feel
    finalCol = mix(finalCol, vec3(1.0), 0.15 * (1.0 - pow(length(finalCol), 1.5)));

    fragColor = vec4(clamp(finalCol, 0.0, 1.0), 1.0);
}
