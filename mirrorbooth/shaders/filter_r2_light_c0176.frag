#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 base = texture(uTexture, uv).rgb;
    float bright = luma(base);
    float glow = smoothstep(0.65, 1.0, bright);
    vec3 glowColor = vec3(0.9, 1.0, 1.2) * glow * 0.7;
    vec3 light = base + glowColor;
    light = mix(base, light, exp(bright * 1.5));
    vec2 center = uFaceCenter / uResolution;
    float distToCenter = length(uv - center);
    float rays = 1.0 - distToCenter * 1.7;
    rays = max(0.0, rays * (0.6 + 0.4 * sin(uTime * 1.3)));
    float bokeh = max(0.0, pow(1.0 - distToCenter * 1.4, 3.0) * 0.35);
    float vignette = 1.0 - length(uv - 0.5) * 1.5;
    vignette = pow(vignette, 1.4);
    vec3 final = light * vignette + bokeh * 0.45 + rays * 0.3;
    fragColor = vec4(clamp(final, 0.0, 1.0), 1.0);
}
