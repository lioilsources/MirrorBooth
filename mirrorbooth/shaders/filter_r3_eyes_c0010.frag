#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

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
    float aspect = uResolution.x / uResolution.y;

    // Apply jelly wobble to the entire face region for subtle movement
    vec2 src = jellyWobble(uv, uFaceCenter, uFaceScale);
    vec2 wUV = clamp(src, 0.0, 1.0);
    vec3 col = texture(uTexture, wUV).rgb;

    // Eye band sits above the face center; one horizontally stretched bulge
    // covers both eyes.
    vec2 e = vec2(uFaceCenter.x, uFaceCenter.y - 0.35 * uFaceScale);
    vec2 d = uv - e;
    d.x *= aspect;

    vec2 k = d;
    k.x *= 0.6;  // widen the kernel horizontally into a band
    float sigma = 0.35 * uFaceScale;
    float w = exp(-dot(k, k) / (sigma * sigma));

    // Sampling closer to the band center magnifies the eyes
    vec2 eyeSrc = d * (1.0 - 0.25 * w);
    eyeSrc.x /= aspect;
    vec2 eyeUV = clamp(e + eyeSrc, 0.0, 1.0);

    // Sample the eye region with magnification
    vec3 eyeCol = texture(uTexture, eyeUV).rgb;

    // Brighten + pastel: mild desaturation with a faint pink cast
    eyeCol = pow(clamp(eyeCol, 0.0, 1.0), vec3(0.85));
    float l = lum(eyeCol);
    eyeCol = mix(vec3(l), eyeCol, 0.8) + vec3(0.04, 0.01, 0.03);

    // Add a vivid color boost to the eyes
    eyeCol = mix(eyeCol, vec3(0.9, 0.3, 0.7), 0.5); // Vivid magenta-blue tint

    // Add a sparkle of light in the iris (a small bright spot)
    vec2 irisPos = e + vec2(0.0, 0.02 * uFaceScale); // Slight offset from center
    vec2 irisD = uv - irisPos;
    irisD.x *= aspect;
    float irisDist = length(irisD);
    float sparkle = exp(-irisDist * irisDist / (0.001 * uFaceScale * uFaceScale));
    sparkle *= 0.8; // Brightness of sparkle
    eyeCol += vec3(1.0, 1.0, 1.0) * sparkle;

    // Blend the enhanced eyes back into the original image
    fragColor = vec4(mix(col, eyeCol, w), 1.0);
}
