#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return vec3(
        0.9 + 0.5 * sin(t * 1.6 + 0.4),
        0.5 + 0.5 * sin(t * 1.6 + 2.5),
        1.2 + 0.5 * sin(t * 1.6 + 4.8)
    ) * 3.0;
}

vec2 kaleidoscopeWarp(vec2 uv, float symmetry, float t, float radius, out vec2 outUV) {
    vec2 centered = uv - 0.5;
    float angle = 2.0 * 3.14159 / symmetry;
    float a = atan(centered.y, centered.x) + t * 0.6;
    float c = floor(a / angle);
    float d = mod(a, angle);
    float r = length(centered);
    
    // Radial wave modulation
    float wave = 0.3 * sin(r * 10.0 + t * 1.4) * (1.0 - 0.4 * sin(t * 0.8));
    // Angular flow modulation
    float flow = 0.4 * sin(d * 8.0 + t * 1.7) * (1.0 - 0.5 * sin(r * 5.0 + t * 1.2));
    // Combined distortion
    float distortion = (wave + flow) * (1.0 - 0.2 * sin(t * 0.9));
    
    float newR = r * (1.0 - distortion * 0.8);
    float newAngle = d + 0.4 * sin(t * 1.3 + d * 6.0) * (1.0 - 0.4 * sin(r * 7.0 + t * 1.1));
    
    outUV = 0.5 + vec2(cos(newAngle), sin(newAngle)) * newR;
    return outUV;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 faceCenter = uFaceCenter;
    float faceRadius = uFaceScale * 0.4;
    float t = uTime * 1.4;

    // Face mask with soft falloff
    float distToFace = length(uv - faceCenter);
    float faceMask = smoothstep(0.0, faceRadius, distToFace);
    float edgeMask = smoothstep(0.0, 0.1, faceRadius - distToFace);

    // Apply kaleidoscopic warping centered on face
    vec2 warpedUV;
    kaleidoscopeWarp(uv, 12.0 + 8.0 * sin(t * 0.3), t, 0.2 + 0.1 * sin(t * 0.25), warpedUV);

    // Dynamic scaling based on radial position
    vec2 centered = uv - faceCenter;
    float scale = 1.0 + 0.8 * (1.0 - faceMask) * (1.0 + 0.7 * sin(t * 0.9));
    vec2 finalUV = faceCenter + (warpedUV - faceCenter) * scale;

    // Sample base color
    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    // Neon pulse waves across the screen
    float pulse = 0.5 + 0.5 * sin(t * 2.8 + uv.x * 20.0 + uv.y * 18.0);
    vec3 neon = neonGlow(t);
    col = mix(col, neon, pulse * 0.7 * faceMask);

    // Chromatic ripple with flowing tint
    float chroma = 0.015 * sin(t * 1.8 + uv.x * 12.0 + uv.y * 10.0);
    vec3 shifted = vec3(
        texture(uTexture, finalUV + vec2(chroma, 0.0)).r,
        texture(uTexture, finalUV + vec2(-chroma, 0.0)).g,
        texture(uTexture, finalUV + vec2(0.0, chroma)).b
    );
    col = mix(col, shifted, 0.4 * faceMask);

    // Glowing halo with motion blur
    float blur = 0.01 + 0.008 * sin(t * 1.1);
    vec2 px = blur / uResolution;
    vec2 offsetDir = vec2(sin(t * 0.8), cos(t * 0.6)) * 0.3;
    vec3 glowAccum = vec3(0.0);
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = finalUV + offsetDir * (float(i) + float(j)) * 0.25 * blur;
            glowAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    glowAccum /= 25.0;
    float motionGlow = 0.6 * sin(t * 3.0 + distToFace * 10.0) * (1.0 + 0.5 * sin(t * 1.0));
    col = mix(col, glowAccum, 0.3 * motionGlow * faceMask);

    // Dynamic edge glow with radial flare
    float edgeGlow = 0.8 * (1.0 - faceMask) * smoothstep(0.0, 0.15, distToFace / faceRadius);
    vec3 glowColor = neonGlow(t * 0.8);
    col = mix(col, glowColor, edgeGlow * 0.6);

    // Subtle ripple glow around face
    float ripple = 0.5 * sin(distToFace * 8.0 + t * 2.5) * (1.0 - 0.4 * faceMask);
    col = mix(col, vec3(1.4, 0.8, 1.7), edgeGlow * (0.4 + ripple));

    // Final color boost and bloom
    col *= vec3(1.6, 1.4, 2.0);
    col = pow(col, vec3(0.6));
    col = clamp(col, 0.0, 1.0);

    // Soft vignette with dynamic depth
    float vignette = 1.0 - 2.0 * length(uv - 0.5) * length(uv - 0.5);
    col *= mix(0.9, 1.1, smoothstep(0.0, 0.3, length(uv - 0.5)));

    // Add subtle edge enhancement
    vec2 dxy = vec2(1.0, 0.0) * (1.0 / uResolution);
    float edge = abs(texture(uTexture, finalUV).r - texture(uTexture, finalUV + dxy).r);
    edge += abs(texture(uTexture, finalUV).g - texture(uTexture, finalUV + dxy).g);
    edge += abs(texture(uTexture, finalUV).b - texture(uTexture, finalUV + dxy).b);
    col += vec3(0.4, 0.7, 1.3) * edge * 0.25;

    // Final flare and chromatic shimmer
    float flare = 0.7 + 0.3 * sin(t * 2.2 + length(uv - 0.5) * 6.0);
    col += vec3(0.3, 0.5, 0.9) * flare * smoothstep(0.0, 0.2, length(uv - 0.5));

    fragColor = vec4(col, 1.0);
}
