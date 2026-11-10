#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 q = abs(uv - 0.5);
    vec2 suv = vec2(0.5 - q.x * 0.9, 0.62 - q.y * 1.1);
    vec3 col = texture(uTexture, clamp(suv, 0.0, 1.0)).rgb;
    float seam = min(q.x * uResolution.x, q.y * uResolution.y);
    col *= 0.8 + 0.2 * smoothstep(0.0, 3.0, seam);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
