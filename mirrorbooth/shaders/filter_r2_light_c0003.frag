#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 col = texture(uTexture, uv).rgb;
    float bright = luma(col);
    float glow = smoothstep(0.7, 1.0, bright);
    col += glow * 0.8;
    col = mix(vec3(luma(col)), col, 1.45);
    float vignette = 1.0 - length(uv - 0.5) * 1.5;
    col *= pow(vignette, 1.5);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
