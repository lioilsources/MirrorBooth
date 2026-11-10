#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return 0.5 + 0.5 * vec3(
        sin(t * 1.3 + 0.0) * 0.5 + 0.5,
        sin(t * 1.3 + 2.1) * 0.5 + 0.5,
        sin(t * 1.3 + 4.2) * 0.5 + 0.5
    );
}

vec3 flowWave(vec2 uv, float t) {
    float wave = sin(t * 0.7 + uv.x * 5.0 + uv.y * 3.0) * 0.5 + 0.5;
    return mix(vec3(0.0, 0.3, 0.8), vec3(0.8, 0.0, 0.6), wave) * 0.7;
}

float kaleidoDistortion(vec2 uv, float n, float t) {
    float angle = 2.0 * 3.14159 / n;
    float a = atan(uv.y, uv.x) + t * 0.15;
    float c = floor(a / angle);
    float d = mod(a, angle);
    float r = length(uv);
    float k = 0.2 * sin(d * 4.0 + t * 0.5) * (1.0 - 0.5 * sin(d * 2.0));
    return r * (1.0 + k * (0.3 + 0.2 * sin(t * 0.3)));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;

    // Smoothly animate kaleidoscope symmetry and flow
    float timeOffset = uTime * 0.7;
    float n = 8.0 + 2.0 * sin(uTime * 0.6); // 8 to 10 fold symmetry
    float radius = 0.4 + 0.2 * sin(uTime * 0.4);
    
    // Offset UV to center on face
    vec2 centered = uv - center;
    float distToFace = length(centered);

    // Mask to apply effect only near face
    float mask = smoothstep(0.0, uFaceScale * 0.6, distToFace);
    float intensity = 0.8 + 0.2 * sin(uTime * 0.3);

    // Apply kaleidoscope warping with flowing distortion
    float angle = 2.0 * 3.14159 / n;
    float a = atan(centered.y, centered.x) + timeOffset;
    float c = floor(a / angle);
    float d = mod(a, angle);
    float r = length(centered);
    float newR = kaleidoDistortion(centered, n, timeOffset);
    float theta = d / angle;
    float k = (1.0 - theta) * 0.7 + theta * 0.3;
    float scale = 1.0 + 0.5 * k * (1.0 - mask);

    vec2 warpedUV = center + (centered * (newR / r)) * scale;

    // Sample warped texture with edge clamping
    vec3 col = texture(uTexture, clamp(warpedUV, 0.0, 1.0)).rgb;

    // Add flowing neon color waves
    vec3 waveColor = flowWave(uv, uTime * 1.1);
    col = mix(col, waveColor, 0.25 * mask);

    // Add vibrant neon glow with time-based color cycling
    vec3 glow = neonGlow(uTime * 1.4);
    col = mix(col, glow, 0.4 * (1.0 - mask));

    // Soft motion blur using 5x5 weighted sampling
    float blur = 0.01 + 0.01 * sin(uTime * 0.8);
    vec2 px = blur / uResolution;
    vec3 blurAccum = vec3(0.0);
    float wTotal = 0.0;
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec3 s = texture(uTexture, clamp(warpedUV + offset, 0.0, 1.0)).rgb;
            float dist = length(s - col);
            float w = exp(-dist * dist * 8.0);
            blurAccum += s * w;
            wTotal += w;
        }
    }
    col = mix(col, blurAccum / wTotal, 0.3);

    // Enhance saturation and brightness with glow
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 2.0);
    col = pow(col, vec3(0.65));

    // Final color: boost contrast and add edge glow
    col = mix(col, vec3(1.0), 0.2 * mask);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
