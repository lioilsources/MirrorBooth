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
    float glow = smoothstep(0.6, 1.0, bright);
    vec3 glowColor = vec3(1.0, 0.9, 0.7) * glow * 0.8;
    vec3 light = base + glowColor;
    light = mix(base, light, pow(bright, 1.5));
    vec2 center = uFaceCenter / uResolution;
    float distToCenter = length(uv - center);
    float rays = max(0.0, 1.0 - distToCenter * 1.5);
    rays *= 0.5 + 0.5 * sin(uTime * 0.8 + distToCenter * 10.0);
    float bokeh = pow(1.0 - distToCenter * 1.4, 4.0);
    bokeh = max(0.0, bokeh * 0.4);
    float vignette = 1.0 - length(uv - 0.5) * 1.7;
    vignette = pow(vignette, 1.4);
    vec3 final = light * vignette + bokeh * 0.6 + rays * 0.5;
    fragColor = vec4(clamp(final, 0.0, 1.0), 1.0);
}
