#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 funhouseWarp(vec2 p, float strength) {
    vec2 c = uFaceCenter;
    float s = uFaceScale;
    vec2 d = (p - c) * s;
    float r = length(d);
    if (r > 0.0) {
        float angle = 0.5 * strength * sin(r * 5.0) / (r + 0.01);
        float sA = sin(angle);
        float cA = cos(angle);
        return c + (vec2(d.x * cA - d.y * sA, d.x * sA + d.y * cA) / s);
    }
    return p;
}

float luminance(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 warped = funhouseWarp(uv, 3.0);

    vec2 dxy = 1.5 / uResolution;
    float l1 = luminance(texture(uTexture, warped - dxy).rgb);
    float l2 = luminance(texture(uTexture, warped + dxy).rgb);
    float edge = smoothstep(0.1, 0.9, abs(l1 - l2));

    vec3 base = texture(uTexture, warped).rgb;
    vec3 tint = mix(vec3(1.0, 0.7, 1.3), vec3(0.8, 1.0, 0.6), edge * 0.6);
    vec3 final = mix(base, tint, 0.4 * edge);

    fragColor = vec4(clamp(final, 0.0, 1.0), 1.0);
}
