#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 rotate(vec2 v, float a) {
    float s = sin(a), c = cos(a);
    return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

float smoothEdge(float x) {
    return smoothstep(0.1, 0.9, x);
}

vec3 neonPulse(float t) {
    return 0.5 + 0.5 * vec3(
        sin(t * 1.8 + 0.0) * 0.6 + 0.5,
        sin(t * 1.8 + 2.6) * 0.7 + 0.5,
        sin(t * 1.8 + 4.8) * 0.8 + 0.5
    ) * 4.0;
}

vec3 flowDistortion(vec2 uv, float t) {
    float f1 = sin(uv.x * 12.0 + t * 1.4) * 0.5 + 0.5;
    float f2 = cos(uv.y * 10.0 + t * 1.2) * 0.5 + 0.5;
    float f3 = sin(uv.x * 8.0 + uv.y * 7.0 + t * 1.0) * 0.5 + 0.5;
    return vec3(f1, f2, f3) * 1.8;
}

float kaleidoEffect(vec2 uv, vec2 center, float t, out vec2 outUV) {
    float angle = atan(uv.y - center.y, uv.x - center.x);
    float symmetry = 16.0 + 8.0 * sin(t * 0.2);
    float octAngle = floor(angle / (3.14159265 / symmetry) + symmetry) * (3.14159265 / symmetry);
    float r = length(uv - center);
    float distort = 0.1 * sin(t * 2.0 + r * 5.0) * (1.0 - 0.4 * sin(t * 0.7));
    float flow = 0.2 * sin(r * 3.0 + t * 1.5) * (1.0 + 0.3 * sin(t * 0.8));
    float totalDistort = distort * (1.0 + flow);
    float newR = r * (1.0 - totalDistort);
    float newAngle = octAngle + 0.2 * sin(t * 1.0 + r * 4.0);
    vec2 newUV = vec2(cos(newAngle), sin(newAngle)) * newR;
    outUV = center + newUV;
    return newR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;
    float t = uTime * 0.7;
    float distToFace = length(uv - center);
    float faceMask = smoothstep(0.0, uFaceScale * 0.6, distToFace);

    vec2 warpedUV;
    float r = kaleidoEffect(uv, center, t, warpedUV);

    // Face-aware warping with dynamic scale and soft blend
    float scale = 1.0 + 0.6 * (1.0 - faceMask) * (1.0 + 0.4 * sin(t * 0.6));
    vec2 finalUV = center + (warpedUV - center) * scale;

    // Base color from warped texture
    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    // Add flowing neon wave texture overlay
    vec3 wave = flowDistortion(uv, t);
    col = mix(col, wave, 0.6 * faceMask);

    // Intense neon glow with rhythmic pulse and color shift
    vec3 pulseGlow = neonPulse(t * 1.2);
    float pulse = 0.7 + 0.3 * sin(t * 2.3 + r * 6.0);
    col = mix(col, pulseGlow, 0.8 * pulse * (1.0 - faceMask));

    // Chromatic aberration with flowing motion
    float aberration = 0.012 * sin(t * 2.0 + uv.x * 10.0 + uv.y * 8.0);
    col.r = texture(uTexture, finalUV + vec2(aberration, 0.0)).r;
    col.g = texture(uTexture, finalUV + vec2(-aberration, 0.0)).g;
    col.b = texture(uTexture, finalUV + vec2(0.0, aberration)).b;

    // Motion-blurred glow with directional jitter
    float blur = 0.01 + 0.008 * sin(t * 0.9);
    vec2 px = blur / uResolution;
    vec2 offsetDir = vec2(sin(t * 0.7), cos(t * 0.6)) * 0.25;
    vec3 blurAccum = vec3(0.0);
    for (int i = -4; i <= 4; i++) {
        for (int j = -4; j <= 4; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = finalUV + offsetDir * (float(i) + float(j)) * 0.2 * blur;
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    blurAccum /= 81.0;
    col = mix(col, blurAccum, 0.3 * (1.0 - faceMask));

    // Enhance contrast and add glow
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 3.2);
    col = pow(col, vec3(0.5));

    // Dynamic halo glow around face with motion sync
    float halo = 0.8 * (1.0 - faceMask) * smoothstep(0.0, 0.04, distToFace / uFaceScale);
    col = mix(col, vec3(1.0, 0.5, 1.2), halo * 0.8);

    // Subtle edge glow with time-synchronized flicker
    vec2 dxy = vec2(1.0, 0.0) * (1.0 / uResolution);
    float edge = abs(texture(uTexture, finalUV).r - texture(uTexture, finalUV + dxy).r);
    edge += abs(texture(uTexture, finalUV).g - texture(uTexture, finalUV + dxy).g);
    edge += abs(texture(uTexture, finalUV).b - texture(uTexture, finalUV + dxy).b);
    float edgeIntensity = 0.6 + 0.4 * sin(t * 3.0);
    col += vec3(0.2, 0.5, 1.0) * edge * 0.4 * edgeIntensity;

    // Final glow flare with radial intensity
    float flare = 0.6 + 0.4 * sin(t * 2.0 + r * 7.0);
    col += vec3(0.1, 0.3, 0.7) * flare * smoothEdge(r * 0.9);

    // Soft vignette with luminance-based fade
    float vignette = 1.0 - 2.0 * r * r;
    col *= mix(0.9, 1.1, smoothstep(0.0, 0.4, r));

    // Final color grading: punchy, vibrant, and saturated
    col *= vec3(1.6, 1.4, 2.0);
    col = clamp(col, 0.0, 1.0);

    fragColor = vec4(col, 1.0);
}
