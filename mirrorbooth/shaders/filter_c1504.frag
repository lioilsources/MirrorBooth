#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return 0.7 + 0.5 * vec3(
        sin(t * 1.5 + 0.0) * 0.5 + 0.5,
        sin(t * 1.5 + 2.4) * 0.5 + 0.5,
        sin(t * 1.5 + 4.8) * 0.5 + 0.5
    ) * 1.5;
}

vec2 kaleidoscopeFlow(vec2 uv, float segments, float angleOffset, float timeMod) {
    vec2 centered = uv - uFaceCenter;
    float r = length(centered);
    float a = atan(centered.y, centered.x) + angleOffset + timeMod;
    float angleStep = 6.2831853 / segments;
    float segment = floor(a / angleStep);
    float inv = mod(segment + 1.0, segments);
    float invAngle = a - (segment * angleStep);
    float newAngle = invAngle + angleStep * (inv - 1.0);

    // Organic flow modulation with radial and time dependence
    float flow = 0.3 * sin(r * 12.0 + uTime * 2.1 + segment * 0.6) * (1.0 + 0.4 * sin(uTime * 0.8));
    float radiusMod = 1.0 + 0.25 * flow * (1.0 - r * 1.8);
    
    return uFaceCenter + (r * radiusMod) * vec2(cos(newAngle), sin(newAngle));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;

    // Dynamic kaleidoscope: pulsing symmetry and radial boundary
    float timeOffset = uTime * 0.7;
    float segments = 6.0 + 6.0 * sin(uTime * 0.4); // 6 to 12-fold symmetry
    float innerRadius = 0.25 + 0.1 * sin(uTime * 0.3); // Inner boundary pulses

    // Face-aware mask: preserve face clarity, apply effect outward
    vec2 faceDir = uv - center;
    float distToFace = length(faceDir * uFaceScale);
    float mask = smoothstep(0.0, uFaceScale * 0.4, distToFace);
    float strength = 1.0 - 0.3 * mask;

    // Apply kaleidoscopic flow with time-based distortion
    vec2 warpedUV = kaleidoscopeFlow(uv, segments, timeOffset, uTime * 0.4);

    // Add subtle wave distortion for fluid motion
    float waveX = sin(uv.y * 20.0 + uTime * 1.4) * 0.004;
    float waveY = sin(uv.x * 20.0 + uTime * 1.5) * 0.004;
    warpedUV += vec2(waveX, waveY) * (1.0 - mask);

    // Clamp and sample texture
    vec3 col = texture(uTexture, clamp(warpedUV, 0.0, 1.0)).rgb;

    // Layered neon color waves: flowing, vibrant, and depth-rich
    float wave1 = sin(uTime * 1.1 + uv.x * 10.0 + uv.y * 8.0);
    float wave2 = sin(uTime * 1.2 + uv.x * 9.0 - uv.y * 7.0);
    float wave3 = sin(uTime * 1.0 + uv.x * 11.0 + uv.y * 6.0);
    vec3 waveColor = vec3(wave1, wave2, wave3) * 0.5 + 0.5;
    waveColor = mix(vec3(0.1, 0.9, 1.0), vec3(1.0, 0.2, 0.9), waveColor.g) * 0.8;
    waveColor = mix(waveColor, vec3(1.0, 1.0, 0.4), 0.6 * (1.0 - mask));
    col = mix(col, waveColor, 0.6 * mask);

    // Pulsing neon halo with dynamic intensity
    float radial = 1.0 - length(uv - center);
    float glow = pow(radial, 2.5) * (0.8 + 0.7 * sin(uTime * 2.8));
    vec3 halo = neonGlow(uTime * 1.6) * glow * 2.0;
    col = mix(col, halo, smoothstep(0.7, 0.92, radial) * 0.9);

    // Chromatic edge glow with motion and depth
    float edge = 1.0 - smoothstep(0.88, 0.96, length(uv - center));
    vec3 edgeGlow = neonGlow(uTime * 1.3) * edge * 0.8;
    col = mix(col, edgeGlow, edge * 0.5);

    // Motion blur with directional flow and soft trails
    float blur = 0.01 + 0.008 * sin(uTime * 0.7);
    vec2 px = blur / uResolution;
    vec2 offsetDir = vec2(sin(uTime * 0.6), cos(uTime * 0.5)) * 0.3;
    vec3 blurAccum = vec3(0.0);
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            if (i == 0 && j == 0) continue;
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = warpedUV + offsetDir * (float(i) + float(j)) * 0.2 * blur;
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    col = mix(col, blurAccum / 24.0, 0.2 * strength);

    // Final enhancement: high saturation, contrast, and glow
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 4.0); // Extreme saturation boost
    col = pow(col, vec3(0.6)); // Deep contrast and punch
    col = clamp(col, 0.0, 1.0);

    fragColor = vec4(col, 1.0);
}
