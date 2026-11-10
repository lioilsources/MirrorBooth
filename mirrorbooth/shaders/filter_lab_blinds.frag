#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float n = 11.0;
    float id = floor(uv.x * n);
    float f = fract(uv.x * n);
    float off = sin(id * 1.7 + uTime * 1.4) * 0.05;
    vec2 suv = vec2((id + 0.5 + (f - 0.5) * 1.7) / n, uv.y + off);
    vec3 col = texture(uTexture, clamp(suv, 0.0, 1.0)).rgb;
    float shade = 0.65 + 0.35 * sin(f * 3.14159);
    col *= shade;
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
