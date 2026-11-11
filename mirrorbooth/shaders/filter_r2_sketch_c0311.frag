#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float hash21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 src = texture(uTexture, uv).rgb;
    float l = pow(luma(src), 0.65) * 1.35;
    
    vec2 faceOffset = (uv - uFaceCenter) * uFaceScale;
    float edgeIntensity = step(0.3, length(faceOffset));
    
    float n = hash21(FlutterFragCoord().xy * 0.7 + uTime * 47.0);
    l += (n - 0.5) * 0.22;
    
    float angle = sin(uTime * 0.3) * 0.4 + 0.2;
    float hatching = sin(uv.x * 150.0 + uv.y * 120.0 + angle * 10.0);
    
    float line = abs(fract(hatching * 0.5 + l * 0.3) - 0.5) * 2.0;
    float w = 1.0 - l;
    float ink = mix(0.0, 1.0, smoothstep(w + 0.05, w - 0.05, line));
    
    vec3 col = mix(vec3(0.95, 0.97, 0.9), vec3(0.1, 0.2, 0.15), ink);
    col *= l;
    
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
