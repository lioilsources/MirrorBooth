#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float hash21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
vec2 hash22(vec2 p) { float n = hash21(p); return vec2(n, hash21(p + n + 17.1)); }
float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 src = texture(uTexture, uv).rgb;
    float l = pow(luma(src), 0.65) * 1.35;
    float n = hash21(FlutterFragCoord().xy * 0.7 + uTime * 47.0);
    l += (n - 0.5) * 0.22;
    l *= 0.88 + 0.12 * sin(FlutterFragCoord().y * 1.6);
    float aspect = uResolution.x / uResolution.y;
    vec2 c = uv - 0.5;
    c.x *= aspect;
    float scope = smoothstep(0.62 * max(aspect, 0.6) + 0.12, 0.3, length(c));
    vec3 col = vec3(0.12, 1.0, 0.25) * l * scope;
    col += vec3(0.6, 1.0, 0.6) * max(l - 0.95, 0.0);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
