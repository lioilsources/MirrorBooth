#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 px = FlutterFragCoord().xy;
    float cell = uResolution.x / 60.0;
    vec2 rp = px / cell;
    vec2 center = (floor(rp) + 0.5) * cell;
    vec2 cuv = center / uResolution;
    float l = luma(texture(uTexture, clamp(cuv, 0.0, 1.0)).rgb);
    float d = length(fract(rp) - 0.5);
    float radius = 0.6 * sqrt(1.0 - l);
    float ink = step(radius, d);
    vec3 col = mix(vec3(0.98, 0.95, 0.90), vec3(0.05, 0.04, 0.08), ink);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
