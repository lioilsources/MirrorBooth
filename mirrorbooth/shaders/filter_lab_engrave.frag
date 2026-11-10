#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 src = texture(uTexture, uv).rgb;
    float l = clamp(luma(src) * 1.1, 0.0, 1.0);
    float pitch = uResolution.x / 110.0;
    float y = FlutterFragCoord().y / pitch + sin(uv.x * 38.0) * 0.7 + (l - 0.5) * 1.5;
    float line = abs(fract(y) - 0.5) * 2.0;
    float w = 1.0 - l;
    float ink = smoothstep(w + 0.12, w - 0.12, line);
    vec3 col = mix(vec3(0.93, 0.95, 0.88), vec3(0.08, 0.22, 0.16), ink);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
