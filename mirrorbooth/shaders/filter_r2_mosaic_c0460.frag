#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 hexagonalMosaic(vec2 p) {
    vec2 uv = floor(p);
    vec2 f = fract(p);
    float aspect = uResolution.x / uResolution.y;
    float s = 34.0;
    vec2 r = vec2(1.0, 1.7320508);
    vec2 h = r * 0.5;
    vec2 a = mod(p, r) - h;
    vec2 b = mod(p - h, r) - h;
    vec2 g = dot(a, a) < dot(b, b) ? a : b;
    vec2 c = (p - g) / s;
    vec3 col = texture(uTexture, clamp(vec2(c.x / aspect, c.y), 0.0, 1.0)).rgb;
    float d = max(abs(g.y), abs(g.y) * 0.5 + abs(g.x) * 0.8660254);
    return col * (0.55 + 0.45 * smoothstep(0.5, 0.42, d));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter / uResolution;
    float scale = uFaceScale * 44.0;
    vec2 p = (uv - center) * scale + center;
    vec3 col = hexagonalMosaic(p);
    fragColor = vec4(col, 1.0);
}
