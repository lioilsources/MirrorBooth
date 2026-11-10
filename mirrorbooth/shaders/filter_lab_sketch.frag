#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 d = 1.5 / uResolution;
    float c = luma(texture(uTexture, uv).rgb);
    float l = luma(texture(uTexture, uv - vec2(d.x, 0.0)).rgb);
    float r = luma(texture(uTexture, uv + vec2(d.x, 0.0)).rgb);
    float t = luma(texture(uTexture, uv - vec2(0.0, d.y)).rgb);
    float b = luma(texture(uTexture, uv + vec2(0.0, d.y)).rgb);
    float edge = clamp(length(vec2(r - l, b - t)) * 5.0, 0.0, 1.0);
    vec2 px = FlutterFragCoord().xy;
    float h1 = smoothstep(0.35, 0.65, abs(fract((px.x + px.y) / 7.0) - 0.5) * 2.0);
    float h2 = smoothstep(0.35, 0.65, abs(fract((px.x - px.y) / 7.0) - 0.5) * 2.0);
    float shade = 1.0;
    shade *= mix(1.0, h1, step(c, 0.55) * 0.7);
    shade *= mix(1.0, h2, step(c, 0.3) * 0.8);
    shade *= 1.0 - edge;
    vec3 col = mix(vec3(0.16, 0.16, 0.2), vec3(0.97, 0.95, 0.9), shade);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
