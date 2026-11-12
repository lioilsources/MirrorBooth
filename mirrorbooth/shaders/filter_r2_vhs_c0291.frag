#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // Apply screen curvature (CRT distortion) with time-varying warp
    vec2 c = uv * 2.0 - 1.0;
    c.x *= uResolution.x / uResolution.y;
    float r2 = dot(c, c);
    c *= 1.0 + (0.13 + 0.025 * sin(uTime * 0.6)) * r2;
    c.x /= (uResolution.x / uResolution.y);
    vec2 wUV = c * 0.5 + 0.5;

    // Black bezel outside screen
    if (wUV.x < 0.0 || wUV.x > 1.0 || wUV.y < 0.0 || wUV.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // Shadow mask: simulate RGB triad pattern (striped) with temporal jitter
    float mask = mod(uv.y * uResolution.y * 2.0 + uTime * 11.0, 3.0) < 1.0 ? 1.0 : 0.0;
    vec3 col = texture(uTexture, wUV).rgb * mask;

    // Chroma bleed: simulate color misalignment with time-varying lateral shift
    float shift = 0.002 + 0.0005 * sin(uTime * 1.3);
    float r = texture(uTexture, wUV + vec2(shift, 0.0)).r;
    float g = texture(uTexture, wUV).g;
    float b = texture(uTexture, wUV - vec2(shift, 0.0)).b;
    col = vec3(r, g, b);

    // Scanlines: alternating dark lines using FlutterFragCoord().y
    float scan = 0.7 + 0.3 * sin(FlutterFragCoord().y * 3.14159 * 0.55);
    col *= scan;

    // Phosphor glow: subtle greenish tint on bright areas
    float bright = dot(col, vec3(0.333));
    col += 0.09 * bright * vec3(0.0, 0.11, 0.0);

    // Apply tracking error: slight vertical jitter based on time and position
    float tracking = 0.001 * sin(uTime * 2.0 + uv.x * 10.0);
    vec2 jitterUV = wUV + vec2(0.0, tracking);
    col = texture(uTexture, jitterUV).rgb * col;

    // Transfer: color grading from the other filter — dynamic luminance mapping with gradient shift
    float l = luma(col);
    l = smoothstep(0.05, 0.95, l);
    vec3 lo = vec3(0.1, 0.05, 0.38);
    vec3 mid = vec3(0.93, 0.18, 0.5);
    vec3 hi = vec3(1.0, 0.92, 0.45);
    col = l < 0.5 ? mix(lo, mid, l * 2.0) : mix(mid, hi, l * 2.0 - 1.0);

    // Final brightness boost and color balance
    col *= 1.2;

    // Final color adjustment with screen edge softness
    col = mix(col, vec3(0.9, 0.85, 0.8), 0.08 * (1.0 - uv.y));

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
