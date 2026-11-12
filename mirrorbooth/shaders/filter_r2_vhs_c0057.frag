#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float hash21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
vec2 hash22(vec2 p) { float n = hash21(p); return vec2(n, hash21(p + n + 17.1)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter / uResolution;
    float scale = uFaceScale;
    vec2 c = (uv - center) * scale;
    float aspect = uResolution.x / uResolution.y;
    c.x *= aspect;

    // Screen curvature: barrel distortion with radius-based warping
    float r = length(c);
    float bend = 0.15 * (1.0 - 0.5 * r);
    c *= (1.0 + bend * r);

    // Shadow mask: RGB stripe pattern
    float mask = mod(uv.y * 300.0 + uTime * 5.0, 3.0);
    float shadowMask = step(0.33, mask) - step(0.66, mask);

    // Chroma bleed: offset R and B channels
    vec2 offset = vec2(0.0015 * sin(uv.y * 200.0 + uTime * 2.0), 0.0);
    vec3 src = texture(uTexture, uv).rgb;
    vec3 rgb = vec3(
        texture(uTexture, uv + offset).r,
        texture(uTexture, uv).g,
        texture(uTexture, uv - offset).b
    );

    // Scanlines: vertical intensity modulation
    float scanline = 0.5 + 0.5 * cos(FlutterFragCoord().y * 30.0 + uTime * 15.0);
    rgb *= scanline;

    // Tracking error: subtle horizontal wobble
    float tracking = 0.005 * sin(uv.y * 100.0 + uTime * 10.0);
    vec2 warpedUv = uv + vec2(tracking, 0.0);
    vec3 color = texture(uTexture, warpedUv).rgb;

    // Final color with shadow mask and intensity
    vec3 final = color * (0.8 + 0.2 * shadowMask);
    final *= 0.9 + 0.1 * sin(uv.y * 50.0 + uTime * 8.0);

    // Add CRT glow and gamma
    float luma = dot(final, vec3(0.299, 0.587, 0.114));
    final *= (0.8 + 1.2 * pow(luma, 0.8));

    // Apply VHS tear and jitter from Shader A
    float band = fract(uv.y * 0.9 - uTime * 0.17);
    float tear = smoothstep(0.0, 0.03, band) * (1.0 - smoothstep(0.03, 0.09, band));
    float jitter = (hash21(vec2(floor(uv.y * 240.0), floor(uTime * 30.0))) - 0.5) * 0.004;
    vec2 suv = vec2(uv.x + jitter + tear * 0.035 * sin(uv.y * 90.0 + uTime * 20.0), uv.y);
    suv.x = clamp(suv.x, 0.0, 1.0);

    // Re-sample with VHS jitter and tear
    vec3 finalColor = texture(uTexture, suv).rgb;

    // Apply chroma bleed and scanlines again on top of VHS jitter
    vec2 bleedOffset = vec2(0.0015 * sin(uv.y * 200.0 + uTime * 2.0), 0.0);
    vec3 bleed = vec3(
        texture(uTexture, suv + bleedOffset).r,
        texture(uTexture, suv).g,
        texture(uTexture, suv - bleedOffset).b
    );
    float scan = 0.5 + 0.5 * cos(FlutterFragCoord().y * 30.0 + uTime * 15.0);
    bleed *= scan;

    // Combine curvature, mask, and final output
    float maskVal = step(0.33, mod(uv.y * 300.0 + uTime * 5.0, 3.0)) - step(0.66, mod(uv.y * 300.0 + uTime * 5.0, 3.0));
    vec3 result = bleed * (0.8 + 0.2 * maskVal);
    result *= 0.9 + 0.1 * sin(uv.y * 50.0 + uTime * 8.0);

    // Final glow and gamma
    float lum = dot(result, vec3(0.299, 0.587, 0.114));
    result *= (0.8 + 1.2 * pow(lum, 0.8));

    fragColor = vec4(result, 1.0);
}
