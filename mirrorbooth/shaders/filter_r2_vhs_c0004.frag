#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float hash21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
vec2 hash22(vec2 p) { float n = hash21(p); return vec2(n, hash21(p + n + 17.1)); }
float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter / uResolution;
    float scale = uFaceScale;
    
    // CRT screen curvature distortion
    vec2 c = uv - center;
    float dist = length(c);
    float curvature = 0.02 * (1.0 - pow(dist, 2.0)) * scale;
    c += c * curvature * 0.5;
    uv = c + center;

    // Scanlines with dynamic intensity
    float scanline = 0.5 + 0.5 * sin(uv.y * 100.0 + uTime * 2.0);
    float scanlineIntensity = 0.08 * (1.0 - pow(0.5 - abs(mod(uv.y * 2.0, 1.0) - 0.5), 2.0));
    scanline *= scanlineIntensity;

    // Shadow mask (RGB triads)
    vec2 mask = mod(uv * 100.0, 3.0) - 1.0;
    float maskR = step(0.0, mask.x) * step(mask.y, 0.0);
    float maskG = step(0.0, mask.x) * step(0.0, mask.y);
    float maskB = step(0.0, -mask.x) * step(0.0, mask.y);
    vec3 maskColor = vec3(maskR, maskG, maskB);

    // Chroma bleed (color fringing)
    vec3 offset = vec3(0.003, 0.002, 0.004);
    vec3 r = texture(uTexture, uv + vec2(offset.x, 0.0)).rgb;
    vec3 g = texture(uTexture, uv + vec2(offset.y, 0.0)).rgb;
    vec3 b = texture(uTexture, uv + vec2(offset.z, 0.0)).rgb;
    vec3 color = r * maskR + g * maskG + b * maskB;

    // Tracking error (wavy horizontal jitter)
    float tracking = sin(uv.y * 30.0 + uTime * 2.0) * 0.002 * sin(uv.x * 100.0);
    vec2 offsetUV = uv + vec2(tracking, 0.0);
    vec3 src = texture(uTexture, offsetUV).rgb;

    // Final color with luminance adjustment and scanline overlay
    float l = pow(luma(src), 0.7) * 1.3;
    l += (hash21(uv * 100.0 + uTime * 13.0) - 0.5) * 0.15;
    l *= 0.85 + 0.15 * sin(uv.y * 1.7);
    vec3 col = color * l * (1.0 - scanline) + vec3(scanline) * 0.1;

    // Add glow and noise for VHS vibe
    col += vec3(0.1, 0.05, 0.0) * (hash21(uv * 20.0 + uTime * 7.0) - 0.5) * 0.1;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
