#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    
    // Center the effect on the face, scale with face size
    vec2 centered = (uv - uFaceCenter) * uFaceScale;
    
    // Kaleidoscope: create 8-fold symmetry using polar coordinates
    float angle = atan(centered.y, centered.x);
    float r = length(centered);
    float segments = 8.0;
    float angleSnap = floor(angle * segments / (2.0 * 3.14159)) * (2.0 * 3.14159 / segments);
    vec2 mirrored = vec2(cos(angleSnap), sin(angleSnap)) * r;
    
    // Add smooth flowing motion with time and position
    float flow = sin(uTime * 0.8 + mirrored.x * 4.0) * 0.15;
    float wave = sin(uTime * 0.5 + mirrored.y * 2.0 + flow) * 0.05;
    
    // Apply displacement with wave and center bias
    vec2 distorted = mirrored + vec2(wave, flow);
    vec2 finalUV = uFaceCenter + distorted / uFaceScale;
    
    // Sample with smooth interpolation and color warping
    vec3 col = texture(uTexture, finalUV).rgb;
    
    // Neon color glow: enhance saturation and add pulse
    float pulse = 0.5 + 0.5 * sin(uTime * 1.2);
    float saturation = 1.5 + 0.5 * sin(uTime * 0.7);
    vec3 rgb = col;
    vec3 gray = vec3(0.299, 0.587, 0.114) * rgb;
    vec3 neon = mix(gray, rgb, saturation);
    
    // Add neon glow: multiply with glowing gradient
    float glow = 0.3 + 0.7 * (1.0 - r * 2.0); // Stronger near center
    vec3 glowColor = vec3(0.0, 1.0, 1.0) * (0.8 + 0.2 * sin(uTime * 0.4));
    vec3 final = neon * (1.0 + glow * glowColor);
    
    // Final color with slight chromatic shift for dynamic feel
    float shift = sin(uTime * 0.9 + r * 3.0) * 0.01;
    vec3 result = vec3(
        texture(uTexture, finalUV + vec2(-shift, 0.0)).r,
        texture(uTexture, finalUV + vec2(0.0, shift)).g,
        texture(uTexture, finalUV + vec2(shift, 0.0)).b
    );
    
    fragColor = vec4(clamp(result * final, 0.0, 1.0), 1.0);
}
