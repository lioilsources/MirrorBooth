#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 px = FlutterFragCoord().xy;
    float cell = uResolution.x / 70.0;
    mat2 rot = mat2(0.7071, -0.7071, 0.7071, 0.7071);
    vec2 rp = rot * px / cell;
    vec2 center = (floor(rp) + 0.5) * cell;
    vec2 cuv = (center * rot) / uResolution;
    float l = luma(texture(uTexture, clamp(cuv, 0.0, 1.0)).rgb);
    float radius = 0.72 * sqrt(1.0 - l);
    float d = length(fract(rp) - 0.5);
    float ink = smoothstep(radius + 0.06, radius - 0.06, d);
    vec3 col = mix(vec3(0.96, 0.93, 0.86), vec3(0.08, 0.07, 0.12), ink);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
