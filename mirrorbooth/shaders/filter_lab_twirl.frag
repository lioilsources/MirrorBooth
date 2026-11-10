#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float aspect = uResolution.x / uResolution.y;
    vec2 d = uv - uFaceCenter;
    d.x *= aspect;
    float r = length(d);
    float R = max(uFaceScale * 1.7, 0.25);
    float fall = 1.0 - smoothstep(0.0, R, r);
    float ang = 2.6 * sin(uTime * 0.9) * fall * fall;
    float s = sin(ang);
    float c = cos(ang);
    d = vec2(c * d.x - s * d.y, s * d.x + c * d.y);
    d.x /= aspect;
    vec3 col = texture(uTexture, clamp(uFaceCenter + d, 0.0, 1.0)).rgb;
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
