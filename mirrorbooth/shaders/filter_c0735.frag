#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return vec3(
        0.5 + 0.5 * sin(t * 1.3 + 0.0) * 0.5 + 0.5,
        0.5 + 0.5 * sin(t * 1.3 + 2.1) * 0.5 + 0.5,
        0.5 + 0.5 * sin(t * 1.3 + 4.3) * 0.5 + 0.5
    ) * 2.0;
}

vec3 flowColor(vec2 uv, float t) {
    float wave1 = sin(uv.x * 8.0 + t * 0.9) * 0.5 + 0.5;
    float wave2 = cos(uv.y * 8.0 + t * 0.7) * 0.5 + 0.5;
    float wave3 = sin(uv.x * 5.0 + uv.y * 4.0 + t * 0.6) * 0.5 + 0.5;
    return vec3(wave1, wave2, wave3) * 1.8;
}

vec3 radialGlow(vec2 uv, vec2 center, float t) {
    float dist = length(uv - center);
    float pulse = 0.5 + 0.5 * sin(t * 0.4);
    float glow = smoothstep(0.1, 0.03, dist * 1.5 - pulse * 0.2);
    return vec3(1.0, 0.5, 1.0) * glow * 3.0;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;

    float t = uTime * 0.8;
    float symmetry = 16.0 + 8.0 * sin(t * 0.3); // 16 to 24 fold kaleidoscope
    float radius = 0.3 + 0.2 * sin(t * 0.2); // Pulsing inner radius

    vec2 centered = uv - center;
    float distToFace = length(centered);
    float mask = smoothstep(0.0, uFaceScale * 0.5, distToFace);

    // Kaleidoscopic rotation with dynamic symmetry and flow
    float angle = 2.0 * 3.14159 / symmetry;
    float a = atan(centered.y, centered.x) + t * 0.7;
    float c = floor(a / angle);
    float d = mod(a, angle);
    float r = length(centered);
    float theta = d / angle;
    float k = (1.0 - theta) * 0.6 + theta * 0.4;
    float distortion = 0.25 * sin(d * 6.0 + t * 0.5) * (1.0 - mask);
    float newR = r * (1.0 - distortion * k);

    // Add subtle motion drift based on time and face scale
    float scale = 1.0 + 0.8 * (1.0 - mask) * (1.0 + 0.4 * sin(t * 0.6));
    vec2 warpedUV = center + (centered * (newR / r)) * scale;

    // Sample with jitter and edge clamping
    vec3 col = texture(uTexture, clamp(warpedUV, 0.0, 1.0)).rgb;

    // Add pulsing neon glow centered on face
    vec3 glow = neonGlow(t);
    col = mix(col, glow, 0.7 * (1.0 - mask));

    // Flowing color waves with motion and face focus
    vec3 wave = flowColor(uv, t);
    col = mix(col, wave, 0.4 * mask);

    // Add radial glow around face center
    vec3 faceGlow = radialGlow(uv, center, t);
    col = mix(col, faceGlow, 0.3 * mask);

    // Temporal blur with motion streak
    float blur = 0.012 + 0.006 * sin(t * 0.9);
    vec2 px = blur / uResolution;
    vec3 blurAccum = vec3(0.0);
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            blurAccum += texture(uTexture, clamp(warpedUV + offset, 0.0, 1.0)).rgb;
        }
    }
    col = mix(col, blurAccum / 25.0, 0.25);

    // Enhance vibrancy and contrast with film-like tone
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 2.5);
    col = pow(col, vec3(0.55));

    // Add soft edge highlight with neon hue
    float edgeGlow = 0.3 * (1.0 - mask) * smoothstep(0.0, 0.04, distToFace / uFaceScale);
    col = mix(col, vec3(0.9, 0.6, 1.2), edgeGlow);

    // Final dynamic neon tint shift
    float shift = 0.2 * sin(t * 0.6);
    col = mix(col, vec3(1.0, 0.4, 1.0), 0.15 * shift);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
