#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

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
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float time = uTime * 0.15;
    
    // Kaleidoscope effect: 6-fold symmetry with smooth rotation
    float angle = atan(p.y, p.x);
    float r = length(p);
    float n = 6.0;
    float snappedAngle = floor(angle * n / 6.28318 + 0.5) * (6.28318 / n);
    float swirl = sin(time * 0.3) * 0.05;
    float distortedAngle = snappedAngle + swirl;
    vec2 distortedP = rotate(p, distortedAngle);
    float distortionFactor = 1.0 + 0.1 * sin(r * 10.0 + time * 0.5);
    distortedP *= distortionFactor;
    
    // Mirror across 6 axes with smooth blending
    vec2 mirroredUv = distortedP + center;
    
    // Sample with smooth interpolation between mirrored sections
    vec3 color = texture(uTexture, mirroredUv).rgb;
    
    // Add flowing neon glow with time-based animation
    float pulse = 0.5 + 0.5 * sin(time * 1.0 + r * 10.0);
    float hue = fract((angle / 6.28318 + time * 0.1) * 0.6);
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
    
    // Add dynamic edge glow with radial variation
    float radialGlow = 1.0 - smoothEdge(r * 2.0);
    float edgeStrength = smoothEdge(r * 4.0);
    float glow = radialGlow * edgeStrength * pulse;
    
    // Final color with intensity modulation
    vec3 finalColor = color * (1.0 + 0.5 * glow) + neon * glow * 1.5;
    
    // Add subtle camera glow for neon aesthetic
    float vignette = 1.0 - 1.5 * r * r;
    finalColor *= vignette;
    
    fragColor = vec4(clamp(finalColor, 0.0, 1.0), 1.0);
}
