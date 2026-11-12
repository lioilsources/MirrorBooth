#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // Compute displacement from face center, scaled by face scale
    vec2 d = (uv - uFaceCenter) / uFaceScale;

    // Apply a funhouse-style distortion using a cubic warp function
    float r = length(d);
    float mask = exp(-r * r * 2.0); // Localized falloff

    // Use a warped wave pattern based on both position and face scale
    float wave = 0.5 * mask * (1.0 + cos(12.0 * d.x + 9.0 * d.y + 3.0 * uFaceScale));

    // Nonlinear stretch: stronger near center, smoother at edges
    float stretch = 1.0 + wave * (1.0 + r * 0.8);

    // Apply deformation anchored at face center
    vec2 distortedUV = uFaceCenter + d * stretch * uFaceScale;

    // Sample the original texture at the deformed position
    vec3 color = texture(uTexture, distortedUV).rgb;

    // Add subtle color shift only in the face region
    vec3 colorShift = vec3(0.15, -0.05, 0.1) * mask;

    fragColor = vec4(clamp(color + colorShift, 0.0, 1.0), 1.0);
}
