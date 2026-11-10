#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }
float bayer2(vec2 a) { a = floor(a); return fract(a.x / 2.0 + a.y * a.y * 0.75); }
float bayer4(vec2 a) { return bayer2(0.5 * a) * 0.25 + bayer2(a); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float px = floor(uResolution.x / 120.0);
    vec2 cell = floor(FlutterFragCoord().xy / px);
    vec2 f = fract(FlutterFragCoord().xy / px);
    float l = luma(texture(uTexture, (cell + 0.5) * px / uResolution).rgb);
    l = clamp((l - 0.5) * 1.25 + 0.5, 0.0, 1.0);
    float q = floor(l * 3.0 + bayer4(cell));
    q = clamp(q, 0.0, 3.0) / 3.0;
    vec3 col = mix(vec3(0.06, 0.22, 0.06), vec3(0.61, 0.74, 0.06), q);
    col = mix(col, vec3(0.19, 0.38, 0.19), (1.0 - q) * 0.25);
    col *= 0.86 + 0.14 * step(0.12, min(f.x, f.y));
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
