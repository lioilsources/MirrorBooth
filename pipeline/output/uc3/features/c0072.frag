#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float R = uFaceScale;

    float dx = uv.x - uFaceCenter.x;
    float dy = uv.y - uFaceCenter.y;

    // Focus on facial features: exaggerate the nose, mouth, and eyes
    float faceMask = exp(-(dx * dx + dy * dy) / (0.5 * R * R));

    // Enlarge the nose: push pixels toward the center horizontally and vertically
    float noseX = uFaceCenter.x + dx * (1.0 + 0.8 * faceMask * (1.0 - abs(dy - uFaceCenter.y) / (0.2 * R)));
    float noseY = uFaceCenter.y + dy * (1.0 + 1.2 * faceMask * (1.0 - abs(dx - uFaceCenter.x) / (0.3 * R)));

    // Enlarge the mouth: vertically stretch below the center
    float mouthY = uFaceCenter.y + dy * (1.0 + 0.9 * smoothstep(0.3 * R, 0.0, dy - uFaceCenter.y) * faceMask);

    // Enlarge the eyes: push them outward and upward, then scale up
    float eyeOffset = 0.15 * R;
    float eyeX = uFaceCenter.x + dx * (1.0 + 0.7 * faceMask * smoothstep(0.0, 0.2 * R, abs(dy - uFaceCenter.y - eyeOffset)));
    float eyeY = uFaceCenter.y + dy * (1.0 + 0.6 * faceMask * smoothstep(0.0, 0.2 * R, abs(dy - uFaceCenter.y - eyeOffset)));

    // Blend the transformed coordinates based on feature proximity
    vec2 srcUV = vec2(
        mix(uv.x, noseX, faceMask * 0.8),
        mix(uv.y, mouthY, faceMask * 0.6)
    );

    // Apply eye exaggeration only near the eye region
    srcUV = vec2(
        mix(srcUV.x, eyeX, smoothstep(0.1 * R, 0.0, abs(dy - uFaceCenter.y - eyeOffset))),
        mix(srcUV.y, eyeY, smoothstep(0.1 * R, 0.0, abs(dy - uFaceCenter.y - eyeOffset)))
    );

    vec2 wUV = clamp(srcUV, 0.0, 1.0);
    fragColor = vec4(texture(uTexture, wUV).rgb, 1.0);
}
