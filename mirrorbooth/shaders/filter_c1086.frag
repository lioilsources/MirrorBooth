#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonColor(float t) {
    return mix(
        vec3(0.0, 1.0, 1.0),  // cyan
        vec3(1.0, 0.0, 1.0),  // magenta
        0.5 + 0.5 * sin(t * 0.5 + 0.7 * t * 0.3)
    ) * (0.8 + 0.2 * sin(t * 0.8 + 1.3 * t * 0.1));
}

float kaleidoDist(vec2 p, float n) {
    float angle = 2.0 * 3.14159 / n;
    p = p - 0.5;
    float a = atan(p.y, p.x);
    float r = length(p);
    a = mod(a + angle * 0.5, angle) - angle * 0.5;
    return length(vec2(r, a)) * n;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter / uResolution;
    float scale = uFaceScale;

    // Adjust for face center and scale
    vec2 p = (uv - center) * scale + center;

    // Apply kaleidoscope effect with 6-fold symmetry
    float n = 6.0;
    float d = kaleidoDist(p, n);
    vec2 mirrored = (p - 0.5) * scale + 0.5;

    // Use the distance to sample the texture with a smooth offset
    vec2 uvSample = uv;
    float offset = 0.01 * sin(d * 10.0 + uTime * 2.0);
    uvSample += offset * normalize(vec2(sin(d * 1.5), cos(d * 1.5)));

    // Sample texture with kaleidoscopic distortion
    vec3 col = texture(uTexture, uvSample).rgb;

    // Add smooth flowing motion with time-based ripple
    float ripple = sin(d * 15.0 + uTime * 3.0) * 0.05;
    col += vec3(ripple, ripple * 0.7, ripple * 0.3);

    // Apply neon color grading with pulsing
    vec3 neon = neonColor(uTime);
    col = mix(col, neon, 0.3 + 0.2 * sin(uTime * 1.5));

    // Add glow effect
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 glow = (col - vec3(0.3)) * 2.0;
    col += glow * (1.0 - smoothstep(0.7, 1.0, lum)) * 0.6;

    // Soft vignette with motion
    vec2 vig = uv * 2.0 - 1.0;
    float vignette = pow(clamp(1.0 - dot(vig * 0.4, vig * 0.4), 0.0, 1.0), 0.3);
    vignette *= 0.8 + 0.2 * sin(uTime * 0.5);
    col *= mix(1.0, 0.7, vignette);

    // Final tone and saturation boost
    col = pow(col, vec3(0.8));
    col = mix(col, vec3(1.0), 0.1 * (1.0 - lum));

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
