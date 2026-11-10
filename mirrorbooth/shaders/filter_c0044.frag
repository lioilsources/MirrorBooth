#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 rotate(vec2 v, float a) {
    float s = sin(a);
    float c = cos(a);
    return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

vec2 mirrorRepeat(vec2 uv, vec2 center, float scale, float segments) {
    vec2 p = (uv - center) * scale;
    p = mod(p + 0.5, 1.0) - 0.5;
    float angle = atan(p.y, p.x);
    float segment = floor(angle / (6.28318530718 / segments) + 0.5);
    p = rotate(p, -segment * (6.28318530718 / segments));
    p = abs(p);
    return center + p / scale;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter / uResolution;
    float scale = uFaceScale * 1.5;

    // Kaleidoscope effect with 8-fold symmetry, centered on face
    vec2 kaleidoUV = mirrorRepeat(uv, center, scale, 8.0);

    // Add subtle flow motion to the kaleidoscope
    float flow = sin(uTime * 0.5 + uv.x * 3.0) * 0.01;
    kaleidoUV += rotate(vec2(flow, 0.0), uTime * 0.2);

    // Sample from kaleidoscopic UV with slight offset for motion
    vec3 col = texture(uTexture, kaleidoUV).rgb;

    // Neon color grading with pulsing glow
    float pulse = sin(uTime * 2.0) * 0.5 + 0.5;
    vec3 neonR = vec3(1.0, 0.3, 0.8) * (0.8 + pulse * 0.4);
    vec3 neonG = vec3(0.3, 1.0, 0.8) * (0.8 + pulse * 0.4);
    vec3 neonB = vec3(0.5, 0.7, 1.0) * (0.8 + pulse * 0.4);

    // Apply neon tint with saturation boost
    vec3 lum = vec3(0.299, 0.587, 0.114);
    float l = dot(col, lum);
    vec3 diff = col - l * vec3(1.0);
    col = l * vec3(1.0) + diff * 2.0;

    // Colorize based on brightness
    col = mix(col, neonR, smoothstep(0.7, 1.0, l));
    col = mix(col, neonG, smoothstep(0.4, 0.7, l));
    col = mix(col, neonB, smoothstep(0.1, 0.4, l));

    // Add soft glow with edge diffusion
    float glow = 1.0 - smoothstep(0.0, 0.05, length(uv - center));
    col += glow * 0.3 * vec3(1.0, 0.6, 1.0);

    // Final output with slight blur for dreamy motion
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
