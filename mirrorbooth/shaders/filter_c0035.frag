#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float lum(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

// Smooth, flowing kaleidoscope with radial symmetry and dynamic color motion
void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float radius = length(p);
    float angle = atan(p.y, p.x);

    // Kaleidoscope: 6-fold symmetry (hexagonal reflection)
    float segments = 6.0;
    float angleMod = mod(angle * segments, 6.28318);
    float angleReflected = min(angleMod, 6.28318 - angleMod);
    vec2 mirrored = vec2(cos(angleReflected), sin(angleReflected)) * radius;

    // Add a slow, smooth flow to the reflection pattern
    float flow = sin(uTime * 0.1 + radius * 3.0) * 0.05;
    float flowAngle = angleReflected + flow;
    vec2 flowOffset = vec2(cos(flowAngle), sin(flowAngle)) * radius * 0.05;
    vec2 finalPos = center + mirrored + flowOffset;

    // Ensure we stay within bounds
    finalPos = clamp(finalPos, vec2(0.0), vec2(1.0));

    // Sample the original texture with the transformed UV
    vec3 baseColor = texture(uTexture, finalPos).rgb;

    // Add a dynamic neon glow with flowing hue
    float hue = fract((angleReflected / 6.28318) + uTime * 0.08);
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

    // Enhance with radial intensity: stronger at center, fading outward
    float radialIntensity = smoothstep(0.4, 0.0, radius);
    float edgeStrength = smoothstep(0.2, 0.5, radius);
    float glowIntensity = smoothstep(0.0, 0.3, radius) * 0.8;

    // Combine base color with neon glow, modulated by flow and radial effect
    vec3 finalColor = baseColor * (1.0 - glowIntensity) + neon * glowIntensity * 1.2;
    finalColor *= (1.0 + radialIntensity * 0.5);

    // Add a subtle edge bloom using a small blur kernel
    vec2 px = 1.0 / uResolution;
    float blur = 0.0;
    blur += lum(texture(uTexture, finalPos + vec2(-px.x, -px.y)).rgb) * 0.1;
    blur += lum(texture(uTexture, finalPos + vec2( 0.0, -px.y)).rgb) * 0.2;
    blur += lum(texture(uTexture, finalPos + vec2( px.x, -px.y)).rgb) * 0.1;
    blur += lum(texture(uTexture, finalPos + vec2(-px.x,  0.0)).rgb) * 0.2;
    blur += lum(texture(uTexture, finalPos + vec2( 0.0,  0.0)).rgb) * 0.4;
    blur += lum(texture(uTexture, finalPos + vec2( px.x,  0.0)).rgb) * 0.2;
    blur += lum(texture(uTexture, finalPos + vec2(-px.x,  px.y)).rgb) * 0.1;
    blur += lum(texture(uTexture, finalPos + vec2( 0.0,  px.y)).rgb) * 0.2;
    blur += lum(texture(uTexture, finalPos + vec2( px.x,  px.y)).rgb) * 0.1;

    // Blend glow with final color
    finalColor += neon * 0.5 * smoothstep(0.0, 0.1, blur);

    // Final output with smooth saturation and brightness
    finalColor = mix(baseColor, finalColor, smoothstep(0.3, 0.8, radius));
    finalColor = clamp(finalColor, 0.0, 1.0);

    fragColor = vec4(finalColor, 1.0);
}
