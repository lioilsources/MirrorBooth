#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }
float bayer2(vec2 a) { a = floor(a); return fract(a.x / 2.0 + a.y * a.y * 0.75); }
float bayer4(vec2 a) { return bayer2(0.5 * a) * 0.25 + bayer2(a); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float px = max(2.0, floor(uResolution.x / 180.0));
    vec2 cell = floor(FlutterFragCoord().xy / px);
    vec2 cuv = (cell + 0.5) * px / uResolution;
    float l = luma(texture(uTexture, cuv).rgb);
    l = clamp((l - 0.5) * 1.3 + 0.5, 0.0, 1.0);
    float on = step(bayer4(cell) + 0.03, l);
    vec3 col = mix(vec3(0.07, 0.09, 0.22), vec3(0.95, 0.91, 0.78), on);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
