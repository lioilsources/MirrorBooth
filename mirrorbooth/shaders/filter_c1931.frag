#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return vec3(
        0.8 + 0.4 * sin(t * 1.7 + 0.3),
        0.6 + 0.4 * sin(t * 1.7 + 2.6),
        1.0 + 0.4 * sin(t * 1.7 + 4.9)
    ) * 2.5;
}

vec2 flowDistortion(vec2 uv, float t) {
    float s = sin(t * 0.5) * 0.3;
    float x = uv.x * 12.0 + s * 1.5;
    float y = uv.y * 12.0 - s * 1.0;
    float fx = sin(x + t * 0.9) * 0.4 + 0.5;
    float fy = cos(y + t * 0.8) * 0.4 + 0.5;
    return vec2(fx, fy) * 0.1;
}

float kaleidoscopeWarp(vec2 uv, float n, float t, float radius, out vec2 outUV) {
    vec2 centered = uv - 0.5;
    float angle = 2.0 * 3.14159 / n;
    float a = atan(centered.y, centered.x) + t * 0.4;
    float c = floor(a / angle);
    float d = mod(a, angle);
    float r = length(centered);
    
    float wave = 0.2 * sin(r * 8.0 + t * 1.3) * (1.0 - 0.5 * sin(t * 0.6));
    float flow = 0.5 * sin(d * 6.0 + t * 1.5) * (1.0 - 0.4 * sin(r * 4.0 + t * 1.0));
    float distortion = (wave + flow) * (1.0 - 0.3 * sin(t * 0.8));
    
    float newR = r * (1.0 - distortion * 0.7);
    float newAngle = d + 0.3 * sin(t * 1.2 + d * 5.0) * (1.0 - 0.3 * sin(r * 6.0 + t * 1.0));
    
    outUV = 0.5 + vec2(cos(newAngle), sin(newAngle)) * newR;
    return newR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 faceCenter = uFaceCenter;
    float faceRadius = uFaceScale * 0.4;

    float t = uTime * 1.3;
    float symmetry = 10.0 + 8.0 * sin(t * 0.3);
    float radius = 0.2 + 0.1 * sin(t * 0.25);
    float faceMask = smoothstep(0.0, faceRadius, length(uv - faceCenter));

    // Apply kaleidoscopic warping centered on face
    vec2 warpedUV;
    float newR = kaleidoscopeWarp(uv, symmetry, t, radius, warpedUV);
    
    // Dynamic scaling with flowing center shift
    vec2 centered = uv - faceCenter;
    float distToFace = length(centered);
    float scale = 1.0 + 0.7 * (1.0 - faceMask) * (1.0 + 0.6 * sin(t * 0.8));
    vec2 finalUV = faceCenter + (warpedUV - faceCenter) * scale;

    // Sample with warping
    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    // Add flowing neon waves across screen
    vec2 flow = flowDistortion(uv, t);
    vec3 waveColor = neonGlow(t);
    col = mix(col, waveColor, 0.7 * faceMask * (1.0 + 0.3 * sin(t * 1.1)));

    // Intense neon glow around edges
    float edgeGlow = 0.8 * (1.0 - faceMask) * smoothstep(0.0, 0.1, distToFace / faceRadius);
    vec3 glowColor = neonGlow(t * 0.9);
    col = mix(col, glowColor, edgeGlow);

    // Soft ripple glow around face with pulsing intensity
    float ripple = 0.4 * sin(distToFace * 7.0 + t * 2.0) * (1.0 - 0.6 * faceMask);
    col = mix(col, vec3(1.3, 0.7, 1.6), edgeGlow * (0.5 + ripple));

    // Motion blur with flowing jitter
    float blur = 0.012 + 0.007 * sin(t * 1.0);
    vec2 px = blur / uResolution;
    vec2 offsetDir = vec2(sin(t * 0.9), cos(t * 0.7)) * 0.2;
    vec3 blurAccum = vec3(0.0);
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = finalUV + offsetDir * (float(i) + float(j)) * 0.3 * blur;
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    col = mix(col, blurAccum / 9.0, 0.25);

    // Enhance vibrancy and saturation with a more dynamic contrast
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 4.0);
    col = pow(col, vec3(0.6));

    // Chromatic aberration with flowing tint and phase shift
    float aberration = 0.018 * sin(t * 2.8 + 3.0 * uv.x + 2.0 * uv.y);
    col.r = texture(uTexture, uv + vec2(aberration, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-aberration, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, aberration)).b;

    // Final color boost and neon bloom with pulsing glow
    col = clamp(col, 0.0, 1.0);
    float bloom = 0.25 + 0.15 * sin(t * 1.5);
    col = mix(col, vec3(1.2, 0.9, 1.5), bloom);

    // Add subtle radial gradient glow from face center
    float radialGlow = 0.3 * (1.0 - smoothstep(0.0, 0.15, distToFace / faceRadius));
    vec3 radialColor = vec3(0.9, 0.3, 1.1) * (1.0 + 0.5 * sin(t * 1.4));
    col = mix(col, radialColor, radialGlow);

    fragColor = vec4(col, 1.0);
}
