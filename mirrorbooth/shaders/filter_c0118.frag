#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 rotate(vec2 v, float a) {
    float s = sin(a), c = cos(a);
    return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

float smoothEdge(float x) {
    return smoothstep(0.1, 0.9, x);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter * uFaceScale + (1.0 - uFaceScale) * 0.5;
    vec2 p = uv - center;
    float r = length(p);
    float angle = atan(p.y, p.x);
    float time = uTime * 0.2;

    // 8-fold kaleidoscope symmetry with smooth rotation and wave distortion
    float n = 8.0;
    float snappedAngle = floor(angle * n / 6.28318 + 0.5) * (6.28318 / n);
    float swirl = sin(time * 0.3) * 0.06;
    float distortion = sin(r * 12.0 + time * 0.8) * 0.1;
    float distortedAngle = snappedAngle + swirl + distortion;
    vec2 distortedP = rotate(p, distortedAngle);
    float scale = 1.0 + 0.15 * sin(r * 10.0 + time * 0.6);
    distortedP *= scale;

    // Final mirrored UV with smooth blending across symmetry axes
    vec2 mirroredUv = distortedP + center;

    // Sample texture with smooth interpolation
    vec3 color = texture(uTexture, mirroredUv).rgb;

    // Dynamic neon color cycle based on time and radial position
    float hue = fract((angle / 6.28318 + time * 0.12) * 0.7);
    float h6 = hue * 6.0;
    float c = 1.0;
    float x = c * (1.0 - abs(mod(h6, 2.0) - 1.0));
    vec3 neon;
    if      (h6 < 1.0) neon = vec3(c, x, 0.0);
    else if (h6 < 2.0) neon = vec3(x, c, 0.0);
    else if (h6 < 3.0) neon = vec3(0.0, c, x);
    else if (h6 < 4.0) neon = vec3(0.0, x, c);
    else if (h6 < 5.0) neon = vec3(x, 0.0, c);
    else               neon = vec3(c, 0.0, x);

    // Add flowing glow intensity with radial falloff and pulsing
    float pulse = 0.5 + 0.5 * sin(time * 1.2 + r * 8.0);
    float radialGlow = 1.0 - smoothEdge(r * 1.8);
    float edgeGlow = smoothEdge(r * 3.0);
    float glow = radialGlow * edgeGlow * pulse;

    // Enhance glow with directional flow and face-aware intensity
    float faceDist = length(uv - center);
    float faceIntensity = 1.0 - smoothstep(0.2, 0.5, faceDist);
    glow *= faceIntensity * 1.5;

    // Final composite: color + glow + subtle bloom
    vec3 finalColor = color * (1.0 + 0.7 * glow) + neon * glow * 2.0;

    // Add soft vignette and depth to emphasize center
    float vignette = pow(1.0 - r * 1.2, 0.6);
    finalColor *= vignette;

    // Slight color grade to enhance neon feel
    finalColor = pow(finalColor, vec3(0.85));
    finalColor *= vec3(1.1, 1.05, 1.2);

    // Final clamp and output
    fragColor = vec4(clamp(finalColor, 0.0, 1.0), 1.0);
}
