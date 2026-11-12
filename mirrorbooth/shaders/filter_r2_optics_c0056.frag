#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 d = uv - uFaceCenter;
    d.x *= uResolution.x / uResolution.y;
    float r = length(d);
    float R = uFaceScale;

    vec2 wUV = uv;
    if (r < R && r > 0.0) {
        float theta = atan(d.y, d.x);
        float radius = max(abs(r / R), 0.001);
        float distorted = pow(radius, 1.4);
        vec2 distortedDir = vec2(cos(theta), sin(theta)) * distorted;
        vec2 displaced = uFaceCenter + distortedDir * R;
        wUV = mix(uv, displaced, smoothstep(0.7 * R, R, r));
        wUV.x /= uResolution.x / uResolution.y;
    }

    fragColor = vec4(texture(uTexture, wUV).rgb, 1.0);
}
