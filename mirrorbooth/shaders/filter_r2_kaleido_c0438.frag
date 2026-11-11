#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter;
    float faceRadius = uFaceScale * 0.5;

    vec2 p = uv - center;
    float angle = atan(p.y, p.x);
    float r = length(p);
    float segments = 8.0;
    float snappedAngle = floor(angle * segments / 6.28318 + 0.5) * (6.28318 / segments);
    float modAngle = mod(angle, 6.28318 / segments);
    float warpedAngle = snappedAngle + 0.05 * sin(uTime * 0.4 + modAngle * 4.0) * (1.0 - r * 1.2);
    vec2 warpedP = vec2(cos(warpedAngle), sin(warpedAngle)) * r;

    float distortion = 0.03 * (1.0 + sin(uTime * 0.9 + r * 10.0)) * (1.0 + cos(uTime * 0.7 + r * 15.0));
    warpedP *= (1.0 + distortion * r * 0.8);

    vec2 kaleidoUV = center + warpedP;

    float dx = uv.x - center.x;
    float dy = uv.y - center.y;
    float warp = 0.4 * (1.0 - exp(-0.6 * (dx * dx + dy * dy) / (faceRadius * faceRadius)));
    kaleidoUV = mix(uv, kaleidoUV, warp);

    kaleidoUV = clamp(kaleidoUV, 0.0, 1.0);

    // Transfer: add scanline-like vertical offset based on horizontal position
    float n = 11.0;
    float id = floor(kaleidoUV.x * n);
    float f = fract(kaleidoUV.x * n);
    float off = sin(id * 1.7 + uTime * 1.4) * 0.05;
    vec2 suv = vec2((id + 0.5 + (f - 0.5) * 1.7) / n, kaleidoUV.y + off);
    vec3 col = texture(uTexture, clamp(suv, 0.0, 1.0)).rgb;

    float shade = 0.65 + 0.35 * sin(f * 3.14159);
    col *= shade;

    float pulse = 0.5 + 0.5 * sin(uTime * 0.6);
    float hueOffset = uTime * 0.2;
    float h = fract(uTime * 0.35 + hueOffset);
    float s = 0.7 + 0.3 * sin(h * 6.28318 + 1.5);
    float v = 0.9 + 0.1 * sin(h * 6.28318 + 2.5);
    float c = v * s;
    float x = c * (1.0 - abs(mod(h * 6.0, 2.0) - 1.0));
    float m = v - c;
    vec3 neon = vec3(
        (h < 1.0) ? c + m : (h < 2.0) ? x + m : m,
        (h < 1.0) ? x + m : (h < 2.0) ? c + m : m,
        (h < 1.0) ? m : (h < 2.0) ? m : (h < 3.0) ? c + m : (h < 4.0) ? x + m : m
    );
    col = mix(col, neon, 0.35 * pulse);

    vec2 vig = uv * 2.0 - 1.0;
    float vignette = pow(1.0 - dot(vig, vig) * 0.8, 1.3 + 0.1 * sin(uTime * 0.6));
    col *= mix(0.85, 1.0, vignette);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
