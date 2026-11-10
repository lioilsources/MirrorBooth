#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 rotate(vec2 v, float a) {
    float s = sin(a), c = cos(a);
    return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

float smoothEdge(float x) {
    return smoothstep(0.1, 0.9, x);
}

vec3 neonHSL(float hue, float sat, float light) {
    float c = (1.0 - abs(2.0 * light - 1.0)) * sat;
    float x = c * (1.0 - abs(mod(hue * 6.0, 2.0) - 1.0));
    float m = light - c / 2.0;
    vec3 ne = vec3(0.0);
    if      (hue < 1.0/6.0) ne = vec3(c, x, 0.0);
    else if (hue < 2.0/6.0) ne = vec3(x, c, 0.0);
    else if (hue < 3.0/6.0) ne = vec3(0.0, c, x);
    else if (hue < 4.0/6.0) ne = vec3(0.0, x, c);
    else if (hue < 5.0/6.0) ne = vec3(x, 0.0, c);
    else                    ne = vec3(c, 0.0, x);
    return ne + vec3(m);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = uFaceCenter * uFaceScale + vec2(0.5) * (1.0 - uFaceScale);
    vec2 p = (uv - center) * uFaceScale;
    float r = length(p);
    float time = uTime * 0.12;
    
    // 8-fold kaleidoscope with smooth rotation and dynamic symmetry
    float angle = atan(p.y, p.x);
    float n = 8.0;
    float snappedAngle = floor(angle * n / 6.28318 + 0.5) * (6.28318 / n);
    float swirl = sin(time * 0.3) * 0.06;
    float distortedAngle = snappedAngle + swirl;
    vec2 distortedP = rotate(p, distortedAngle);
    
    // Radial distortion for flowing motion
    float distortionFactor = 1.0 + 0.15 * sin(r * 12.0 + time * 0.8) * (1.0 - r * 0.8);
    distortedP *= distortionFactor;
    
    // Mirror across 8 axes with smooth blending
    vec2 mirroredUv = distortedP + center;
    
    // Sample with smooth interpolation between mirrored sections
    vec3 color = texture(uTexture, mirroredUv).rgb;
    
    // Neon glow with time-varying hue and pulsing intensity
    float pulse = 0.5 + 0.5 * sin(time * 1.0 + r * 10.0 + uTime * 0.05);
    float hue = fract((angle / 6.28318 + time * 0.15) * 0.7);
    vec3 neon = neonHSL(hue, 1.0, 0.8) * 1.2;
    
    // Dynamic edge glow with radial falloff and sharpness
    float radialGlow = 1.0 - smoothEdge(r * 2.0);
    float edgeStrength = smoothEdge(r * 4.0);
    float glow = radialGlow * edgeStrength * pulse * 1.5;
    
    // Add soft bloom and color intensity boost
    vec3 finalColor = color * (1.0 + 0.7 * glow) + neon * glow;
    
    // Apply subtle chromatic aberration for neon feel
    vec2 offset = vec2(0.002, 0.001) * sin(time * 0.7);
    finalColor = vec3(
        texture(uTexture, mirroredUv + offset).r,
        texture(uTexture, mirroredUv).g,
        texture(uTexture, mirroredUv - offset).b
    ) * (1.0 + 0.3 * glow) + neon * glow * 1.3;
    
    // Add soft vignette with dynamic centering
    vec2 vig = uv * 2.0 - 1.0;
    float vignette = pow(clamp(1.0 - dot(vig * 0.4, vig * 0.4), 0.0, 1.0), 0.5);
    finalColor *= mix(0.9, 1.0, vignette);
    
    // Final color correction for neon vibrancy
    finalColor = pow(clamp(finalColor, 0.0, 1.0), vec3(0.9));
    finalColor *= vec3(1.1, 1.05, 1.2);
    
    fragColor = vec4(clamp(finalColor, 0.0, 1.0), 1.0);
}
