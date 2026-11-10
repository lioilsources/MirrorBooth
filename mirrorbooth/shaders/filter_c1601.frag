#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonPulse(float t) {
    return vec3(
        0.9 + 0.5 * sin(t * 2.3 + 0.2),
        0.3 + 0.7 * sin(t * 2.3 + 2.5),
        1.2 + 0.6 * sin(t * 2.3 + 4.8)
    ) * 3.5;
}

vec3 flowField(vec2 uv, float t) {
    float wave1 = sin(uv.x * 14.0 + t * 1.6) * 0.5 + 0.5;
    float wave2 = cos(uv.y * 12.0 + t * 1.3) * 0.5 + 0.5;
    float wave3 = sin(uv.x * 10.0 + uv.y * 16.0 + t * 1.0) * 0.5 + 0.5;
    return vec3(wave1, wave2, wave3) * 2.0;
}

float kaleidoWarp(vec2 uv, float n, float t, float radius, out vec2 outUV) {
    float angle = 2.0 * 3.14159 / n;
    float a = atan(uv.y, uv.x) + t * 0.9;
    float c = floor(a / angle);
    float d = mod(a, angle);
    float r = length(uv);
    float theta = d / angle;
    float k = (1.0 - theta) * 0.8 + theta * 0.2;

    float flow = 0.7 * sin(d * 12.0 + t * 1.9) * (1.0 - 0.4 * sin(r * 7.0 + t * 1.3));
    float wave = 0.4 * sin(r * 9.0 + t * 1.5) * (1.0 - 0.5 * sin(t * 1.1));
    float distortion = flow * (1.0 + wave);

    float newR = r * (1.0 - distortion * k);
    float newAngle = d + 0.5 * sin(t * 1.3 + d * 9.0);
    vec2 newUV = vec2(cos(newAngle), sin(newAngle)) * newR;

    outUV = newUV;
    return newR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;

    float t = uTime * 1.2;
    float symmetry = 8.0 + 10.0 * sin(t * 0.6);
    float radius = 0.2 + 0.35 * sin(t * 0.4);
    float mask = smoothstep(0.0, uFaceScale * 0.8, length(uv - center));

    vec2 centered = uv - center;
    float distToFace = length(centered);

    vec2 warpedUV;
    float newR = kaleidoWarp(centered, symmetry, t, radius, warpedUV);
    float scale = 1.0 + 1.8 * (1.0 - mask) * (1.0 + 0.7 * sin(t * 1.0));
    vec2 finalUV = center + (warpedUV * (newR / length(centered))) * scale;

    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    // Dynamic neon wave overlay with flowing color pulses
    vec3 wave = flowField(uv, t);
    col = mix(col, wave, 0.9 * mask);

    // Intense pulsing radial glow from face center
    vec3 glow = neonPulse(t * 1.2);
    float glowStrength = 1.0 * (1.0 - mask);
    col = mix(col, glow, glowStrength);

    // Swirling edge glow with time-varying swirl and intensity
    float edgeGlow = 0.8 * (1.0 - mask) * smoothstep(0.0, 0.07, distToFace / uFaceScale);
    float swirl = 0.5 * sin(t * 1.7 + 4.0 * distToFace);
    col = mix(col, vec3(1.0, 0.5, 1.6) * (1.0 + swirl), edgeGlow);

    // Subtle radial motion blur with swirling phase
    float blur = 0.01 + 0.02 * sin(t * 1.1);
    vec2 px = blur / uResolution;
    vec2 offsetDir = vec2(sin(t * 0.8), cos(t * 0.9)) * 0.4;
    vec3 blurAccum = vec3(0.0);
    for (int i = -4; i <= 4; i++) {
        for (int j = -4; j <= 4; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = finalUV + offsetDir * (float(i) + float(j)) * 0.25 * blur;
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    col = mix(col, blurAccum / 81.0, 0.3);

    // Enhance saturation and apply vibrant tone curve
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 6.0);
    col = pow(clamp(col, 0.0, 1.0), vec3(0.4));

    // Dynamic neon tint with deep, shifting hues
    float pulse = 1.0 + 0.9 * sin(t * 2.6);
    col = mix(col, neonPulse(t * 1.5), pulse * 0.7);

    // Chromatic aberration with swirling dispersion
    float aberration = 0.02 * sin(t * 4.0 + 5.0 * uv.x + 3.0 * uv.y + 1.5 * t);
    col.r = texture(uTexture, uv + vec2(aberration, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-aberration * 0.5, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, aberration * 0.3)).b;

    // Final bloom and glow
    col = clamp(col, 0.0, 1.0);
    col += 0.5 * vec3(1.6, 1.3, 2.0);

    // Soft vignette with luminance-based glow and dynamic depth
    float vignette = 1.0 - 2.0 * distToFace * distToFace;
    col *= mix(0.9, 1.1, smoothstep(0.0, 0.6, distToFace));

    // Subtle edge glow on high-contrast areas with synced motion
    vec2 dxy = vec2(1.0, 0.0) * (1.0 / uResolution);
    float edge = abs(texture(uTexture, finalUV).r - texture(uTexture, finalUV + dxy).r);
    edge += abs(texture(uTexture, finalUV).g - texture(uTexture, finalUV + dxy).g);
    edge += abs(texture(uTexture, finalUV).b - texture(uTexture, finalUV + dxy).b);
    float edgeIntensity = 0.9 + 0.5 * sin(t * 3.7);
    col += vec3(0.3, 0.6, 1.2) * edge * 0.3 * edgeIntensity;

    // Final animated radial flare with pulse sync and glow
    float flare = 1.0 + 0.4 * sin(t * 2.5 + distToFace * 5.0);
    col += vec3(0.2, 0.4, 1.0) * flare * smoothstep(0.0, 0.7, distToFace);

    fragColor = vec4(col, 1.0);
}
