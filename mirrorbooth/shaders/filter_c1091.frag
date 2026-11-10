#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return vec3(
        0.9 + 0.5 * sin(t * 1.7 + 0.1),
        0.4 + 0.6 * sin(t * 1.7 + 2.4),
        1.1 + 0.4 * sin(t * 1.7 + 4.6)
    ) * 3.0;
}

vec2 rotate(vec2 v, float a) {
    float s = sin(a), c = cos(a);
    return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

float smoothEdge(float x) {
    return smoothstep(0.1, 0.9, x);
}

float kaleidoTransform(vec2 uv, float n, float t, float radius, out vec2 outUV) {
    float angle = 2.0 * 3.14159 / n;
    float a = atan(uv.y, uv.x) + t * 0.9;
    float c = floor(a / angle);
    float d = mod(a, angle);
    float r = length(uv);
    float theta = d / angle;
    float k = (1.0 - theta) * 0.7 + theta * 0.3;

    float flow = 0.6 * sin(d * 7.0 + t * 1.8) * (1.0 - 0.5 * sin(r * 4.0 + t * 1.2));
    float wave = 0.3 * sin(r * 8.0 + t * 1.4) * (1.0 - 0.6 * sin(t * 0.8));
    float distortion = flow * (1.0 + wave);

    float newR = r * (1.0 - distortion * k);
    float newAngle = d + 0.6 * sin(t * 1.2 + d * 5.0);
    vec2 newUV = vec2(cos(newAngle), sin(newAngle)) * newR;

    outUV = newUV;
    return newR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;
    float t = uTime * 0.9;
    float faceDist = length(uv - center);
    float mask = smoothstep(0.0, uFaceScale * 0.8, faceDist);

    // Dynamic kaleidoscopic symmetry with swirling flow
    vec2 centered = uv - center;
    float symmetry = 10.0 + 12.0 * sin(t * 0.4);
    float radius = 0.3 + 0.25 * sin(t * 0.3);
    vec2 warpedUV;
    float newR = kaleidoTransform(centered, symmetry, t, radius, warpedUV);
    vec2 finalUV = center + (warpedUV * (newR / length(centered))) * (1.0 + 0.8 * sin(t * 0.6));

    // Base color from warped texture
    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    // Neon pulsing waves across screen with layered motion
    float wave1 = sin(uv.x * 20.0 + t * 2.1) * 0.5 + 0.5;
    float wave2 = cos(uv.y * 18.0 + t * 1.9) * 0.5 + 0.5;
    float wave3 = sin(uv.x * 14.0 + uv.y * 12.0 + t * 1.6) * 0.5 + 0.5;
    vec3 neonWaves = vec3(wave1, wave2, wave3) * 2.0;
    col = mix(col, neonWaves, 0.6 * mask);

    // Intense center glow with motion blur and radial pulsing
    vec3 glow = neonGlow(t);
    float pulse = 0.7 + 0.6 * sin(t * 2.3);
    col = mix(col, glow, 0.8 * (1.0 - mask) * pulse);

    // Soft glowing halo with swirling chromatic ripple
    float swirl = sin(t * 3.0 + faceDist * 10.0) * 0.12;
    vec2 swirlDir = rotate(vec2(sin(t * 1.3), cos(t * 1.1)), swirl);
    vec2 rippleUV = finalUV + swirlDir * 0.015;
    vec3 ripple = texture(uTexture, rippleUV).rgb;
    col = mix(col, ripple, 0.3 * (1.0 - mask));

    // Dynamic chromatic aberration with flowing depth
    float aberration = 0.02 * sin(t * 4.0 + uv.x * 12.0 + uv.y * 10.0);
    col.r = texture(uTexture, uv + vec2(aberration, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-aberration * 0.7, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, aberration * 0.5)).b;

    // Motion-blurred glow with radial diffusion
    float blur = 0.01 + 0.012 * sin(t * 0.8);
    vec2 px = blur / uResolution;
    vec2 offsetDir = vec2(sin(t * 0.9), cos(t * 0.7)) * 0.6;
    vec3 blurAccum = vec3(0.0);
    for (int i = -4; i <= 4; i++) {
        for (int j = -4; j <= 4; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = finalUV + offsetDir * (float(i) + float(j)) * 0.2 * blur;
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    col = mix(col, blurAccum / 81.0, 0.3);

    // Vibrant tone curve and saturation boost
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 4.0);
    col = pow(col, vec3(0.5));

    // Final neon tint with phase shift
    float pulse2 = 0.9 + 0.5 * sin(t * 2.0);
    col = mix(col, neonGlow(t * 1.3), pulse2 * 0.5);

    // Subtle edge glow with motion-synced intensity
    vec2 dxy = vec2(1.0, 0.0) * (1.0 / uResolution);
    float edge = abs(texture(uTexture, finalUV).r - texture(uTexture, finalUV + dxy).r);
    edge += abs(texture(uTexture, finalUV).g - texture(uTexture, finalUV + dxy).g);
    edge += abs(texture(uTexture, finalUV).b - texture(uTexture, finalUV + dxy).b);
    float edgeIntensity = 0.6 + 0.4 * sin(t * 3.5);
    col += vec3(0.4, 0.7, 1.4) * edge * 0.4 * edgeIntensity;

    // Final bloom and radial flare
    float flare = 0.9 + 0.3 * sin(t * 2.2 + faceDist * 6.0);
    col += vec3(0.3, 0.5, 1.0) * flare * smoothEdge(faceDist * 1.2);

    // Vignette with luminance-based softness
    float vignette = 1.0 - 2.0 * faceDist * faceDist;
    col *= mix(0.85, 1.1, smoothstep(0.0, 0.4, faceDist));

    col = clamp(col, 0.0, 1.0);
    fragColor = vec4(col, 1.0);
}
