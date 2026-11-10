#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec3 neonColor(float t) {
    float r = 0.5 + 0.5 * sin(t * 0.8 + 0.0);
    float g = 0.5 + 0.5 * sin(t * 0.8 + 2.1);
    float b = 0.5 + 0.5 * sin(t * 0.8 + 4.2);
    return vec3(r, g, b) * 1.8;
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
    float angleOffset = uTime * 0.6 + 0.5 * sin(uTime * 0.8);
    vec2 kuv = kaleidoscope(uv, segments, angleOffset);
    
    // Enhanced distortion based on face center and scale
    vec2 faceDist = uv - uFaceCenter;
    float distFromFace = length(faceDist * uFaceScale);
    float ripple = 0.015 * sin(distFromFace * 20.0 + uTime * 2.5);
    float swirl = 0.008 * sin(uTime * 1.8) * (1.0 - distFromFace);
    vec2 swirlDir = vec2(-faceDist.y, faceDist.x);
    kuv += faceDist * (ripple + swirl * length(faceDist));
    
    // Sample with high-quality interpolation and dynamic color shift
    vec3 col = texture(uTexture, kuv).rgb;
    
    // Intensified neon glow with time-varying pulse
    vec3 neon = neonColor(uTime);
    float glowStrength = 0.6 + 0.4 * sin(uTime * 1.4);
    col = mix(col, neon, glowStrength);
    
    // Dynamic edge glow with face proximity
    float edge = smoothstep(0.0, 0.03, distFromFace);
    vec3 edgeGlow = neon * (0.5 + 0.5 * sin(uTime * 0.7));
    col = mix(col, edgeGlow, edge * 0.5);
    
    // Add subtle color modulation and saturation boost
    col = pow(col, vec3(0.75));
    col = mix(col, vec3(1.0), 0.08);
    col *= (1.0 + 0.3 * sin(uTime * 0.9));
    
    // Final color balance and luminance enhancement
    col = clamp(col, 0.0, 1.0);
    col = mix(col, vec3(1.0), 0.05);
    
    fragColor = vec4(col, 1.0);
}
