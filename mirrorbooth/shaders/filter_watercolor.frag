#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 px = 1.0 / uResolution;

    // Soft cross blur for watercolor base (9 taps)
    vec3 col = texture(uTexture, uv).rgb * 2.0;
    col += texture(uTexture, uv + vec2( 2.0,  0.0) * px).rgb;
    col += texture(uTexture, uv + vec2(-2.0,  0.0) * px).rgb;
    col += texture(uTexture, uv + vec2( 0.0,  2.0) * px).rgb;
    col += texture(uTexture, uv + vec2( 0.0, -2.0) * px).rgb;
    col += texture(uTexture, uv + vec2( 1.5,  1.5) * px).rgb * 0.75;
    col += texture(uTexture, uv + vec2(-1.5,  1.5) * px).rgb * 0.75;
    col += texture(uTexture, uv + vec2( 1.5, -1.5) * px).rgb * 0.75;
    col += texture(uTexture, uv + vec2(-1.5, -1.5) * px).rgb * 0.75;
    col /= 8.0;

    // Boost saturation for watercolor vibrancy
    float l = lum(col);
    col = mix(vec3(l), col, 1.35);

    // Paper texture: coarse + fine grain
    vec2 cell = floor(uv * uResolution * 0.07);
    float paperCoarse = rand(cell) * 0.06;
    float paperFine   = rand(uv * uResolution * 0.3) * 0.025;
    float paper = 1.0 - paperCoarse - paperFine;

    // Ink bleed: dark edges bleed outward
    float eL = lum(texture(uTexture, uv + vec2(-3.0,  0.0) * px).rgb);
    float eR = lum(texture(uTexture, uv + vec2( 3.0,  0.0) * px).rgb);
    float eU = lum(texture(uTexture, uv + vec2( 0.0,  3.0) * px).rgb);
    float eD = lum(texture(uTexture, uv + vec2( 0.0, -3.0) * px).rgb);
    float inkEdge = smoothstep(0.04, 0.28, sqrt((eR-eL)*(eR-eL) + (eU-eD)*(eU-eD)));

    // Warm paper tint
    col *= vec3(0.97, 0.95, 0.88) * paper;
    col = mix(col, vec3(0.06, 0.03, 0.09), inkEdge * 0.65);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
