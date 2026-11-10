#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return vec3(
        0.9 + 0.5 * sin(t * 1.9 + 0.2),
        0.3 + 0.7 * sin(t * 1.9 + 2.4),
        1.0 + 0.6 * sin(t * 1.9 + 4.6)
    ) * 3.5;
}

vec2 flowDistortion(vec2 uv, float t) {
    float x = uv.x * 18.0 + t * 1.3;
    float y = uv.y * 18.0 + t * 1.1;
    float s = sin(x) * cos(y) * 0.5 + 0.5;
    float w1 = sin(x * 1.4 + y * 1.3 + t * 0.7) * 0.5 + 0.5;
    float w2 = cos(x * 1.6 - y * 1.5 + t * 0.6) * 0.5 + 0.5;
    return vec2(w1, w2) * 0.1;
}

float kaleidoscopeWarp(vec2 uv, float n, float t, float radius, out vec2 outUV) {
    vec2 centered = uv - 0.5;
    float angle = 2.0 * 3.14159 / n;
    float a = atan(centered.y, centered.x) + t * 0.6;
    float c = floor(a / angle);
    float d = mod(a, angle);
    float r = length(centered);
    
    // Radial wave distortion
    float wave = 0.25 * sin(r * 9.0 + t * 1.4) * (1.0 - 0.4 * sin(t * 0.9));
    // Angular flow distortion
    float flow = 0.3 * sin(d * 8.0 + t * 1.6) * (1.0 - 0.5 * sin(r * 5.0 + t * 1.1));
    // Dynamic time-based warping
    float distortion = (wave + flow) * (1.0 - 0.3 * sin(t * 0.8));
    
    float newR = r * (1.0 - distortion * 0.8);
    float newAngle = d + 0.4 * sin(t * 1.3 + d * 6.0) * (1.0 - 0.4 * sin(r * 7.0 + t * 1.2));
    
    outUV = 0.5 + vec2(cos(newAngle), sin(newAngle)) * newR;
    return newR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 faceCenter = uFaceCenter;
    float faceRadius = uFaceScale * 0.4;
    float t = uTime * 1.2;

    // Dynamic symmetry: 12 to 20 folds, pulsing with time
    float symmetry = 12.0 + 8.0 * sin(t * 0.35);
    float radius = 0.15 + 0.1 * sin(t * 0.22);
    float faceMask = smoothstep(0.0, faceRadius, length(uv - faceCenter));

    // Apply kaleidoscopic warping centered on face
    vec2 warpedUV;
    float newR = kaleidoscopeWarp(uv, symmetry, t, radius, warpedUV);

    // Adaptive scaling: stronger near face, fades at edges
    vec2 centered = uv - faceCenter;
    float distToFace = length(centered);
    float scale = 1.0 + 0.8 * (1.0 - faceMask) * (1.0 + 0.5 * sin(t * 0.9));
    vec2 finalUV = faceCenter + (warpedUV - faceCenter) * scale;

    // Sample texture with warping and edge clamping
    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    // Add flowing neon waves across screen
    vec2 flow = flowDistortion(uv, t);
    vec3 waveColor = neonGlow(t);
    col = mix(col, waveColor, 0.8 * faceMask * (1.0 + 0.3 * sin(t * 1.0)));

    // Intense neon glow around face boundary
    float edgeGlow = 0.9 * (1.0 - faceMask) * smoothstep(0.0, 0.08, distToFace / faceRadius);
    vec3 glowColor = neonGlow(t * 0.8);
    col = mix(col, glowColor, edgeGlow);

    // Soft ripple glow around face
    float ripple = 0.5 * sin(distToFace * 8.0 + t * 2.1) * (1.0 - 0.5 * faceMask);
    col = mix(col, vec3(1.4, 0.8, 1.7), edgeGlow * (0.6 + ripple));

    // Directional motion blur with jitter and radial falloff
    float blur = 0.015 + 0.008 * sin(t * 1.1);
    vec2 px = blur / uResolution;
    vec2 offsetDir = vec2(sin(t * 0.8), cos(t * 0.7)) * 0.3;
    vec3 blurAccum = vec3(0.0);
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            if (i == 0 && j == 0) continue;
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = finalUV + offsetDir * (float(i) + float(j)) * 0.4 * blur;
            float weight = 1.0 - 0.1 * (abs(float(i)) + abs(float(j)));
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb * weight;
        }
    }
    col = mix(col, blurAccum / 25.0, 0.3);

    // High saturation and contrast with glowing highlights
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 3.5);
    col = pow(col, vec3(0.65));

    // Chromatic aberration with time-varying offset and depth
    float abOffset = 0.015 * sin(t * 3.2 + 5.0 * uv.x + 3.0 * uv.y) * (1.0 - faceMask * 0.6);
    vec3 abCol = vec3(
        texture(uTexture, finalUV + vec2(abOffset, 0.0)).r,
        texture(uTexture, finalUV + vec2(0.0, -abOffset)).g,
        texture(uTexture, finalUV + vec2(-abOffset, 0.0)).b
    );
    col = mix(col, abCol, 0.2);

    // Radial flare with motion sync and pulsing
    float flare = 0.9 + 0.7 * sin(t * 2.3 + distToFace * 7.0);
    col += vec3(0.6, 1.0, 1.7) * flare * (1.0 - faceMask);

    // Soft vignette with luminance-based glow and edge softness
    float vignette = 1.0 - 3.0 * distToFace * distToFace;
    col *= mix(0.9, 1.3, smoothstep(0.0, 0.25, distToFace / faceRadius));

    // Final color boost and neon bloom
    col = clamp(col, 0.0, 1.0);
    col = mix(col, vec3(1.1, 1.2, 1.4), 0.2);

    fragColor = vec4(col, 1.0);
}
