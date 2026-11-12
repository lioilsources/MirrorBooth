#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 glassRefraction(vec2 uv, vec2 center, float strength, float radius) {
    vec2 d = uv - center;
    float r = length(d);
    float theta = atan(d.y, d.x);
    float distortedR = r + strength * r * r * (1.0 - r / radius);
    return center + vec2(cos(theta), sin(theta)) * distortedR;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float aspect = uResolution.x / uResolution.y;
    float R = uFaceScale;

    vec2 d = uv - uFaceCenter;
    d.x *= aspect;

    float distortStrength = 0.8;
    float maxDist = 0.4 * R;

    vec2 distortedUV = glassRefraction(uv, uFaceCenter, distortStrength, maxDist);
    distortedUV.x /= aspect;

    vec2 wUV = clamp(uFaceCenter + (distortedUV - uFaceCenter) * 1.2, 0.0, 1.0);

    vec3 col = texture(uTexture, wUV).rgb;

    col = pow(clamp(col, 0.0, 1.0), vec3(0.85));

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
