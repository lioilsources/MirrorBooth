#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 d = 1.6 / uResolution;
    vec3 src = texture(uTexture, uv).rgb;
    float a = luma(texture(uTexture, uv - d).rgb);
    float b = luma(texture(uTexture, uv + d).rgb);
    float e = clamp(0.5 + (a - b) * 4.0, 0.0, 1.0);
    vec3 col = mix(vec3(e), vec3(e) * (0.6 + 0.8 * src), 0.35);
    col *= vec3(1.0, 0.97, 0.9);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
