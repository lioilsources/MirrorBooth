#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float y = FlutterFragCoord().y;

    // CRT curvature: radial distortion centered on face with scale influence
    vec2 center = uFaceCenter / uResolution;
    vec2 to_center = uv - center;
    float dist = length(to_center);
    float curvature_strength = 0.12 * uFaceScale * dist * dist;
    vec2 distorted_uv = center + to_center * (1.0 + curvature_strength);

    // Scanlines: vertical modulation using y-coordinate and time
    float scanline_intensity = 0.5 + 0.5 * cos(y * 32.0 + uTime * 13.0);

    // Shadow mask simulation: RGB stripe pattern with dynamic vertical offset
    float mask_phase = sin(uv.x * 98.0 + uTime * 16.0) * 0.006;
    vec2 r_uv = distorted_uv + vec2(0.0, mask_phase);
    vec2 g_uv = distorted_uv;
    vec2 b_uv = distorted_uv - vec2(0.0, mask_phase);

    // Chroma bleed: separate channel sampling with small vertical offsets
    float r = texture(uTexture, r_uv).r;
    float g = texture(uTexture, g_uv).g;
    float b = texture(uTexture, b_uv).b;

    // Tracking error: horizontal wobble modulated by vertical position and time
    float tracking = 0.0025 * sin(uv.x * 55.0 + uTime * 17.0) * (1.0 + 0.6 * sin(y * 22.0));
    vec2 final_uv = vec2(distorted_uv.x + tracking, distorted_uv.y);

    // Final color with scanline modulation
    vec3 color = vec3(r, g, b);
    color *= scanline_intensity;

    // Add subtle noise and grain
    float grain = (hash21(uv * 180.0 + uTime * 8.0) - 0.5) * 0.04;
    color += vec3(grain);

    // Screen edge softening based on distance from center
    float falloff = 1.0 - smoothstep(0.1, 0.8, dist);
    color *= falloff;

    // VHS-style tint and saturation adjustment
    float luma = dot(color, vec3(0.3, 0.59, 0.11));
    float tint = 0.9 + 0.2 * sin(uTime * 0.7);
    vec3 vhs_tint = vec3(0.15, 1.0, 0.28);
    vec3 final_color = color * (0.9 + 0.1 * sin(luma * 4.0)) + vhs_tint * (0.85 - luma * 0.5);

    // Apply final scanline effect using y coordinate directly
    float scanline_mask = 0.5 + 0.5 * cos(y * 30.0 + uTime * 11.0);
    final_color *= scanline_mask;

    fragColor = vec4(clamp(final_color, 0.0, 1.0), 1.0);
}
