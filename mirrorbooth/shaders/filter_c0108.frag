#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = vec2(0.5, 0.5);
    float angle = uTime * 0.8;
    float radius = length(uv - center);
    float rot = atan(uv.y - center.y, uv.x - center.x) + angle;

    // Kaleidoscope effect: mirror across 6 axes
    int slices = 6;
    float sliceAngle = 2.0 * 3.14159 / float(slices);
    float slice = floor((rot + sliceAngle * 0.5) / sliceAngle);
    float mirroredAngle = rot - slice * sliceAngle;

    // Map back to one slice with mirrored coordinates
    vec2 mirroredUV = vec2(
        cos(mirroredAngle) * radius,
        sin(mirroredAngle) * radius
    );
    mirroredUV += center;

    // Smooth flow distortion using time and noise
    float flow = sin(uTime * 0.6 + radius * 8.0) * 0.05;
    float noise = fract(sin(dot(mirroredUV, vec2(12.9898, 78.233))) * 43758.5453);
    float distortion = flow + noise * 0.03;

    // Apply smooth kaleidoscopic flow
    vec2 flowUV = mirroredUV + vec2(
        sin(mirroredAngle * 4.0 + uTime * 1.2) * distortion,
        cos(mirroredAngle * 4.0 + uTime * 1.0) * distortion
    );

    // Sample with edge clamping to avoid seams
    vec3 col = texture(uTexture, clamp(flowUV, 0.0, 1.0)).rgb;

    // Neon color bloom: enhance saturation and add glow
    float intensity = length(col);
    vec3 neon = vec3(
        0.8 + 0.2 * sin(uTime * 0.3 + intensity * 10.0),
        0.2 + 0.8 * sin(uTime * 0.3 + intensity * 10.0 + 2.0),
        1.0
    );
    col = mix(col, neon, 0.6 * (intensity - 0.5));

    // Add subtle chromatic glow based on radial distance
    float glow = smoothstep(0.6, 1.0, radius);
    col += glow * vec3(0.3, 0.1, 0.8);

    // Final color clamping and output
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
