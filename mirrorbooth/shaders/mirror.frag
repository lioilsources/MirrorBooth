#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
// 1.0 = mirror left half (right half becomes left's reflection)
// 0.0 = mirror right half (left half becomes right's reflection)
uniform float uMirrorLeft;
uniform vec2 uResolution;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    float halfX;
    if (uMirrorLeft > 0.5) {
        // Source: left half [0, 0.5]. Right side gets (1 - x) sample.
        halfX = uv.x < 0.5 ? uv.x : (1.0 - uv.x);
    } else {
        // Source: right half [0.5, 1]. Left side gets (1 - x) sample.
        halfX = uv.x >= 0.5 ? uv.x : (1.0 - uv.x);
    }

    fragColor = texture(uTexture, vec2(halfX, uv.y));
}
