#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 base = texture(uTexture, uv).rgb;
    vec2 dir = uFaceCenter - uv;
    vec3 acc = vec3(0.0);
    float wsum = 0.0;
    for (int i = 0; i < 18; i++) {
        float t = float(i) / 18.0;
        vec3 c = texture(uTexture, uv + dir * t * 0.55).rgb;
        float w = 1.0 - t;
        acc += max(c - 0.72, 0.0) * w;
        wsum += w;
    }
    vec3 rays = acc / wsum * 2.4;
    vec3 col = base * 0.9 + rays * vec3(1.0, 0.9, 0.7);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
