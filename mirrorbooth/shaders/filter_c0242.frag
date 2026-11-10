#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float lum(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

// Enhanced kaleidoscope mirror with neon flow, dynamic symmetry, and facial alignment
void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float radius = length(p);
    float angle = atan(p.y, p.x);

    // Dynamic 8-fold symmetry with time-varying segment count for visual rhythm
    float segments = 8.0 + sin(uTime * 0.3) * 2.0;
    float angleMod = mod(angle * segments, 6.28318);
    float angleReflected = min(angleMod, 6.28318 - angleMod);
    vec2 mirrored = vec2(cos(angleReflected), sin(angleReflected)) * radius;

    // Flow distortion: smooth wave motion with radial modulation
    float flowStrength = sin(uTime * 0.2 + radius * 5.0) * 0.08;
    float flowAngle = angleReflected + flowStrength * (1.0 - radius);
    vec2 flowOffset = vec2(cos(flowAngle), sin(flowAngle)) * radius * 0.04;
    vec2 finalPos = center + mirrored + flowOffset;

    // Clamp to bounds
    finalPos = clamp(finalPos, vec2(0.0), vec2(1.0));

    // Sample original texture with transformed coordinates
    vec3 baseColor = texture(uTexture, finalPos).rgb;

    // Neon color flow: animated hue cycle with smooth interpolation
    float hue = fract((angleReflected / 6.28318) + uTime * 0.12);
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

    // Radial intensity: bright center, fading edges with softness
    float radialIntensity = smoothstep(0.3, 0.0, radius);
    float edgeMask = smoothstep(0.1, 0.4, radius);
    float glowIntensity = smoothstep(0.0, 0.25, radius) * 1.0;

    // Combine base with neon glow, enhanced by radial and edge effects
    vec3 finalColor = baseColor * (1.0 - glowIntensity) + neon * glowIntensity * 1.5;
    finalColor *= (1.0 + radialIntensity * 0.8);

    // Add dynamic edge bloom with directional blur for neon glow
    vec2 px = 1.0 / uResolution;
    float blur = 0.0;
    blur += lum(texture(uTexture, finalPos + vec2(-px.x, -px.y)).rgb) * 0.05;
    blur += lum(texture(uTexture, finalPos + vec2( 0.0, -px.y)).rgb) * 0.15;
    blur += lum(texture(uTexture, finalPos + vec2( px.x, -px.y)).rgb) * 0.05;
    blur += lum(texture(uTexture, finalPos + vec2(-px.x,  0.0)).rgb) * 0.15;
    blur += lum(texture(uTexture, finalPos + vec2( 0.0,  0.0)).rgb) * 0.3;
    blur += lum(texture(uTexture, finalPos + vec2( px.x,  0.0)).rgb) * 0.15;
    blur += lum(texture(uTexture, finalPos + vec2(-px.x,  px.y)).rgb) * 0.05;
    blur += lum(texture(uTexture, finalPos + vec2( 0.0,  px.y)).rgb) * 0.15;
    blur += lum(texture(uTexture, finalPos + vec2( px.x,  px.y)).rgb) * 0.05;

    // Enhance glow with edge mask and flow modulation
    finalColor += neon * 0.6 * smoothstep(0.0, 0.1, blur) * edgeMask;

    // Final blending: emphasize center, preserve facial features
    float centerBoost = smoothstep(0.0, 0.3, radius);
    finalColor = mix(baseColor, finalColor, centerBoost * 1.2);

    // Add subtle saturation boost and brightness for neon pop
    finalColor = pow(finalColor, vec3(0.8));
    finalColor = clamp(finalColor, 0.0, 1.0);

    fragColor = vec4(finalColor, 1.0);
}
