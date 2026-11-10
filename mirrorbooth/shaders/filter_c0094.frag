#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float rand(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 neonHue(float t) {
    return 0.5 + 0.5 * sin(t + vec3(0.0, 2.094, 4.188));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    
    // Kaleidoscope: mirror across 6 axes (hexagonal symmetry)
    vec2 p = uv - 0.5;
    float angle = atan(p.y, p.x);
    float r = length(p);
    float sectors = 6.0;
    angle = mod(angle, 2.0 * 3.14159 / sectors);
    angle = min(angle, 2.0 * 3.14159 / sectors - angle);
    p = vec2(cos(angle), sin(angle)) * r;
    p += 0.5;
    
    // Add subtle flow based on time and position
    float flow = rand(uv * 100.0 + uTime * 0.5) * 0.01;
    p += vec2(sin(uTime * 0.5 + p.x * 5.0), cos(uTime * 0.7 + p.y * 4.0)) * flow;
    
    // Sample with kaleidoscopic distortion
    vec3 col = texture(uTexture, p).rgb;
    
    // Apply smooth flowing neon glow with color shift
    float pulse = 0.5 + 0.5 * sin(uTime * 1.8);
    vec3 neon = neonHue(uTime * 0.8);
    col = mix(col, neon, pulse * 0.4);
    
    // Enhance brightness and contrast for neon effect
    col = pow(col, vec3(0.8));
    col = (col - 0.5) * 1.8 + 0.5;
    col = clamp(col, 0.0, 1.0);
    
    // Add glowing edge halo
    float edge = 1.0 - length(uv - 0.5);
    vec3 halo = neon * pow(edge, 2.0) * (1.0 + 0.5 * sin(uTime * 3.0));
    col = mix(col, halo, smoothstep(0.85, 1.0, edge));
    
    // Add subtle radial gradient glow
    float radial = 1.0 - length(uv - 0.5);
    float glow = pow(radial, 3.0) * 0.6;
    col += glow * neon * 0.8;
    
    // Final color clamping
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
