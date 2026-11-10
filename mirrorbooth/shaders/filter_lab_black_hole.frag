#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float aspect = uResolution.x / uResolution.y;
    vec2 d = uv - uFaceCenter;
    d.x *= aspect;
    float r = max(length(d), 0.0001);
    float R = max(uFaceScale * 0.55, 0.08) * (1.0 + 0.12 * sin(uTime * 1.3));
    float bend = (R * R) / (r * r);
    vec2 sd = d * (1.0 - bend);
    sd.x /= aspect;
    vec2 suv = uFaceCenter + sd;
    suv = abs(mod(suv, 2.0) - 1.0);
    suv = 1.0 - suv;
    vec3 col = texture(uTexture, clamp(suv, 0.0, 1.0)).rgb;
    float core = smoothstep(R * 0.72, R * 0.6, r);
    float ring = exp(-pow((r - R) / (R * 0.12), 2.0));
    float swirl = 0.5 + 0.5 * sin(atan(d.y, d.x) * 3.0 - uTime * 3.0);
    col = mix(col, vec3(0.0), core);
    col += vec3(1.0, 0.62, 0.25) * ring * (0.5 + 0.7 * swirl);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
