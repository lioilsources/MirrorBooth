#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter / uResolution;
    float scale = uFaceScale;
    vec2 c = (uv - center) * scale;
    float aspect = uResolution.x / uResolution.y;
    c.x *= aspect;

    // Screen curvature: radial distortion with dynamic center shift
    float r = length(c);
    float bend = 0.18 * r * (1.0 - 0.6 * r);
    c *= (1.0 + bend);

    // Shadow mask: alternating RGB stripes using vertical frequency
    float stripe = mod(uv.y * 280.0 + uTime * 7.0, 3.0);
    float maskStripes = step(0.33, stripe) - step(0.66, stripe);

    // Chroma bleed: lateral color displacement with time-varying amplitude
    float amplitude = 0.002 * (1.0 + 0.5 * sin(uv.y * 150.0 + uTime * 4.0));
    vec2 chromaOffset = vec2(amplitude * sin(uv.y * 250.0 + uTime * 3.0), 0.0);
    vec3 base = texture(uTexture, uv).rgb;
    vec3 colored = vec3(
        texture(uTexture, uv + chromaOffset).r,
        base.g,
        texture(uTexture, uv - chromaOffset).b
    );

    // Scanlines: high-frequency vertical modulation with phase shift
    float scan = 0.6 + 0.4 * cos(FlutterFragCoord().y * 32.0 + uTime * 12.0);
    vec3 withScan = colored * scan;

    // Tracking error: horizontal jitter with wave interference
    float jitter = 0.004 * sin(uv.y * 90.0 + uTime * 11.0) * cos(uv.x * 100.0);
    vec2 offsetUv = uv + vec2(jitter, 0.0);
    vec3 warpedColor = texture(uTexture, offsetUv).rgb;

    // Additive glow blur from other filter: radial sampling with intensity based on distance from face
    float dist = abs(uv.y - uFaceCenter.y / uResolution.y);
    float amt = smoothstep(0.12, 0.42, dist);
    vec2 rad = amt * 9.0 / uResolution;
    vec3 acc = warpedColor;
    for (int i = 0; i < 12; i++) {
        float a = 2.3999632 * float(i);
        float r = sqrt((float(i) + 0.5) / 12.0);
        acc += texture(uTexture, uv + vec2(cos(a), sin(a)) * r * rad).rgb;
    }
    vec3 col = acc / 13.0;

    // Final composite with mask and dynamic contrast
    vec3 finalColor = col * (0.7 + 0.3 * maskStripes);
    finalColor *= 0.95 + 0.05 * sin(uv.y * 45.0 + uTime * 9.0);

    // CRT glow: brightness-based bloom with gamma correction
    float brightness = dot(finalColor, vec3(0.3, 0.59, 0.11));
    finalColor *= (0.85 + 1.15 * pow(brightness, 0.7));

    fragColor = vec4(finalColor, 1.0);
}
