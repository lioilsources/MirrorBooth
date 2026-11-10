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
        mix(a, b, 0.5 + 0.5 * sin(t * 0.8)),
        mix(c, d, 0.5 + 0.5 * sin(t * 1.2)),
        0.5 + 0.5 * sin(t * 0.6)
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

    // Dynamic kaleidoscope: 14-fold symmetry with flowing distortion
    float symmetry = 14.0 + 6.0 * sin(uTime * 0.3);
    float angle = atan(p.y, p.x);
    float slice = floor(angle / (2.0 * 3.14159) * symmetry + 0.5) / symmetry;
    float newAngle = slice * (2.0 * 3.14159 / symmetry);
    vec2 mirrored = rotate(p, newAngle);
    vec2 kaleidoUV = mirrored + center;

    // Fluid, wave-like warping with time and radial influence
    float timeWarp = 0.1 * sin(uTime * 2.7 + radius * 12.0);
    float waveX = sin(uTime * 1.6 + kaleidoUV.x * 10.0 + radius * 10.0) * timeWarp;
    float waveY = cos(uTime * 1.8 + kaleidoUV.y * 10.0 + radius * 10.0) * timeWarp;
    vec2 distortedUV = kaleidoUV + vec2(waveX, waveY);

    // Subtle organic jitter with motion sync
    float jitter = 0.01 * sin(uTime * 5.0 + uv.x * 15.0 + uv.y * 20.0);
    distortedUV += vec2(jitter, jitter * 0.7);

    // Sample the warped texture with edge clamping
    vec3 col = texture(uTexture, clamp(distortedUV, 0.0, 1.0)).rgb;

    // Neon pulse glow: stronger near face center, fades outward
    float l = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 neon = neonPalette(uTime);
    float glowIntensity = 0.9 * (1.0 - l) * (1.0 - pow(radius, 0.2));
    col = mix(col, neon, glowIntensity);

    // Dynamic bloom: soft glow with radial falloff and motion sync
    float bloom = 0.7 * (1.0 - radius) * (1.0 - pow(radius, 0.1));
    col += bloom * neon * 0.8;

    // Animated concentric ripples: flowing from center with time
    float ripple = 0.3 * sin(uTime * 6.0 + radius * 25.0 - 0.4 * sin(uTime * 0.8));
    float rippleStrength = 0.6 * step(0.3, radius) * ripple;
    vec2 ripples = vec2(
        sin(uTime * 3.0 + radius * 18.0) * ripple,
        cos(uTime * 2.8 + radius * 18.0) * ripple
    );
    col = mix(col, neon, rippleStrength);

    // Chromatic shift: time-based color fringing for glitchy vibrancy
    float glitch = 0.02 * sin(uTime * 4.0 + 10.0 * uv.x + 12.0 * uv.y);
    col.r = texture(uTexture, uv + vec2(glitch, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-glitch, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, glitch)).b;

    // Dynamic tint: rhythmic pulse synced to time and face presence
    float tint = 0.6 + 0.4 * sin(uTime * 2.6);
    col = mix(col, neon, 0.6 * tint);

    // Soft radial vignette with luminance-based color tint
    vec2 vig = uv * 2.0 - 1.0;
    float vignette = pow(clamp(1.0 - dot(vig * 0.6, vig * 0.6), 0.0, 1.0), 0.6);
    col *= mix(0.8, 1.0, vignette);

    // Final enhancements: punchy contrast, clarity, and vibrant saturation
    col = pow(col, vec3(0.55));  // Slight contrast boost
    col = clamp(col, 0.0, 1.0);

    fragColor = vec4(col, 1.0);
}
