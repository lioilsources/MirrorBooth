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

float kaleidoscopeWarp(vec2 uv, float symmetry, float t, float radius, out vec2 outUV) {
    vec2 centered = uv - 0.5;
    float angle = 2.0 * 3.14159 / symmetry;
    float a = atan(centered.y, centered.x) + t * 0.5;
    float c = floor(a / angle);
    float d = mod(a, angle);
    float r = length(centered);
    
    // Dynamic radial wave modulation
    float wave = 0.15 * sin(r * 10.0 + t * 1.5) * (1.0 - 0.4 * sin(t * 0.7));
    float flow = 0.4 * sin(d * 8.0 + t * 1.8) * (1.0 - 0.5 * sin(r * 5.0 + t * 1.2));
    float distortion = (wave + flow) * (1.0 - 0.2 * sin(t * 0.9));
    
    float newR = r * (1.0 - distortion * 0.6);
    float newAngle = d + 0.2 * sin(t * 1.3 + d * 6.0) * (1.0 - 0.2 * sin(r * 7.0 + t * 1.1));
    
    outUV = 0.5 + vec2(cos(newAngle), sin(newAngle)) * newR;
    return newR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 faceCenter = uFaceCenter;
    float faceRadius = uFaceScale * 0.4;

    float t = uTime * 1.4;
    float symmetry = 12.0 + 10.0 * sin(t * 0.35);
    float radius = 0.2 + 0.12 * sin(t * 0.28);
    float faceMask = smoothstep(0.0, faceRadius, length(uv - faceCenter));

    // Apply kaleidoscopic warping centered on face
    vec2 warpedUV;
    float newR = kaleidoscopeWarp(uv, symmetry, t, radius, warpedUV);

    // Apply dynamic scaling based on distance from face
    vec2 centered = uv - faceCenter;
    float distToFace = length(centered);
    float scale = 1.0 + 0.6 * (1.0 - faceMask) * (1.0 + 0.5 * sin(t * 0.9));
    vec2 finalUV = faceCenter + (warpedUV - faceCenter) * scale;

    // Sample with warping
    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    // Intensified neon glow: pulsing color from face center
    float l = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 neon = neonPalette(t);
    float glowIntensity = 1.4 * (1.0 - l) * (1.0 - pow(distToFace / faceRadius, 0.4));
    col = mix(col, neon, glowIntensity * 0.9);

    // Dynamic bloom: soft, expanding glow with radial falloff and time sync
    float bloom = 0.9 * (1.0 - distToFace / faceRadius) * (1.0 - pow(distToFace / faceRadius, 0.2));
    col += bloom * neon * 0.8;

    // Animated concentric ripples: flowing waves from face center
    float ripple = 0.5 * sin(t * 8.0 + distToFace * 30.0 - 0.6 * sin(t * 0.8));
    float rippleStrength = 0.8 * step(0.15, distToFace) * ripple;
    vec2 ripples = vec2(
        sin(t * 3.8 + distToFace * 25.0) * ripple,
        cos(t * 3.6 + distToFace * 25.0) * ripple
    );
    col = mix(col, neon, rippleStrength * 0.6);

    // Organic jitter with face-centered motion and flow
    float jitter = 0.012 * sin(t * 6.0 + uv.x * 20.0 + uv.y * 28.0 + distToFace * 12.0);
    vec2 jitterUV = finalUV + vec2(jitter, jitter * 0.6);
    col = mix(col, texture(uTexture, clamp(jitterUV, 0.0, 1.0)).rgb, 0.2);

    // Chromatic shift: rhythmic color fringing with time
    float glitch = 0.016 * sin(t * 5.2 + 14.0 * uv.x + 16.0 * uv.y);
    col.r = texture(uTexture, uv + vec2(glitch, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-glitch, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, glitch)).b;

    // Dynamic tint: pulsing color shift synced to time and motion
    float tint = 0.8 + 0.4 * sin(t * 3.1);
    col = mix(col, neon, 0.7 * tint);

    // Soft radial vignette with luminance-based tint and glow
    vec2 vig = uv * 2.0 - 1.0;
    float vignette = pow(clamp(1.0 - dot(vig * 0.6, vig * 0.6), 0.0, 1.0), 0.8);
    col *= mix(0.88, 1.0, vignette);

    // Final enhancements: punchy contrast, clarity, and vibrant saturation
    col = pow(col, vec3(0.55));   // Stronger contrast boost
    col = clamp(col, 0.0, 1.0);

    // Add subtle motion blur with flowing jitter
    float blur = 0.01 + 0.006 * sin(t * 1.1);
    vec2 px = blur / uResolution;
    vec2 offsetDir = vec2(sin(t * 0.8), cos(t * 0.6)) * 0.15;
    vec3 blurAccum = vec3(0.0);
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = finalUV + offsetDir * (float(i) + float(j)) * 0.4 * blur;
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    col = mix(col, blurAccum / 9.0, 0.2);

    fragColor = vec4(col, 1.0);
}
