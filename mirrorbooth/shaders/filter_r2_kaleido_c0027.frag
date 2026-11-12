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
    float segments = 6.0;
    float snappedAngle = floor(angle * segments / 6.28318 + 0.5) * (6.28318 / segments);
    float distortedAngle = snappedAngle + 0.1 * sin(uTime * 0.3) * (1.0 - r * 1.5);
    vec2 distortedP = vec2(cos(distortedAngle), sin(distortedAngle)) * r;

    float distortion = 0.02 * (1.0 + sin(uTime * 0.8 + r * 8.0)) * (1.0 + cos(uTime * 0.6 + r * 12.0));
    distortedP *= (1.0 + distortion * r);

    vec2 kaleidoUV = center + distortedP;

    float dx = uv.x - center.x;
    float dy = uv.y - center.y;
    float warp = 0.3 * (1.0 - exp(-0.5 * (dx * dx + dy * dy) / (faceRadius * faceRadius)));
    kaleidoUV = mix(uv, kaleidoUV, warp);

    kaleidoUV = clamp(kaleidoUV, 0.0, 1.0);

    vec3 col = texture(uTexture, kaleidoUV).rgb;

    float pulse = 0.5 + 0.5 * sin(uTime * 0.7);
    float hueOffset = uTime * 0.25;
    float h = fract(uTime * 0.3 + hueOffset);
    float s = 0.8 + 0.2 * sin(h * 6.28318 + 1.0);
    float v = 0.8 + 0.2 * sin(h * 6.28318 + 2.0);
    float c = v * s;
    float x = c * (1.0 - abs(mod(h * 6.0, 2.0) - 1.0));
    float m = v - c;
    vec3 neon = vec3(
        (h < 1.0) ? c + m : (h < 2.0) ? x + m : m,
        (h < 1.0) ? x + m : (h < 2.0) ? c + m : m,
        (h < 1.0) ? m : (h < 2.0) ? m : (h < 3.0) ? c + m : (h < 4.0) ? x + m : m
    );
    col = mix(col, neon, 0.4 * pulse);

    vec2 vig = uv * 2.0 - 1.0;
    float vignette = pow(1.0 - dot(vig, vig) * 0.7, 1.2 + 0.2 * sin(uTime * 0.5));
    col *= mix(0.9, 1.0, vignette);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
