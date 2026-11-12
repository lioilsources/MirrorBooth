#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 d = uv - uFaceCenter;
    float r = length(d);
    float R = max(uFaceScale * 0.55, 0.08) * (1.0 + 0.12 * sin(uTime * 1.3));
    float angle = atan(d.y, d.x);
    float distortedR = r * (1.0 + 0.6 * sin(5.0 * r) * (1.0 - r));
    float newR = mix(r, distortedR, smoothstep(0.0, 0.3, r));
    vec2 newD = vec2(cos(angle), sin(angle)) * newR;
    vec2 distortedUV = uFaceCenter + newD;
    vec3 col = texture(uTexture, clamp(distortedUV, 0.0, 1.0)).rgb;
    col *= 1.0 - 0.4 * smoothstep(0.2, 0.6, r);

    float shift = sin(uTime * 2.0 + r * 5.0) * (0.01 * (1.0 - smoothstep(R * 0.72, R * 0.6, r)));
    vec2 ref = d * 0.01;
    ref.x += shift * d.y;
    ref.y -= shift * d.x;
    vec2 refracted = uv + ref;
    vec3 refractCol = texture(uTexture, refracted).rgb;

    vec2 uv2 = FlutterFragCoord().xy / uResolution;
    vec2 d2 = uv2 - uFaceCenter;
    d2.x *= uResolution.x / uResolution.y;
    float r2 = length(d2);
    float R2 = uFaceScale;
    vec2 wUV = uv2;
    if (r2 < R2 && r2 > 0.0) {
        float theta2 = atan(d2.y, d2.x);
        float radius2 = max(abs(r2 / R2), 0.001);
        float distorted2 = pow(radius2, 1.4);
        vec2 distortedDir2 = vec2(cos(theta2), sin(theta2)) * distorted2;
        vec2 displaced2 = uFaceCenter + distortedDir2 * R2;
        wUV = mix(uv2, displaced2, smoothstep(0.7 * R2, R2, r2));
        wUV.x /= uResolution.x / uResolution.y;
    }

    vec3 finalCol = texture(uTexture, wUV).rgb;
    finalCol *= 1.0 - 0.4 * smoothstep(0.2, 0.6, r2);

    fragColor = vec4(mix(finalCol, refractCol, 0.3), 1.0);
}
