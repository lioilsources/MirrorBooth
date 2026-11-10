#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float n = 44.0;
    vec2 cells = vec2(n, n * uResolution.y / uResolution.x);
    vec2 f = fract(uv * cells);
    vec3 col = texture(uTexture, (floor(uv * cells) + 0.5) / cells).rgb;
    float b = smoothstep(0.0, 0.1, min(min(f.x, f.y), min(1.0 - f.x, 1.0 - f.y)));
    col *= 0.72 + 0.28 * b;
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
