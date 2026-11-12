#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float l = luma(texture(uTexture, uv).rgb);
    l = smoothstep(0.05, 0.95, l);
    vec3 lo = vec3(0.1, 0.05, 0.38);
    vec3 hi = vec3(1.0, 0.92, 0.45);
    vec3 col = mix(lo, hi, l);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
