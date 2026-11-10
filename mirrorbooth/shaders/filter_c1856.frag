#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonPalette(float t) {
    vec3 a = vec3(0.0, 0.4, 1.0);     // Vibrant cyan-blue
    vec3 b = vec3(1.0, 0.0, 0.8);     // Electric magenta
    vec3 c = vec3(1.0, 1.0, 0.2);     // Neon yellow-white
    vec3 d = vec3(0.2, 0.8, 1.0);     // Glowing aqua
    return mix(
        mix(a, b, 0.5 + 0.5 * sin(t * 0.7)),
        mix(c, d, 0.5 + 0.5 * sin(t * 1.3)),
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

    // Dynamic 18-fold kaleidoscope with flowing symmetry and time-driven warping
    float symmetry = 18.0 + 8.0 * sin(uTime * 0.25);
    float angle = atan(p.y, p.x);
    float slice = floor(angle / (2.0 * 3.14159) * symmetry + 0.5) / symmetry;
    float newAngle = slice * (2.0 * 3.14159 / symmetry);
    vec2 mirrored = rotate(p, newAngle);
    vec2 kaleidoUV = mirrored + center;

    // Fluid wave distortion: radial and angular flow with time sync
    float waveIntensity = 0.1 * sin(uTime * 2.0 + radius * 14.0);
    float waveX = sin(uTime * 1.7 + kaleidoUV.x * 12.0 + radius * 18.0) * waveIntensity;
    float waveY = cos(uTime * 1.9 + kaleidoUV.y * 12.0 + radius * 18.0) * waveIntensity;
    vec2 distortedUV = kaleidoUV + vec2(waveX, waveY);

    // Subtle organic jitter with motion-synced noise
    float jitter = 0.008 * sin(uTime * 6.0 + uv.x * 20.0 + uv.y * 25.0);
    distortedUV += vec2(jitter, jitter * 0.6);

    // Sample with edge clamping and dynamic warping
    vec3 col = texture(uTexture, clamp(distortedUV, 0.0, 1.0)).rgb;

    // Neon pulse glow: stronger near face, fades outward with luminance
    float l = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 neon = neonPalette(uTime);
    float glowIntensity = 1.0 * (1.0 - l) * (1.0 - pow(radius, 0.3));
    col = mix(col, neon, glowIntensity * 0.8);

    // Dynamic radial bloom: pulsing soft glow with time sync
    float bloom = 0.6 * (1.0 - radius) * (0.7 + 0.3 * sin(uTime * 1.9));
    col += bloom * neon * 0.9;

    // Animated concentric ripples: flowing from center with color-shifting hue
    float ripple = 0.4 * sin(uTime * 6.0 + radius * 28.0 + 0.5 * sin(uTime * 0.7));
    float rippleStrength = 0.7 * step(0.2, radius) * ripple;
    vec2 ripples = vec2(
        sin(uTime * 3.2 + radius * 16.0) * ripple,
        cos(uTime * 3.0 + radius * 16.0) * ripple
    );
    col = mix(col, neon, rippleStrength * 0.6);

    // Chromatic aberration glitch: time-based color fringing for digital vibrancy
    float glitch = 0.015 * sin(uTime * 4.0 + 10.0 * uv.x + 12.0 * uv.y);
    col.r = texture(uTexture, uv + vec2(glitch, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-glitch, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, glitch)).b;

    // Face-synced color pulse: rhythmic tint that pulses with time
    float pulse = 0.5 + 0.5 * sin(uTime * 2.8);
    col = mix(col, neon, 0.6 * pulse * (1.0 - radius * 0.5));

    // Soft, cinematic vignette with luminance-based depth
    vec2 vig = uv * 2.0 - 1.0;
    float vignette = pow(clamp(1.0 - dot(vig * 0.7, vig * 0.7), 0.0, 1.0), 0.6);
    col *= mix(0.85, 1.0, vignette);

    // Final enhancements: punchy contrast, saturation boost, and neon pop
    col = pow(col, vec3(0.52));  // Slight contrast boost
    col = clamp(col, 0.0, 1.0);
    col = mix(col, neon, 0.4 * (1.0 - l));  // Final neon saturation pop

    fragColor = vec4(col, 1.0);
}
