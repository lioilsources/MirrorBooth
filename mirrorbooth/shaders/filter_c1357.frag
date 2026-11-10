#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return vec3(
        0.9 + 0.5 * sin(t * 2.1 + 0.3),
        0.4 + 0.6 * sin(t * 2.1 + 2.6),
        1.3 + 0.5 * sin(t * 2.1 + 4.9)
    ) * 3.5;
}

vec2 rotate(vec2 v, float a) {
    float s = sin(a), c = cos(a);
    return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

float smoothEdge(float x) {
    return smoothstep(0.1, 0.9, x);
}

float kaleidoFlow(vec2 uv, float t, float symmetry, float radius, out vec2 outUV) {
    float angle = 2.0 * 3.14159 / symmetry;
    float a = atan(uv.y, uv.x) + t * 1.1;
    float c = floor(a / angle);
    float d = mod(a, angle);
    float r = length(uv);
    float theta = d / angle;
    float k = (1.0 - theta) * 0.7 + theta * 0.3;

    // Dynamic flow modulation with time and radial position
    float flow = 0.6 * sin(d * 9.0 + t * 1.8) * (1.0 - 0.5 * sin(r * 5.0 + t * 1.2));
    float wave = 0.5 * sin(r * 7.0 + t * 1.4) * (1.0 - 0.8 * sin(t * 1.0));
    float distortion = flow * (1.0 + wave);

    float newR = r * (1.0 - distortion * k);
    float newAngle = d + 0.6 * sin(t * 1.2 + d * 7.0);
    vec2 newUV = vec2(cos(newAngle), sin(newAngle)) * newR;

    outUV = newUV;
    return newR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;
    float t = uTime * 0.9;

    // Base symmetry and radius with smooth modulation
    float symmetry = 8.0 + 6.0 * sin(t * 0.6);
    float radius = 0.3 + 0.2 * sin(t * 0.4);
    float distToFace = length(uv - center);
    float faceMask = exp(-pow(distToFace / uFaceScale, 2.0) * 6.0);

    // Apply kaleidoscopic warping with dynamic flow
    vec2 centered = uv - center;
    vec2 warpedUV;
    float newR = kaleidoFlow(centered, t, symmetry, radius, warpedUV);
    float scale = 1.0 + 1.3 * (1.0 - faceMask) * (1.0 + 0.8 * sin(t * 0.7));
    vec2 finalUV = center + (warpedUV * (newR / length(centered))) * scale;

    // Sample the warped texture
    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    // Neon wave overlay: electric cyan, magenta, and violet pulses
    float wave1 = sin(uv.x * 22.0 + t * 4.0) * 0.5 + 0.5;
    float wave2 = cos(uv.y * 20.0 + t * 3.8) * 0.5 + 0.5;
    float wave3 = sin(uv.x * 14.0 + uv.y * 12.0 + t * 3.6) * 0.5 + 0.5;
    vec3 neonOverlay = vec3(wave1, wave2, wave3) * 2.5;
    col = mix(col, neonOverlay, 0.7 * faceMask);

    // Pulsing central glow with radial expansion
    vec3 pulseGlow = neonGlow(t * 1.3);
    float pulseIntensity = 0.7 + 0.6 * sin(t * 2.0);
    float radialGlow = 1.0 - smoothstep(0.0, 0.15, distToFace / uFaceScale);
    col = mix(col, pulseGlow, pulseIntensity * radialGlow * 0.8);

    // Chromatic swirl: flowing color shifts with motion
    float chroma = 0.02 * sin(t * 3.5 + uv.x * 18.0 + uv.y * 15.0);
    vec3 chromatic = vec3(
        texture(uTexture, finalUV + vec2(chroma, 0.0)).r,
        texture(uTexture, finalUV + vec2(-chroma * 0.7, 0.0)).g,
        texture(uTexture, finalUV + vec2(0.0, chroma * 0.6)).b
    );
    col = mix(col, chromatic, 0.5 * faceMask);

    // Dynamic motion blur with radial jitter
    float blur = 0.012 + 0.02 * sin(t * 0.8);
    vec2 px = blur / uResolution;
    vec2 offsetDir = vec2(sin(t * 0.6), cos(t * 0.9)) * 0.6;
    vec3 blurAccum = vec3(0.0);
    for (int i = -4; i <= 4; i++) {
        for (int j = -4; j <= 4; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = finalUV + offsetDir * (float(i) + float(j)) * 0.4 * blur;
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    col = mix(col, blurAccum / 81.0, 0.4);

    // Enhanced saturation and tone curve for cinematic neon
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 3.8);
    col = pow(col, vec3(0.58));

    // Subtle edge glow synced with motion
    vec2 dxy = vec2(1.0, 0.0) * (1.0 / uResolution);
    float edge = abs(texture(uTexture, finalUV).r - texture(uTexture, finalUV + dxy).r);
    edge += abs(texture(uTexture, finalUV).g - texture(uTexture, finalUV + dxy).g);
    edge += abs(texture(uTexture, finalUV).b - texture(uTexture, finalUV + dxy).b);
    float edgeIntensity = 0.9 + 0.5 * sin(t * 2.5);
    col += vec3(0.3, 0.6, 1.2) * edge * 0.5 * edgeIntensity;

    // Final flare and bloom with animated radial spread
    float flare = 0.8 + 0.5 * sin(t * 2.3 + distToFace * 7.0);
    col += vec3(0.2, 0.4, 1.0) * flare * smoothEdge(distToFace * 0.8);

    // Soft vignette with luminance-based dimming
    float vignette = 1.0 - 2.0 * distToFace * distToFace;
    col *= mix(0.9, 1.1, smoothstep(0.0, 0.5, distToFace));

    // Final clamp and output
    col = clamp(col, 0.0, 1.0);
    fragColor = vec4(col, 1.0);
}
