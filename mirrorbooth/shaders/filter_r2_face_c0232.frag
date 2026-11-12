#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float aspect = uResolution.x / uResolution.y;

    // Anchor point for all distortions: the face center
    vec2 anchor = uFaceCenter;

    // Adjust radius based on face scale to ensure consistent deformation
    float radius = 0.35 * uFaceScale;

    // Distance from pixel to face center, scaled by aspect ratio
    vec2 diff = uv - anchor;
    diff.x *= aspect;
    float dist = length(diff);

    // Replace the original distortion function with a "bubbling" effect:
    // the face center expands like a bubble, while edges are pulled inward
    float t = dist / radius;
    float bubble = 1.0 + 0.8 * (1.0 - t) * sin(3.14159 * t); // oscillating expansion
    vec2 warped = anchor + diff * bubble;

    // Ensure the warped coordinates stay within the texture bounds
    vec2 sampleUV = clamp(warped, 0.0, 1.0);

    // Sample the original image at the warped location
    vec3 color = texture(uTexture, sampleUV).rgb;

    // Apply a soft, dreamy color grading with a golden shimmer
    color = pow(color, vec3(1.1));
    float lightness = lum(color);
    color = mix(vec3(lightness * 1.2), color, 0.75) + vec3(0.1, 0.08, 0.02);

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
