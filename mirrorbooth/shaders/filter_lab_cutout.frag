#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float n = 5.0;
    float l = luma(texture(uTexture, uv).rgb);
    float q = floor(clamp(l, 0.0, 0.999) * n);
    vec2 off = vec2(-5.0, -7.0) / uResolution;
    float ls = luma(texture(uTexture, uv + off).rgb);
    float qs = floor(clamp(ls, 0.0, 0.999) * n);
    vec3 col = vec3(0.13, 0.16, 0.33);
    if (q > 3.5) { col = vec3(0.99, 0.95, 0.85); }
    else if (q > 2.5) { col = vec3(0.98, 0.75, 0.35); }
    else if (q > 1.5) { col = vec3(0.9, 0.36, 0.33); }
    else if (q > 0.5) { col = vec3(0.4, 0.2, 0.45); }
    col *= 1.0 - 0.3 * step(q + 0.5, qs);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
