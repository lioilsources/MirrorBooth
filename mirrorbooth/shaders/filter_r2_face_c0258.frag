#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 jellyWobble(vec2 uv, vec2 center, float scale) {
    float aspect = uResolution.x / uResolution.y;
    vec2 d = (uv - center) * vec2(aspect, 1.0);

    vec2 offset = vec2(0.6 * scale, 0.15 * scale);
    float dist = length(d - offset);
    float influence = exp(-dist * dist / (0.3 * scale * scale));
    float wobble = 0.15 * influence * sin(2.0 * 3.14159 * dist / (0.4 * scale));

    d.x += wobble * aspect;
    d.y += wobble * 0.4;

    return center + d / vec2(aspect, 1.0);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 src = jellyWobble(uv, uFaceCenter, uFaceScale);
    fragColor = vec4(texture(uTexture, clamp(src, 0.0, 1.0)).rgb, 1.0);
}
