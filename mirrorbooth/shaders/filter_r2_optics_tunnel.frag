#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 p = uv - 0.5;
    float s = max(max(abs(p.x), abs(p.y)) * 2.0, 0.0005);
    float t = fract(uTime * 0.25);
    float k = log2(1.0 / s) + t;
    float n = floor(k);
    float zoom = exp2(n - t);
    vec2 q = p * zoom;
    vec3 col = texture(uTexture, clamp(q + 0.5, 0.0, 1.0)).rgb;
    float e = max(abs(q.x), abs(q.y)) * 2.0;
    col *= 0.55 + 0.45 * smoothstep(1.0, 0.93, e);
    col *= 1.0 - 0.25 * smoothstep(0.62, 0.5, e);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
