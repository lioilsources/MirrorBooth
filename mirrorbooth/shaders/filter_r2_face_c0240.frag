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
        float angle = 0.8 * strength * sin(r * 7.0) / (r + 0.005);
        float sA = sin(angle);
        float cA = cos(angle);
        return c + (vec2(d.x * cA - d.y * sA, d.x * sA + d.y * cA) / s);
    }
    return p;
}

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 warped = funhouseWarp(uv, 2.5);

    vec2 dxy = 1.2 / uResolution;
    float l1 = luminance(texture(uTexture, warped - dxy).rgb);
    float l2 = luminance(texture(uTexture, warped + dxy).rgb);
    float edge = smoothstep(0.2, 0.8, abs(l1 - l2));

    vec3 base = texture(uTexture, warped).rgb;
    vec3 tint = mix(vec3(1.2, 0.5, 0.9), vec3(0.6, 1.1, 0.8), edge * 0.5);
    vec3 final = mix(base, tint, 0.35 * edge);

    fragColor = vec4(clamp(final, 0.0, 1.0), 1.0);
}
