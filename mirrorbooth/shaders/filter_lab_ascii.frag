#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float cell = uResolution.x / 56.0;
    vec2 g = FlutterFragCoord().xy / cell;
    vec2 f = fract(g);
    vec3 src = texture(uTexture, (floor(g) + 0.5) * cell / uResolution).rgb;
    float lvl = floor(clamp(luma(src) * 1.15, 0.0, 0.999) * 6.0);
    vec2 a = abs(f - 0.5);
    float glyph = 0.0;
    if (lvl > 4.5) { glyph = step(max(a.x, a.y), 0.42); }
    else if (lvl > 3.5) { glyph = max(step(abs(a.x - 0.18), 0.07), step(abs(a.y - 0.18), 0.07)) * step(max(a.x, a.y), 0.42); }
    else if (lvl > 2.5) { glyph = max(step(a.x, 0.07) * step(a.y, 0.34), step(a.y, 0.07) * step(a.x, 0.34)); }
    else if (lvl > 1.5) { glyph = step(a.y, 0.07) * step(a.x, 0.3); }
    else if (lvl > 0.5) { glyph = step(length(f - 0.5), 0.13); }
    vec3 tint = mix(vec3(0.2, 1.0, 0.45), src * 1.6, 0.35);
    vec3 col = tint * glyph;
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
