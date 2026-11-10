#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return vec3(
        0.8 + 0.6 * sin(t * 1.8 + 0.1),
        0.2 + 0.8 * sin(t * 1.8 + 2.4),
        1.0 + 0.5 * sin(t * 1.8 + 4.7)
    ) * 2.0;
}

vec2 kaleidoscopeFlow(vec2 uv, float segments, float timeOffset, float radius) {
    vec2 centered = uv - uFaceCenter;
    float r = length(centered);
    float a = atan(centered.y, centered.x) + timeOffset;
    float angleStep = 6.2831853 / segments;
    float segment = floor(a / angleStep);
    float inv = mod(segment + 1.0, segments);
    float invAngle = a - (segment * angleStep);
    float newAngle = invAngle + angleStep * (inv - 1.0);

    // Dynamic radial flow modulation with time and position
    float flow = 0.4 * sin(r * 12.0 + uTime * 2.3 + segment * 0.7) * (1.0 + 0.6 * sin(uTime * 0.8));
    float radiusMod = 1.0 + 0.3 * flow * (1.0 - r * 1.2);

    // Swirling distortion at center
    float swirl = 0.2 * sin(uTime * 1.4 + r * 4.0) * (1.0 - r * 0.8);
    newAngle += swirl;

    // Apply final transformation
    return uFaceCenter + (r * radiusMod) * vec2(cos(newAngle), sin(newAngle));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;

    float t = uTime * 0.8;
    float symmetry = 12.0 + 8.0 * sin(t * 0.5); // 12 to 20 fold symmetry, pulsing
    float radius = 0.3 + 0.25 * sin(t * 0.4); // Inner radius pulsing
    float mask = smoothstep(0.0, uFaceScale * 0.6, length(uv - center));

    // Face-aware radial mask for edge blending
    float distToFace = length((uv - center) * uFaceScale);
    float faceMask = smoothstep(0.0, uFaceScale * 0.7, distToFace);
    float strength = 1.0 - 0.5 * faceMask;

    // Apply kaleidoscopic flow with smooth time modulation
    vec2 warpedUV = kaleidoscopeFlow(uv, symmetry, t * 0.4, radius);

    // Subtle wave distortion for organic motion
    float waveX = sin(uv.y * 18.0 + t * 1.4) * 0.004;
    float waveY = sin(uv.x * 16.0 + t * 1.5) * 0.004;
    warpedUV += vec2(waveX, waveY) * (1.0 - faceMask);

    // Clamp and sample texture
    vec3 col = texture(uTexture, clamp(warpedUV, 0.0, 1.0)).rgb;

    // Add flowing neon color waves across the entire frame
    float wave1 = sin(t * 1.1 + uv.x * 10.0 + uv.y * 8.0) * 0.5 + 0.5;
    float wave2 = sin(t * 1.2 + uv.x * 9.0 - uv.y * 7.0) * 0.5 + 0.5;
    float wave3 = sin(t * 1.0 + uv.x * 11.0 + uv.y * 6.0) * 0.5 + 0.5;
    vec3 waveColor = vec3(wave1, wave2, wave3);
    waveColor = mix(vec3(0.0, 0.9, 1.0), vec3(1.0, 0.0, 0.8), waveColor.g) * 0.6;
    waveColor = mix(waveColor, vec3(1.0, 1.0, 0.2), 0.4 * (1.0 - faceMask));
    col = mix(col, waveColor, 0.5 * faceMask);

    // Pulsing neon halo around face with radial glow
    float radial = 1.0 - length(uv - center);
    float glow = pow(radial, 1.8) * (0.8 + 0.7 * sin(t * 2.6));
    vec3 halo = neonGlow(t * 1.6) * glow * 2.0;
    col = mix(col, halo, smoothstep(0.65, 0.9, radial) * 0.9);

    // Edge chromatic glow with swirling motion
    float edge = 1.0 - smoothstep(0.88, 0.96, length(uv - center));
    float aberration = 0.04 * sin(t * 3.2 + 6.0 * uv.x + 4.0 * uv.y);
    vec3 edgeGlow = neonGlow(t * 1.3) * edge * 0.6;
    col = mix(col, edgeGlow, edge * 0.5);

    // Motion blur with swirling directional flow
    float blur = 0.01 + 0.015 * sin(t * 0.7);
    vec2 px = blur / uResolution;
    vec2 offsetDir = vec2(sin(t * 0.6), cos(t * 0.9)) * 0.5;
    vec3 blurAccum = vec3(0.0);
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = warpedUV + offsetDir * (float(i) + float(j)) * 0.4 * blur;
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    col = mix(col, blurAccum / 25.0, 0.3 * strength);

    // Final color enhancement: extreme saturation, glow, and tone curve
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 4.5); // High saturation boost
    col = pow(col, vec3(0.6)); // Deep contrast and glow
    col = clamp(col, 0.0, 1.0);

    // Dynamic neon tint with phase shift and motion
    float pulse = 0.9 + 0.8 * sin(t * 2.5);
    col = mix(col, neonGlow(t * 1.4), pulse);

    // Final bloom and glow enhancement
    col = mix(col, vec3(1.4, 1.2, 1.7), 0.4);

    fragColor = vec4(col, 1.0);
}
