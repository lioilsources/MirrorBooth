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
    float t = floor(uTime * 7.0);
    float row = floor(uv.y * 14.0);
    float h = hash21(vec2(row, t));
    float hit = step(0.72, h);
    float shift = (hash21(vec2(row + 3.0, t)) - 0.5) * 0.22 * hit;
    vec2 cell = floor(uv * vec2(8.0, 14.0));
    float hb = hash21(cell + t * 1.3);
    vec2 suv = vec2(fract(uv.x + shift), uv.y);
    float split = 0.004 + 0.02 * hit;
    vec3 col;
    col.r = texture(uTexture, vec2(fract(suv.x + split), suv.y)).r;
    col.g = texture(uTexture, suv).g;
    col.b = texture(uTexture, vec2(fract(suv.x - split), suv.y)).b;
    if (hb > 0.95) { col = 1.0 - col; }
    else if (hb > 0.9) { col = vec3(luma(col)) * vec3(0.2, 1.0, 0.9); }
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
