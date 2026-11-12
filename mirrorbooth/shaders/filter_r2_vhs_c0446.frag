#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 warp(vec2 uv, float strength) {
    vec2 c = (uv - 0.5) * 2.0;
    c.x *= uResolution.x / uResolution.y;
    float r2 = c.x * c.x + c.y * c.y;
    c *= 1.0 + strength * r2 * (1.0 - r2);
    c.x /= (uResolution.x / uResolution.y);
    return c * 0.5 + 0.5;
}

float sampleNoise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float grid(vec2 uv, float spacing) {
    return step(0.5, mod(uv.x * spacing, 1.0));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // Apply CRT screen curvature using a modified warp function
    vec2 wUV = warp(uv, 0.14);
    if (wUV.x < 0.0 || wUV.x > 1.0 || wUV.y < 0.0 || wUV.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // Simulate tracking errors with horizontal jitter and wave modulation
    float wave = sin(uv.y * 120.0 + uTime * 18.0) * 0.003;
    float jitter = (fract(uv.y * 240.0 + uTime * 45.0) - 0.5) * 0.005;
    vec2 suv = vec2(wUV.x + wave + jitter, wUV.y);

    // Extract luminance and simulate chroma bleed via offset sampling
    float y = dot(texture(uTexture, suv).rgb, vec3(0.299, 0.587, 0.114));
    vec3 left = texture(uTexture, vec2(clamp(suv.x - 0.01, 0.0, 1.0), suv.y)).rgb;
    vec3 right = texture(uTexture, vec2(clamp(suv.x + 0.01, 0.0, 1.0), suv.y)).rgb;
    vec3 chroma = 0.4 * (left + right) - vec3(dot(0.4 * (left + right), vec3(0.299, 0.587, 0.114)));
    vec3 col = vec3(y) + chroma * 1.3;

    // Add vertical scanlines with intensity modulation
    float scan = 0.5 + 0.5 * sin(FlutterFragCoord().y * 2.0 + uTime * 1.5);
    col *= scan;

    // Apply shadow mask as vertical color stripes
    float mask = mod(wUV.x * 2.7, 1.0);
    float maskLine = step(0.35, mask) - step(0.65, mask);
    vec3 shadow = vec3(maskLine * 0.8);

    // Add flicker and grain using noise at high frequency
    float noiseVal = sampleNoise(uv * 250.0 + uTime * 17.0);
    col += (noiseVal - 0.5) * 0.06;

    // Vignette: darken edges with soft falloff
    vec2 vig = wUV * 2.0 - 1.0;
    float vignette = pow(clamp(1.0 - dot(vig, vig) * 1.3, 0.0, 1.0), 0.85);
    col *= vignette;

    // Dithering via grid pattern for dot crawl effect
    float gridSpacing = 1.8;
    float dither = grid(wUV, gridSpacing);
    float luma = dot(texture(uTexture, wUV).rgb, vec3(0.299, 0.587, 0.114));
    float threshold = (luma * 1.1) + 0.05;
    vec3 dithered = mix(vec3(0.05, 0.08, 0.2), vec3(0.9, 0.88, 0.8), step(dither, threshold));
    col = mix(col, dithered, 0.3);

    // Final warm tint and contrast boost
    col = mix(vec3(0.9, 0.85, 0.8), col, 0.7);
    col *= 1.15;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
