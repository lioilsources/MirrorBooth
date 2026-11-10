#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonGlow(float t) {
    return vec3(
        0.9 + 0.6 * sin(t * 2.3 + 0.2),
        0.2 + 0.8 * sin(t * 2.3 + 2.7),
        1.2 + 0.7 * sin(t * 2.3 + 4.9)
    ) * 4.0;
}

vec3 flowField(vec2 uv, float t) {
    float wave1 = sin(uv.x * 20.0 + t * 1.9) * 0.5 + 0.5;
    float wave2 = cos(uv.y * 18.0 + t * 1.6) * 0.5 + 0.5;
    float wave3 = sin(uv.x * 14.0 + uv.y * 16.0 + t * 1.3) * 0.5 + 0.5;
    float wave4 = sin(uv.x * 22.0 + t * 1.1) * 0.5 + 0.5;
    return vec3(wave1, wave2, wave3) * (1.0 + wave4 * 0.7) * 2.8;
}

float kaleidoscopeWarp(vec2 uv, float segments, float t, float radius, out vec2 outUV) {
    vec2 centered = uv - 0.5;
    float r = length(centered);
    float a = atan(centered.y, centered.x) + t * 0.7;
    float angle = 2.0 * 3.14159 / segments;
    float seg = floor(a / angle);
    float rem = mod(a, angle);
    
    // Swirling flow distortion based on angular and radial position
    float flow = 0.6 * sin(rem * 14.0 + t * 2.5) * (1.0 - 0.4 * sin(r * 10.0 + t * 1.7));
    float wave = 0.5 * sin(r * 12.0 + t * 1.8) * (1.0 - 0.5 * sin(t * 1.4));
    float distortion = flow * (1.0 + wave * 0.6);
    
    float newAngle = rem + (angle * (1.0 - (mod(seg + 1.0, segments) / segments))) + 
                     0.2 * sin(t * 1.6 + rem * 8.0) * (1.0 - 0.4 * sin(r * 7.0 + t * 1.2));
    
    float newR = r * (1.0 - distortion * 0.4);
    vec2 newUV = vec2(cos(newAngle), sin(newAngle)) * newR;
    outUV = 0.5 + newUV;
    return newR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 faceCenter = uFaceCenter;
    float faceDist = length(uv - faceCenter);
    float faceMask = smoothstep(0.0, uFaceScale * 0.6, faceDist);

    // Dynamic kaleidoscopic symmetry with swirling flow
    float segments = 16.0 + 10.0 * sin(uTime * 0.4);
    float radius = 0.35 + 0.15 * sin(uTime * 0.28);
    vec2 warpedUV;
    float newR = kaleidoscopeWarp(uv, segments, uTime, radius, warpedUV);

    // Swirling motion blur with radial phase shifting
    vec2 flowOffset = vec2(
        sin(uTime * 1.1 + uv.y * 10.0) * 0.014,
        cos(uTime * 1.3 + uv.x * 10.0) * 0.014
    );
    vec2 finalUV = warpedUV + flowOffset;

    // Sample warped texture
    vec3 col = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;

    // Add flowing neon wave overlay across entire frame
    vec3 wave = flowField(uv, uTime);
    col = mix(col, wave, 0.7 * (1.0 - faceMask));

    // Intense neon bloom from center outward
    vec3 glow = neonGlow(uTime);
    col = mix(col, glow, 0.9 * (1.0 - faceMask));

    // Swirling edge glow with pulsing ripple
    float edgeGlow = 0.8 * (1.0 - faceMask) * smoothstep(0.0, 0.07, faceDist / (uFaceScale * 0.6));
    float ripple = 0.5 * sin(faceDist * 8.0 + uTime * 2.0) * (1.0 - 0.6 * faceMask);
    col = mix(col, vec3(1.5, 0.5, 2.0), edgeGlow * (1.0 + ripple));

    // Enhanced motion blur with dynamic radial dispersion
    float blur = 0.01 + 0.02 * sin(uTime * 1.2);
    vec2 px = blur / uResolution;
    vec2 dir = vec2(sin(uTime * 0.8), cos(uTime * 1.0)) * 0.5;
    vec3 blurAccum = vec3(0.0);
    for (int i = -3; i <= 3; i++) {
        for (int j = -3; j <= 3; j++) {
            vec2 offset = vec2(float(i), float(j)) * px;
            vec2 sampleUV = finalUV + dir * (float(i) + float(j)) * 0.3 * 0.1;
            blurAccum += texture(uTexture, clamp(sampleUV, 0.0, 1.0)).rgb;
        }
    }
    col = mix(col, blurAccum / 49.0, 0.4);

    // High saturation and dynamic tone curve
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    col = mix(gray, col, 5.0);
    col = pow(clamp(col, 0.0, 1.0), vec3(0.55));

    // Dynamic chromatic aberration with swirling dispersion
    float aberration = 0.022 * sin(uTime * 4.0 + 4.5 * uv.x + 2.5 * uv.y + 2.0 * uTime);
    col.r = texture(uTexture, uv + vec2(aberration, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-aberration * 0.5, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, aberration * 0.3)).b;

    // Final color boost and neon bloom
    col = clamp(col, 0.0, 1.0);
    col += 0.5 * vec3(1.6, 1.3, 2.0);

    fragColor = vec4(col, 1.0);
}
