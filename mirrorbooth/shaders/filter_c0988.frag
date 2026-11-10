#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonPalette(float t) {
    vec3 a = vec3(0.0, 0.8, 1.0);     // vibrant cyan
    vec3 b = vec3(1.0, 0.2, 1.0);     // electric magenta
    vec3 c = vec3(1.0, 1.0, 0.5);     // neon yellow
    vec3 d = vec3(0.3, 0.5, 1.0);     // deep blue-violet
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

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter * uFaceScale + (1.0 - uFaceScale) * 0.5;
    vec2 p = uv - center;
    float radius = length(p);

    // Dynamic kaleidoscope: 12-fold symmetry with animated rotation and flow
    float symmetry = 12.0 + 6.0 * sin(uTime * 0.5);
    float angle = atan(p.y, p.x);
    float slice = floor(angle / (2.0 * 3.14159) * symmetry + 0.5) / symmetry;
    float newAngle = slice * (2.0 * 3.14159 / symmetry);
    vec2 mirrored = rotate(p, newAngle);
    vec2 kaleidoUV = mirrored + center;

    // Flowing distortion with time and radial control
    float waveIntensity = 0.025 * (1.0 - pow(radius, 0.25));
    float timeWarp = waveIntensity * sin(uTime * 3.0 + kaleidoUV.x * 10.0 + kaleidoUV.y * 10.0);
    vec2 distortedUV = kaleidoUV + vec2(
        sin(uTime * 2.8 + kaleidoUV.x * 14.0) * timeWarp,
        cos(uTime * 3.1 + kaleidoUV.y * 14.0) * timeWarp
    );

    // Subtle organic jitter synced to face and time
    float jitter = 0.006 * sin(uTime * 7.0 + uv.x * 18.0 + uv.y * 22.0);
    distortedUV += vec2(jitter, jitter * 0.7);

    // Sample with edge clamping and slight blur for dreamy effect
    vec3 col = texture(uTexture, clamp(distortedUV, 0.0, 1.0)).rgb;

    // Dynamic neon glow: pulsing from center with smooth radial falloff
    float l = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 neon = neonPalette(uTime);
    float glow = 1.0 - pow(radius, 0.12);
    float glowIntensity = 1.0 * (1.0 - l) * glow * (0.5 + 0.5 * sin(uTime * 1.5));
    col = mix(col, neon, glowIntensity * 0.7);

    // Expanding soft bloom halo with time and radial modulation
    float bloom = 0.5 * (1.0 - radius) * (1.0 - pow(radius, 0.1));
    col += bloom * neon * 0.8;

    // Animated concentric ripples with color pulse and motion sync
    float ripple = 0.35 * sin(uTime * 6.0 + radius * 25.0 + 0.4 * sin(uTime * 0.6));
    float rippleStrength = 0.6 * step(0.35, radius) * ripple;
    vec2 ripples = vec2(
        sin(uTime * 3.0 + radius * 18.0) * ripple,
        cos(uTime * 3.3 + radius * 18.0) * ripple
    );
    col = mix(col, neon, rippleStrength * 0.5);

    // Chromatic shift with time-based jitter and motion sync
    float glitch = 0.012 * sin(uTime * 4.8 + 10.0 * uv.x + 12.0 * uv.y + 1.5 * sin(uTime * 1.1));
    col.r = texture(uTexture, uv + vec2(glitch, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-glitch, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, glitch)).b;

    // Rhythmic tint pulse: synchronized with face presence and time
    float tint = 0.6 + 0.4 * sin(uTime * 2.5 + 0.8 * radius);
    col = mix(col, neon, 0.6 * tint * (1.0 - pow(radius, 0.18)));

    // Soft radial vignette with luminance-based glow and depth
    vec2 vig = uv * 2.0 - 1.0;
    float vignette = pow(clamp(1.0 - dot(vig * 0.6, vig * 0.6), 0.0, 1.0), 0.8);
    col *= mix(0.8, 1.0, vignette);

    // Final tone: high contrast, vibrancy boost, and neon sheen
    col = pow(col, vec3(0.6));  // Enhanced clarity and punch
    col = mix(col, neon, 0.35 * (1.0 - pow(radius, 0.2)));  // Add glowing layer
    col = clamp(col, 0.0, 1.0);

    fragColor = vec4(col, 1.0);
}
