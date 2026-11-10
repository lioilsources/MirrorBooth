#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

float rand(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 neonPalette(float t) {
    vec3 a = vec3(0.1, 0.0, 0.8); // deep blue
    vec3 b = vec3(1.0, 0.0, 1.0); // magenta
    vec3 c = vec3(1.0, 0.8, 0.0); // neon orange
    vec3 d = vec3(0.0, 1.0, 1.0); // cyan
    return mix(mix(a, b, 0.5 + 0.5 * sin(t * 0.6)), mix(c, d, 0.5 + 0.5 * sin(t * 1.2)), 0.5 + 0.5 * sin(t * 0.8));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float radius = length(p);

    // Kaleidoscope: 6-fold symmetry with smooth blending
    float angle = atan(p.y, p.x);
    float segments = 6.0;
    float slice = floor(angle / (2.0 * 3.14159) * segments + 0.5) / segments;
    angle = slice * (2.0 * 3.14159 / segments);
    vec2 mirrored = vec2(cos(angle), sin(angle)) * radius;
    vec2 kaleidoUV = mirrored + center;

    // Flowing distortion: time-based wave motion with radial control
    float timeWarp = 0.08 * sin(uTime * 1.4 + radius * 12.0);
    float wave = 0.5 + 0.5 * sin(uTime * 0.9 + radius * 8.0);
    vec2 distort = vec2(
        sin(wave * 2.0 * 3.14159 * kaleidoUV.x) * timeWarp,
        cos(wave * 2.0 * 3.14159 * kaleidoUV.y) * timeWarp
    );
    vec2 distortedUV = kaleidoUV + distort;

    // Sample the texture with kaleidoscopic flow
    vec3 col = texture(uTexture, distortedUV).rgb;

    // Add dynamic neon glow based on face center (emphasize face)
    float faceMask = 1.0 - smoothstep(0.2, 0.8, radius);
    float glowStrength = 0.7 * faceMask * (1.0 - radius * 0.5);
    vec3 neon = neonPalette(uTime);
    col = mix(col, neon, 0.5 * glowStrength);

    // Add radial pulse glow with soft edge
    float radialGlow = 0.3 * (1.0 - radius) * (1.0 - pow(radius, 2.0));
    col += radialGlow * neon * 0.7;

    // Subtle ripple effect from center with time modulation
    float ripple = 0.05 * sin(uTime * 2.0 + radius * 18.0) * (1.0 - radius);
    vec2 ripples = vec2(
        sin(uTime * 1.1 + 3.0 * radius * 6.0) * ripple,
        cos(uTime * 0.9 + 3.0 * radius * 6.0) * ripple
    );
    col = mix(col, neon, 0.2 * step(0.3, radius) * ripple);

    // Glitch effect: shimmering color shift with time and motion
    float glitch = 0.02 * sin(uTime * 3.0 + 4.0 * uv.x + 2.0 * uv.y);
    col.r = texture(uTexture, uv + vec2(glitch, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-glitch, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, glitch)).b;

    // Enhance vibrancy with non-linear toning and color saturation
    col = pow(col, vec3(0.65)); // Slight contrast boost
    col = mix(col, neon, 0.4 + 0.6 * sin(uTime * 1.7)); // Pulsing neon tint

    // Final touch: soft edge glow and lens flare simulation
    float edgeGlow = 0.2 * (1.0 - radius) * (1.0 - radius);
    col += edgeGlow * neon * 0.5;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
