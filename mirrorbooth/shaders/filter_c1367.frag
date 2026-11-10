#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return vec3(
        0.9 + 0.5 * sin(t * 2.1 + 0.1),
        0.3 + 0.7 * sin(t * 2.1 + 2.5),
        1.1 + 0.6 * sin(t * 2.1 + 4.7)
    ) * 3.8;
}

vec3 flowField(vec2 uv, float t) {
    float wave1 = sin(uv.x * 18.0 + t * 1.8) * 0.5 + 0.5;
    float wave2 = cos(uv.y * 16.0 + t * 1.5) * 0.5 + 0.5;
    float wave3 = sin(uv.x * 12.0 + uv.y * 14.0 + t * 1.2) * 0.5 + 0.5;
    float wave4 = sin(uv.x * 20.0 + t * 1.0) * 0.5 + 0.5;
    return vec3(wave1, wave2, wave3) * (1.0 + wave4 * 0.6) * 2.5;
}

float kaleidoscopeWarp(vec2 uv, float segments, float t, float radius, out vec2 outUV) {
    vec2 centered = uv - 0.5;
    float r = length(centered);
    float a = atan(centered.y, centered.x) + t * 0.8;
    float angle = 2.0 * 3.14159 / segments;
    float seg = floor(a / angle);
    float rem = mod(a, angle);
    float newAngle = rem + (angle * (1.0 - (mod(seg + 1.0, segments) / segments)));
    
    // Flow distortion based on radial and angular position
    float flow = 0.5 * sin(rem * 12.0 + t * 2.3) * (1.0 - 0.5 * sin(r * 9.0 + t * 1.5));
    float wave = 0.4 * sin(r * 10.0 + t * 1.6) * (1.0 - 0.6 * sin(t * 1.3));
    float distortion = flow * (1.0 + wave);
    
    float newR = r * (1.0 - distortion * 0.35);
    vec2 newUV = vec2(cos(newAngle), sin(newAngle)) * newR;
    outUV = 0.5 + newUV;
    return newR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 faceCenter = uFaceCenter;
    float faceDist = length(uv - faceCenter);
    float faceMask = smoothstep(0.0, uFaceScale * 0.7, faceDist);

    // Dynamic kaleidoscopic symmetry with flowing distortion
    float segments = 14.0 + 12.0 * sin(uTime * 0.5);
    float radius = 0.3 + 0.2 * sin(uTime * 0.3);
    vec2 warpedUV;
    float newR = kaleidoscopeWarp(uv, segments, uTime, radius, warpedUV);

    // Flowing motion and centering effect
    vec2 flowOffset = vec2(
        sin(uTime * 1.0 + uv.y * 8.0) * 0.012,
        cos(uTime * 1.2 + uv.x * 8.0) * 0.012
    );
    vec2 finalUV = warpedUV + flowOffset;

    // Sample warped texture
    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    // Add flowing neon wave overlay across the entire frame
    vec3 wave = flowField(uv, uTime);
    col = mix(col, wave, 0.6 * (1.0 - faceMask));

    // Intense neon glow from center outward
    vec3 glow = neonGlow(uTime);
    col = mix(col, glow, 0.8 * (1.0 - faceMask));

    // Swirling edge glow with pulsing ripple
    float edgeGlow = 0.7 * (1.0 - faceMask) * smoothstep(0.0, 0.08, faceDist / (uFaceScale * 0.7));
    float ripple = 0.4 * sin(faceDist * 7.0 + uTime * 1.9) * (1.0 - 0.7 * faceMask);
    col = mix(col, vec3(1.3, 0.6, 1.9), edgeGlow * (1.0 + ripple));

    // Enhanced motion blur with radial phase shifting
    float blur = 0.01 + 0.015 * sin(uTime * 1.1);
    vec2 px = blur / uResolution;
    vec2 dir = vec2(sin(uTime * 0.7), cos(uTime * 0.9)) * 0.4;
    vec3 blurAccum = vec3(0.0);
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = finalUV + dir * (float(i) + float(j)) * 0.3 * 0.08;
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    col = mix(col, blurAccum / 25.0, 0.35);

    // High saturation and tone curve
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 4.5);
    col = pow(clamp(col, 0.0, 1.0), vec3(0.58));

    // Dynamic chromatic aberration with swirling dispersion
    float aberration = 0.02 * sin(uTime * 3.8 + 4.0 * uv.x + 2.0 * uv.y + 1.7 * uTime);
    col.r = texture(uTexture, uv + vec2(aberration, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-aberration * 0.6, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, aberration * 0.4)).b;

    // Final color boost and bloom
    col = clamp(col, 0.0, 1.0);
    col += 0.4 * vec3(1.4, 1.2, 1.7);

    fragColor = vec4(col, 1.0);
}
