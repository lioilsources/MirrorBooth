#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return 0.7 + 0.5 * vec3(
        sin(t * 1.6 + 0.1) * 0.5 + 0.5,
        sin(t * 1.6 + 2.1) * 0.5 + 0.5,
        sin(t * 1.6 + 4.1) * 0.5 + 0.5
    );
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

    // Flow modulation with time and radial position
    float flow = 0.3 * sin(r * 12.0 + uTime * 2.5 + segment * 0.7) * (1.0 + 0.6 * sin(uTime * 0.8));
    float radiusMod = 1.0 + 0.25 * flow * (1.0 - r * 1.8);

    return uFaceCenter + (r * radiusMod) * vec2(cos(newAngle), sin(newAngle));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;

    // Dynamic kaleidoscope with pulsing symmetry
    float timeOffset = uTime * 0.7;
    float n = 6.0 + 6.0 * sin(uTime * 0.4); // 6 to 12-fold, smooth pulsing
    float radius = 0.3 + 0.2 * sin(uTime * 0.35); // Inner boundary pulsing

    // Face-aware radial mask with smooth falloff
    vec2 faceDir = uv - center;
    float distToFace = length(faceDir * uFaceScale);
    float mask = smoothstep(0.0, uFaceScale * 0.6, distToFace);
    float strength = 1.0 - 0.5 * mask;

    // Apply kaleidoscopic flow with time-based distortion
    vec2 warpedUV = kaleidoscopeFlow(uv, n, timeOffset, uTime * 0.35);

    // Subtle wave distortion for organic flow
    float waveX = sin(uv.y * 18.0 + uTime * 1.4) * 0.006;
    float waveY = sin(uv.x * 18.0 + uTime * 1.5) * 0.006;
    warpedUV += vec2(waveX, waveY) * (1.0 - mask);

    // Clamp and sample texture
    vec3 col = texture(uTexture, clamp(warpedUV, 0.0, 1.0)).rgb;

    // Vibrant neon color waves with time and motion
    float wave1 = sin(uTime * 0.8 + uv.x * 10.0 + uv.y * 8.0);
    float wave2 = sin(uTime * 1.0 + uv.x * 9.0 - uv.y * 7.0);
    float wave3 = sin(uTime * 0.9 + uv.x * 11.0 + uv.y * 6.0);
    vec3 waveColor = vec3(wave1, wave2, wave3) * 0.5 + 0.5;
    waveColor = mix(vec3(0.0, 0.9, 1.0), vec3(1.0, 0.0, 0.8), waveColor.g) * 0.8;
    waveColor = mix(waveColor, vec3(1.0, 0.7, 0.0), 0.6 * (1.0 - mask));
    col = mix(col, waveColor, 0.6 * mask);

    // Pulsing neon halo with radial glow and motion
    float radial = 1.0 - length(uv - center);
    float glow = pow(radial, 2.2) * (0.8 + 0.7 * sin(uTime * 2.8));
    vec3 halo = neonGlow(uTime * 1.6) * glow * 2.0;
    col = mix(col, halo, smoothstep(0.5, 0.9, radial) * 0.9);

    // Chromatic edge glow with swirling motion
    float edge = 1.0 - smoothstep(0.8, 0.96, length(uv - center));
    float edgeHue = fract((uTime * 0.2 + edge * 3.0) * 0.8);
    float h6 = edgeHue * 6.0;
    float c = 1.0;
    float x = c * (1.0 - abs(mod(h6, 2.0) - 1.0));
    vec3 edgeGlow;
    if      (h6 < 1.0) edgeGlow = vec3(c, x, 0.0);
    else if (h6 < 2.0) edgeGlow = vec3(x, c, 0.0);
    else if (h6 < 3.0) edgeGlow = vec3(0.0, c, x);
    else if (h6 < 4.0) edgeGlow = vec3(0.0, x, c);
    else if (h6 < 5.0) edgeGlow = vec3(x, 0.0, c);
    else               edgeGlow = vec3(c, 0.0, x);
    col = mix(col, edgeGlow * 0.8, edge * 0.6);

    // Directional motion blur with flow vector
    float blur = 0.015 + 0.008 * sin(uTime * 0.7);
    vec2 px = blur / uResolution;
    vec2 flowDir = vec2(sin(uTime * 0.6), cos(uTime * 0.5)) * 0.5;
    vec3 blurAccum = vec3(0.0);
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = warpedUV + flowDir * (float(i) + float(j)) * 0.4 * blur;
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    col = mix(col, blurAccum / 25.0, 0.2 * strength);

    // Final color enhancement: high contrast, saturation, and glowing
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 4.0); // Strong saturation boost
    col = pow(col, vec3(0.6)); // Deep contrast
    col = clamp(col, 0.0, 1.0);

    fragColor = vec4(col, 1.0);
}
