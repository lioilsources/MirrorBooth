#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    
    // Distort around face center with smooth flowing motion
    vec2 center = uFaceCenter / uResolution;
    vec2 toCenter = uv - center;
    float dist = length(toCenter);
    float scale = uFaceScale * 0.8;
    float radius = 0.3 * (1.0 + 0.2 * sin(uTime * 0.3));
    
    // Kaleidoscope effect: mirror across 8 axes around face center
    float angle = atan(toCenter.y, toCenter.x);
    float mirroredAngle = mod(angle + 0.3926, 0.7854); // 8-fold symmetry
    float adjustedAngle = mirroredAngle < 0.3927 ? mirroredAngle : 0.7854 - mirroredAngle;
    vec2 mirrored = vec2(cos(adjustedAngle), sin(adjustedAngle)) * dist;
    
    // Smooth flow distortion with time
    float flow = sin(uTime * 0.5 + dist * 5.0) * 0.02;
    vec2 distorted = mirrored + vec2(flow * toCenter.y, -flow * toCenter.x);
    
    // Normalize to keep within bounds
    vec2 finalUV = center + (dist > radius ? distorted * (radius / dist) : distorted);
    
    // Neon color glow with chromatic shift and vibrancy
    vec3 color = texture(uTexture, finalUV).rgb;
    
    // Apply glowing neon effect with pulsing hue
    float pulse = 0.5 + 0.5 * sin(uTime * 1.2);
    vec3 neon = vec3(
        0.8 + 0.2 * sin(uTime * 0.8 + color.r * 10.0),
        0.8 + 0.2 * sin(uTime * 1.0 + color.g * 10.0),
        0.8 + 0.2 * sin(uTime * 1.4 + color.b * 10.0)
    );
    
    // Add glow by sampling nearby pixels
    vec3 glow = vec3(0.0);
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            if (i == 0 && j == 0) continue;
            vec2 offset = vec2(float(i), float(j)) * 0.005;
            glow += texture(uTexture, finalUV + offset).rgb * (1.0 - length(offset));
        }
    }
    glow *= 0.3;
    
    // Final color: neon base + glow + subtle motion blur
    vec3 finalColor = mix(color, neon, pulse) + glow;
    finalColor = pow(finalColor, vec3(0.8)); // Slight contrast boost
    
    // Enhance brightness and saturation for selfie glow
    finalColor = mix(vec3(0.5), finalColor, 1.0 + 0.3 * sin(uTime * 0.6));
    
    fragColor = vec4(clamp(finalColor, 0.0, 1.0), 1.0);
}
