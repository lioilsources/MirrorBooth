#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonColor(float t) {
    float r = 0.5 + 0.5 * sin(t * 0.6 + 0.0);
    float g = 0.5 + 0.5 * sin(t * 0.6 + 2.0);
    float b = 0.5 + 0.5 * sin(t * 0.6 + 4.0);
    return vec3(r, g, b) * 2.0;
}

vec2 kaleidoscope(vec2 uv, float segments, float angleOffset) {
    vec2 centered = uv - 0.5;
    float r = length(centered);
    float a = atan(centered.y, centered.x) + angleOffset;
    float segment = floor(a / (6.2831853 / segments));
    float inv = mod(segment + 1.0, segments);
    float invAngle = a - (segment * (6.2831853 / segments));
    float newAngle = invAngle + (6.2831853 / segments) * (inv - 1.0);
    return 0.5 + r * vec2(cos(newAngle), sin(newAngle));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    
    // Dynamic kaleidoscope with face-centered focus
    float segments = 12.0 + 4.0 * sin(uTime * 0.3);
    float angleOffset = uTime * 0.6;
    vec2 kuv = kaleidoscope(uv, segments, angleOffset);
    
    // Smooth wave distortion centered on face
    vec2 faceDist = uv - uFaceCenter;
    float distFromFace = length(faceDist * uFaceScale);
    float ripple = 0.015 * sin(distFromFace * 18.0 + uTime * 3.0 + faceDist.x * 2.0);
    float swirl = 0.01 * sin(uTime * 1.5) * (1.0 - distFromFace * 2.0);
    kuv += faceDist * (ripple + swirl);
    
    // Enhanced kaleidoscopic warping with color variation
    vec3 col = texture(uTexture, kuv).rgb;
    
    // Intensified neon glow with animated color pulses
    vec3 neon = neonColor(uTime * 1.1);
    col = mix(col, neon, 0.5 + 0.3 * sin(uTime * 0.8));
    
    // Dynamic pulse and glow based on motion
    float pulse = 0.7 + 0.3 * sin(uTime * 1.5);
    col *= (1.0 + 0.9 * pulse);
    
    // Edge glow that follows facial contours
    float edge = 1.0 - smoothstep(0.0, 0.08, distFromFace);
    vec3 glow = neon * (0.8 + 0.2 * sin(uTime * 2.0));
    col = mix(col, glow, edge * 0.4);
    
    // Color saturation boost and vibrancy
    col = pow(col, vec3(0.7));
    col = mix(col, vec3(1.0), 0.05);
    
    // Final tone mapping and bloom-like highlight
    col = clamp(col, 0.0, 1.0);
    col = pow(col, vec3(0.95));
    
    fragColor = vec4(col, 1.0);
}
