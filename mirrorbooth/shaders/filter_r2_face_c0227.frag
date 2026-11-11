#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

// Jelly wobble: face region wobbles with two soft oscillations on the sides,
// anchored at uFaceCenter and scaled by uFaceScale, creating a jiggly, gelatinous effect.
vec2 jellyWobble(vec2 uv, vec2 center, float scale) {
    float aspect = uResolution.x / uResolution.y;
    vec2 d = (uv - center) * vec2(aspect, 1.0);

    // Define two wobble zones near the left and right sides of the face
    vec2 leftOffset = vec2(-0.6 * scale, 0.15 * scale);
    vec2 rightOffset = vec2(0.6 * scale, 0.15 * scale);

    float distLeft = length(d - leftOffset);
    float distRight = length(d - rightOffset);

    // Gaussian falloff for localized effect
    float influenceLeft = exp(-distLeft * distLeft / (0.3 * scale * scale));
    float influenceRight = exp(-distRight * distRight / (0.3 * scale * scale));

    // Sinusoidal wobble with time-independent frequency (no uTime used)
    float wobbleLeft = 0.15 * influenceLeft * sin(2.0 * 3.14159 * distLeft / (0.4 * scale));
    float wobbleRight = 0.15 * influenceRight * sin(2.0 * 3.14159 * distRight / (0.4 * scale));

    // Apply displacement: more horizontal, less vertical for a jelly-like wiggle
    d.x += (wobbleLeft + wobbleRight) * aspect;
    d.y += (wobbleLeft + wobbleRight) * 0.4;

    return center + d / vec2(aspect, 1.0);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float R = uFaceScale;

    // First, compute the remapped UV using the jelly wobble, anchored on uFaceCenter and scaled by uFaceScale
    vec2 src = jellyWobble(uv, uFaceCenter, R);

    // Clamp the result to avoid texture sampling outside bounds
    vec2 wUV = clamp(src, 0.0, 1.0);

    // Sample the original texture at the deformed UV
    fragColor = vec4(texture(uTexture, wUV).rgb, 1.0);
}
