#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float dist = abs(uv.y - uFaceCenter.y);
    float amt = smoothstep(0.12, 0.42, dist);
    vec2 rad = amt * 9.0 / uResolution;
    vec3 acc = texture(uTexture, uv).rgb;
    for (int i = 0; i < 12; i++) {
        float a = 2.3999632 * float(i);
        float r = sqrt((float(i) + 0.5) / 12.0);
        acc += texture(uTexture, uv + vec2(cos(a), sin(a)) * r * rad).rgb;
    }
    vec3 col = acc / 13.0;
    col = mix(vec3(luma(col)), col, 1.45);
    col = (col - 0.5) * 1.12 + 0.5;
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
