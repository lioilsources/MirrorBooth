#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 p = uv - 0.5;
    float angle = atan(p.y, p.x);
    float r = length(p);
    float sectors = 6.0;
    angle = mod(angle, 2.0 * 3.14159 / sectors);
    angle = min(angle, 2.0 * 3.14159 / sectors - angle);
    p = vec2(cos(angle), sin(angle)) * r;
    p += 0.5;

    vec3 col = texture(uTexture, p).rgb;
    col = pow(col, vec3(0.8));
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
