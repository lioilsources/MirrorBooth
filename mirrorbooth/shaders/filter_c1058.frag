#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return vec3(
        0.9 + 0.5 * sin(t * 1.7 + 0.4),
        0.4 + 0.6 * sin(t * 1.7 + 2.7),
        1.3 + 0.4 * sin(t * 1.7 + 5.0)
    ) * 3.0;
}

vec3 swirlFlow(vec2 uv, float t) {
    float r = length(uv - 0.5);
    float a = atan(uv.y - 0.5, uv.x - 0.5);
    float swirl = 0.3 * sin(t * 1.5 + r * 10.0 + a * 5.0) * (1.0 - 0.5 * r);
    float pulse = 0.4 * sin(t * 2.3 + 3.0 * r);
    return vec3(
        0.8 + 0.4 * sin(t * 1.8 + a * 3.0 + 0.3),
        0.3 + 0.7 * sin(t * 1.8 + a * 3.0 + 2.5),
        1.1 + 0.6 * sin(t * 1.8 + a * 3.0 + 4.8)
    ) * (1.0 + swirl + pulse);
}

float kaleidoTransform(vec2 uv, float n, float t, float radius, out vec2 outUV) {
    float angle = 2.0 * 3.14159 / n;
    float a = atan(uv.y, uv.x) + t * 0.9;
    float c = floor(a / angle);
    float d = mod(a, angle);
    float r = length(uv);
    float theta = d / angle;
    float k = (1.0 - theta) * 0.6 + theta * 0.4;

    // Dynamic wave modulation with time and radial frequency
    float wave = 0.3 * sin(r * 8.0 + t * 1.6) * (1.0 - 0.3 * sin(t * 0.8));
    float flow = 0.4 * sin(d * 10.0 + t * 1.8) * (1.0 - 0.4 * sin(r * 6.0 + t * 1.2));
    float distortion = wave * (1.0 + flow * 0.7);

    float newR = r * (1.0 - distortion * k);
    float newAngle = d + 0.6 * sin(t * 1.3 + d * 5.0);

    outUV = vec2(cos(newAngle), sin(newAngle)) * newR;
    return newR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;
    float t = uTime * 0.85;
    float faceDist = length(uv - center);
    float mask = smoothstep(0.0, uFaceScale * 0.7, faceDist);

    // Pulsing kaleidoscope symmetry: 16 to 24 folds
    float symmetry = 16.0 + 8.0 * sin(t * 0.4);
    float radius = 0.3 + 0.2 * sin(t * 0.25);
    vec2 centered = uv - center;
    float r = length(centered);

    vec2 warpedUV;
    float baseR = kaleidoTransform(centered, symmetry, t, radius, warpedUV);
    float scale = 1.0 + 1.3 * (1.0 - mask) * (0.6 + 0.4 * sin(t * 0.8));
    vec2 finalUV = center + (warpedUV * (baseR / r)) * scale;

    // Sample texture with edge clamping
    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    // Intense neon glow from center with pulsing intensity
    vec3 glow = neonGlow(t);
    col = mix(col, glow, 0.8 * (1.0 - mask));

    // Swirling neon flow field across screen
    vec3 swirl = swirlFlow(uv, t);
    col = mix(col, swirl, 0.5 * mask);

    // Chromatic aberration with motion and radial variation
    float abOffset = 0.02 * sin(t * 3.0 + 7.0 * uv.x + 5.0 * uv.y) * (1.0 - mask * 0.5);
    col.r = texture(uTexture, finalUV + vec2(abOffset, 0.0)).r;
    col.g = texture(uTexture, finalUV + vec2(-abOffset * 0.7, 0.0)).g;
    col.b = texture(uTexture, finalUV + vec2(0.0, abOffset * 0.5)).b;

    // Directional motion blur with radial jitter and high-frequency noise
    float blur = 0.012 + 0.018 * sin(t * 1.0);
    vec2 px = blur / uResolution;
    vec2 offsetDir = vec2(sin(t * 0.8), cos(t * 0.9)) * 0.6;
    vec3 blurAccum = vec3(0.0);
    for (int i = -4; i <= 4; i++) {
        for (int j = -4; j <= 4; j++) {
            if (i == 0 && j == 0) continue;
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = finalUV + offsetDir * (float(i) + float(j)) * 0.3 * blur;
            float weight = 1.0 - 0.1 * (abs(float(i)) + abs(float(j)));
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb * weight;
        }
    }
    col = mix(col, blurAccum / 63.0, 0.3);

    // Edge glow with face boundary emphasis and motion
    float edge = smoothstep(0.01, 0.05, faceDist / uFaceScale);
    col = mix(col, vec3(1.3, 0.7, 1.6), edge * 1.0);

    // Color grading: high saturation, tone curve, and radiant highlights
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 4.0);
    col = pow(col, vec3(0.58));

    // Dynamic radial flare with motion sync and depth
    float flare = 0.6 + 0.8 * sin(t * 2.2 + faceDist * 8.0);
    col += vec3(0.5, 1.0, 1.7) * flare * (1.0 - mask);

    // Soft vignette with luminance-based glow
    float vignette = 1.0 - 2.5 * faceDist * faceDist;
    col *= mix(0.9, 1.2, smoothstep(0.0, 0.3, faceDist));

    // Final bloom and neon punch
    col = clamp(col, 0.0, 1.0);
    col = mix(col, vec3(1.2, 1.1, 1.5), 0.18);

    fragColor = vec4(col, 1.0);
}
