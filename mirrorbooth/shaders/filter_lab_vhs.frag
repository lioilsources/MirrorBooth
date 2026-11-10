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
    float band = fract(uv.y * 0.9 - uTime * 0.17);
    float tear = smoothstep(0.0, 0.03, band) * (1.0 - smoothstep(0.03, 0.09, band));
    float jitter = (hash21(vec2(floor(uv.y * 240.0), floor(uTime * 30.0))) - 0.5) * 0.004;
    float foot = step(0.965, uv.y) * (hash21(vec2(floor(uv.y * 300.0), floor(uTime * 60.0))) - 0.3) * 0.12;
    vec2 suv = vec2(uv.x + jitter + tear * 0.035 * sin(uv.y * 90.0 + uTime * 20.0) + foot, uv.y);
    suv.x = clamp(suv.x, 0.0, 1.0);
    float y = luma(texture(uTexture, suv).rgb);
    vec3 cl = texture(uTexture, vec2(clamp(suv.x - 0.012, 0.0, 1.0), suv.y)).rgb;
    vec3 cr = texture(uTexture, vec2(clamp(suv.x + 0.012, 0.0, 1.0), suv.y)).rgb;
    vec3 chroma = 0.5 * (cl + cr) - vec3(luma(0.5 * (cl + cr)));
    vec3 col = vec3(y) + chroma * 1.25 + vec3(0.03, 0.0, 0.05);
    float n = hash21(FlutterFragCoord().xy + uTime * 61.0);
    col += (n - 0.5) * 0.09 + tear * 0.18 * n;
    col *= 0.9 + 0.1 * sin(FlutterFragCoord().y * 2.2);
    col = mix(vec3(luma(col)), col, 0.85);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
