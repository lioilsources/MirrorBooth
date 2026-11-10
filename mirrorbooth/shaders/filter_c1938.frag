#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonPalette(float t) {
    vec3 a = vec3(0.1, 0.6, 1.0);     // Bright cyan-blue
    vec3 b = vec3(1.0, 0.1, 0.9);     // Vivid magenta-pink
    vec3 c = vec3(1.0, 1.0, 0.3);     // Hot neon yellow
    vec3 d = vec3(0.4, 0.0, 1.0);     // Deep electric blue
    return mix(
        mix(a, b, 0.5 + 0.5 * sin(t * 0.65)),
        mix(c, d, 0.5 + 0.5 * sin(t * 1.25)),
        0.5 + 0.5 * sin(t * 0.85)
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

    // Dynamic 24-fold kaleidoscope with flowing symmetry and time-driven warping
    float symmetry = 24.0 + 10.0 * sin(uTime * 0.3);
    float angle = atan(p.y, p.x);
    float slice = floor(angle / (2.0 * 3.14159) * symmetry + 0.5) / symmetry;
    float newAngle = slice * (2.0 * 3.14159 / symmetry);
    vec2 mirrored = rotate(p, newAngle);
    vec2 kaleidoUV = mirrored + center;

    // Fluid wave distortion: radial and angular flow with time sync and organic motion
    float waveIntensity = 0.03 * (1.0 - pow(radius, 0.3));
    float waveX = sin(uTime * 2.5 + kaleidoUV.x * 15.0 + radius * 20.0) * waveIntensity;
    float waveY = cos(uTime * 2.7 + kaleidoUV.y * 15.0 + radius * 20.0) * waveIntensity;
    vec2 distortedUV = kaleidoUV + vec2(waveX, waveY);

    // Subtle organic jitter with motion-synced noise and face-relative modulation
    float jitter = 0.007 * sin(uTime * 6.0 + uv.x * 22.0 + uv.y * 28.0 + radius * 3.0);
    distortedUV += vec2(jitter, jitter * 0.65);

    // Sample with edge clamping and slight temporal blur for dreamy flow
    vec3 col = texture(uTexture, clamp(distortedUV, 0.0, 1.0)).rgb;

    // Neon glow: pulsing from center with smooth luminance and radial falloff
    float l = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 neon = neonPalette(uTime);
    float glow = 1.0 - pow(radius, 0.15);
    float glowIntensity = 1.2 * (1.0 - l) * glow * (0.6 + 0.4 * sin(uTime * 1.7));
    col = mix(col, neon, glowIntensity * 0.8);

    // Expanding soft bloom halo with time and radial modulation
    float bloom = 0.6 * (1.0 - radius) * (0.7 + 0.3 * sin(uTime * 2.1));
    col += bloom * neon * 0.9;

    // Animated concentric ripples: flowing from center with color-shifting hue and motion sync
    float ripple = 0.4 * sin(uTime * 6.2 + radius * 27.0 + 0.5 * sin(uTime * 0.7));
    float rippleStrength = 0.7 * step(0.25, radius) * ripple;
    vec2 ripples = vec2(
        sin(uTime * 3.1 + radius * 17.0) * ripple,
        cos(uTime * 3.4 + radius * 17.0) * ripple
    );
    col = mix(col, neon, rippleStrength * 0.7);

    // Chromatic aberration glitch: time-based color fringing for digital vibrancy
    float glitch = 0.018 * sin(uTime * 4.5 + 10.0 * uv.x + 12.0 * uv.y + 0.8 * sin(uTime * 1.3));
    col.r = texture(uTexture, uv + vec2(glitch, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-glitch, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, glitch)).b;

    // Face-synced color pulse: rhythmic tint that pulses with time and follows face
    float pulse = 0.5 + 0.5 * sin(uTime * 3.0 + 0.6 * radius);
    col = mix(col, neon, 0.6 * pulse * (1.0 - pow(radius, 0.1)));

    // Soft radial vignette with luminance-based glow and depth
    vec2 vig = uv * 2.0 - 1.0;
    float vignette = pow(clamp(1.0 - dot(vig * 0.65, vig * 0.65), 0.0, 1.0), 0.7);
    col *= mix(0.8, 1.0, vignette);

    // Final enhancements: punchy contrast, saturation boost, and neon sheen
    col = pow(col, vec3(0.55));  // Slight contrast boost for clarity
    col = clamp(col, 0.0, 1.0);
    col = mix(col, neon, 0.4 * (1.0 - l) * (1.0 - pow(radius, 0.2)));  // Final neon pop

    fragColor = vec4(col, 1.0);
}
