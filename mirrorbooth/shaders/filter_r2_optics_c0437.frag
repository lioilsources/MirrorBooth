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
    float aspect = uResolution.x / uResolution.y;
    d.x *= aspect;
    float r = max(length(d), 0.0001);
    float R = uFaceScale * 0.5;

    // Apply fisheye distortion centered on face using length and max
    float distortion = 0.8 * (1.0 - r / R);
    float distortedR = r * (1.0 + distortion);
    vec2 theta = d / max(r, 0.0001);
    vec2 distortedUV = uFaceCenter + theta * distortedR;
    distortedUV.x /= aspect;

    // Sample distorted texture
    vec3 col = texture(uTexture, distortedUV).rgb;

    // Add bulge effect with max and abs
    float bulge = max(0.0, 1.0 - (r / R));
    float absDist = abs(bulge - 0.5);
    col *= (0.9 + 0.2 * absDist);

    // Apply twirl effect based on angle and time
    float angle = atan(d.y, d.x);
    float twirl = 0.5 + 0.5 * sin(angle * 4.0 + uTime * 2.0);
    col *= (0.8 + 0.2 * twirl);

    // Final glass refraction layer with refraction strength modulated by time
    vec2 d2 = uv - uFaceCenter;
    d2.x *= aspect;
    float depth = max(abs(d2.x), abs(d2.y));
    float refractFactor = 0.4 * (1.0 + 0.6 * sin(uTime * 1.8));
    vec2 refractDir = d2 * (1.0 + refractFactor * depth);
    vec2 refUV = uFaceCenter + refractDir;
    refUV.x /= aspect;
    vec3 refractCol = texture(uTexture, clamp(refUV, 0.0, 1.0)).rgb;
    float refMask = smoothstep(0.3, 0.2, depth);
    col = mix(col, refractCol, refMask * 0.4);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
