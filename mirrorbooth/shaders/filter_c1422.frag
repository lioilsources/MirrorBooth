#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return vec3(
        0.9 + 0.5 * sin(t * 2.0 + 0.3),
        0.4 + 0.6 * sin(t * 2.0 + 2.7),
        1.0 + 0.4 * sin(t * 2.0 + 4.9)
    ) * 4.0;
}

vec3 flowWaves(vec2 uv, float t) {
    float wave1 = sin(uv.x * 18.0 + t * 1.7) * 0.5 + 0.5;
    float wave2 = cos(uv.y * 16.0 + t * 1.4) * 0.5 + 0.5;
    float wave3 = sin(uv.x * 12.0 + uv.y * 14.0 + t * 1.1) * 0.5 + 0.5;
    return vec3(wave1, wave2, wave3) * 2.5;
}

float kaleidoTransform(vec2 uv, float n, float t, float radius, out vec2 outUV) {
    float angle = 2.0 * 3.14159 / n;
    float a = atan(uv.y, uv.x) + t * 0.85;
    float c = floor(a / angle);
    float d = mod(a, angle);
    float r = length(uv);
    float theta = d / angle;
    float k = (1.0 - theta) * 0.7 + theta * 0.3;

    float flow = 0.6 * sin(d * 10.0 + t * 1.8) * (1.0 - 0.5 * sin(r * 6.0 + t * 1.2));
    float wave = 0.5 * sin(r * 8.0 + t * 1.4) * (1.0 - 0.6 * sin(t * 1.0));
    float distortion = flow * (1.0 + wave);

    float newR = r * (1.0 - distortion * k);
    float newAngle = d + 0.6 * sin(t * 1.2 + d * 8.0);
    vec2 newUV = vec2(cos(newAngle), sin(newAngle)) * newR;

    outUV = newUV;
    return newR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;

    float t = uTime * 1.0;
    float symmetry = 12.0 + 18.0 * sin(t * 0.5);
    float radius = 0.25 + 0.3 * sin(t * 0.35);
    float mask = smoothstep(0.0, uFaceScale * 0.7, length(uv - center));

    vec2 centered = uv - center;
    float distToFace = length(centered);

    // Apply kaleidoscopic warping with smooth flowing motion
    vec2 warpedUV;
    float newR = kaleidoTransform(centered, symmetry, t, radius, warpedUV);
    float scale = 1.0 + 2.0 * (1.0 - mask) * (1.0 + 0.9 * sin(t * 0.9));
    vec2 finalUV = center + (warpedUV * (newR / length(centered))) * scale;

    // Sample warped texture
    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    // Add flowing neon waves across the entire frame
    vec3 wave = flowWaves(uv, t);
    col = mix(col, wave, 0.8 * mask);

    // Intense pulsing neon glow from center with radial gradient
    vec3 glow = neonGlow(t * 1.1);
    float glowStrength = 0.9 * (1.0 - mask);
    col = mix(col, glow, glowStrength);

    // Swirling edge glow with dynamic swirl
    float edgeGlow = 0.7 * (1.0 - mask) * smoothstep(0.0, 0.08, distToFace / uFaceScale);
    float swirl = 0.4 * sin(t * 1.6 + 5.0 * distToFace);
    col = mix(col, vec3(1.0, 0.6, 1.7) * (1.0 + swirl), edgeGlow);

    // Subtle radial motion blur with swirling phase
    float blur = 0.01 + 0.02 * sin(t * 1.0);
    vec2 px = blur / uResolution;
    vec2 offsetDir = vec2(sin(t * 0.9), cos(t * 0.8)) * 0.5;
    vec3 blurAccum = vec3(0.0);
    for (int i = -3; i <= 3; i++) {
        for (int j = -3; j <= 3; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = finalUV + offsetDir * (float(i) + float(j)) * 0.3 * blur;
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    col = mix(col, blurAccum / 49.0, 0.35);

    // Enhance saturation and apply vibrant tone curve
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 5.0);
    col = pow(clamp(col, 0.0, 1.0), vec3(0.45));

    // Dynamic neon tint with deep color shifts
    float pulse = 1.0 + 0.8 * sin(t * 2.4);
    col = mix(col, neonGlow(t * 1.4), pulse * 0.6);

    // Chromatic aberration with swirling dispersion
    float aberration = 0.025 * sin(t * 3.7 + 6.0 * uv.x + 4.0 * uv.y + 2.0 * t);
    col.r = texture(uTexture, uv + vec2(aberration, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-aberration * 0.6, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, aberration * 0.4)).b;

    // Final bloom and glow
    col = clamp(col, 0.0, 1.0);
    col += 0.4 * vec3(1.5, 1.2, 1.8);

    fragColor = vec4(col, 1.0);
}
