#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float aspect = uResolution.x / uResolution.y;
    vec2 d = uv - uFaceCenter;
    d.x *= aspect;
    float r = length(d);
    float k = clamp(r / 0.75, 0.0, 1.0);
    d *= mix(0.42, 1.0, k * k);
    d.x /= aspect;
    vec3 col = texture(uTexture, clamp(uFaceCenter + d, 0.0, 1.0)).rgb;
    col *= 1.0 - 0.55 * smoothstep(0.45, 0.95, r);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
