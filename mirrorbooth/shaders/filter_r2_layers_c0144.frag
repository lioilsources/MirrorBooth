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
    vec3 base = texture(uTexture, uv).rgb;

    // Weather and particle overlay: rain with sin-based motion and time-driven randomness
    float rain = 0.0;
    float aspect = uResolution.x / uResolution.y;
    vec2 p = uv * vec2(20.0 * aspect, 20.0);
    p.y += uTime * 0.8;
    p.x += sin(uTime * 0.7 + p.y * 1.2 + fract(p.y)) * 0.15;
    vec2 id = floor(p);
    vec2 f = fract(p) - 0.5;
    float h = hash21(id + 37.0);
    float r = 0.02 + 0.06 * h;
    float strength = smoothstep(r, r * 0.4, length(f - (h - 0.5) * 0.7));
    rain += strength * (0.9 - 0.3 * fract(uTime * 0.25));

    // Dust particles using fract(sin(...)) for organic movement
    float dust = 0.0;
    vec2 d = uv * vec2(15.0, 15.0);
    d.x += sin(uTime * 0.4 + d.y * 0.9) * 0.2;
    d.y += uTime * 0.3;
    vec2 di = floor(d);
    vec2 df = fract(d) - 0.5;
    float dval = fract(sin(dot(di, vec2(17.0, 41.0)) + uTime * 0.5) * 73.0);
    float dsize = 0.01 + 0.04 * dval;
    dust += smoothstep(dsize, dsize * 0.5, length(df)) * (0.7 + 0.3 * dval);

    // Fog effect with time-based density variation
    float fog = 0.0;
    float ftime = uTime * 0.1;
    float fbase = fract(sin(uv.x * 23.0 + ftime * 0.5) * 47.0) + fract(sin(uv.y * 19.0 + ftime * 0.7) * 53.0);
    fog += 0.15 * (fbase * 0.5 + 0.5);

    // Combine all effects: base image with weather overlay
    vec3 weather = vec3(rain * 0.5, rain * 0.6, rain * 0.7) + vec3(dust * 0.3, dust * 0.2, dust * 0.1) + vec3(fog * 0.2);
    vec3 final = base + weather;

    fragColor = vec4(clamp(final, 0.0, 1.0), 1.0);
}
