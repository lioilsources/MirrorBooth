#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // Eye band sits above the face center; one horizontally stretched bulge
    // covers both eyes.
    vec2 e = vec2(uFaceCenter.x, uFaceCenter.y - 0.35 * uFaceScale);
    vec2 d = uv - e;
    d.x *= uResolution.x / uResolution.y;

    vec2 k = d;
    k.x *= 0.6;  // widen the kernel horizontally into a band
    float sigma = 0.35 * uFaceScale;
    float w = exp(-dot(k, k) / (sigma * sigma));

    // Sampling closer to the band center magnifies the eyes
    vec2 src = d * (1.0 - 0.25 * w);
    src.x /= uResolution.x / uResolution.y;
    vec2 wUV = clamp(e + src, 0.0, 1.0);

    vec3 col = texture(uTexture, wUV).rgb;

    // Brighten + pastel: mild desaturation with a faint pink cast
    col = pow(clamp(col, 0.0, 1.0), vec3(0.85));
    float l = lum(col);
    col = mix(vec3(l), col, 0.8) + vec3(0.04, 0.01, 0.03);

    // Transfer: Apply funhouse-style distortion from the other filter to enhance the eye area
    vec2 dDistort = (uv - uFaceCenter) / uFaceScale;
    float r = length(dDistort);
    float mask = exp(-r * r * 2.0);
    float wave = 0.5 * mask * (1.0 + cos(12.0 * dDistort.x + 9.0 * dDistort.y + 3.0 * uFaceScale));
    float stretch = 1.0 + wave * (1.0 + r * 0.8);
    vec2 distortedUV = uFaceCenter + dDistort * stretch * uFaceScale;

    // Sample the original texture at the deformed position
    vec3 color = texture(uTexture, distortedUV).rgb;

    // Add subtle color shift only in the face region
    vec3 colorShift = vec3(0.15, -0.05, 0.1) * mask;

    // Blend the distorted color into the eye-enhanced color, with emphasis on the eye region
    float eyeMask = smoothstep(0.0, 0.5, length(uv - e) / (0.3 * uFaceScale));
    col = mix(col, color + colorShift, eyeMask * 0.7);

    // Add a sparkle of light in the iris: small bright spot with a glow
    vec2 irisCenter = e + vec2(0.0, 0.02 * uFaceScale); // Slight offset toward center of eye band
    float distToIris = length(uv - irisCenter);
    float sparkle = exp(-distToIris * distToIris * 500.0) * (1.0 - 0.7 * w); // Fades with eye band weight
    vec3 sparkleColor = vec3(1.0, 0.9, 0.7) * 5.0 * sparkle;
    col += sparkleColor;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
