#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 src = texture(uTexture, uv).rgb;
    float c = luma(src);
    
    // Apply face-centered distortion for localized sketch effect
    vec2 faceOffset = (uv - uFaceCenter) * uFaceScale;
    float mask = step(0.3, length(faceOffset));
    
    // Edge detection using step for sharp contrast (from Shader B)
    vec2 d = 1.2 / uResolution;
    float l = luma(texture(uTexture, uv - vec2(d.x, 0.0)).rgb);
    float r = luma(texture(uTexture, uv + vec2(d.x, 0.0)).rgb);
    float t = luma(texture(uTexture, uv - vec2(0.0, d.y)).rgb);
    float b = luma(texture(uTexture, uv + vec2(0.0, d.y)).rgb);
    float edge = step(0.15, length(vec2(r - l, b - t)) * 6.0);
    
    // Use fract to create a grainy line pattern driven by brightness (replaces smoothstep)
    float pattern = fract(sin(uv.x * 37.0 + uv.y * 19.0 + c * 15.0) * 120.0);
    float hatching = step(0.4, pattern);
    
    // Use mix to blend hatching with edge mask based on brightness (from Shader B)
    float shade = mix(1.0, hatching, step(c, 0.5));
    shade *= 1.0 - edge;
    
    // Use sin to create dynamic line density variation over time (replaces fract-based line spacing)
    float lineDensity = sin(uv.x * 20.0 + uTime * 0.7) * 0.5 + 0.5;
    float line = fract(uv.y * 30.0 + c * 2.0 + lineDensity * 5.0);
    float ink = step(0.4, abs(line - 0.5));
    
    // Combine ink and hatching using mix (from Shader A), with face mask influence
    float finalInk = mix(ink, shade, 0.7);
    
    // Use mix to blend with time-dependent brightness modulation (replaces sinusoidal variation)
    float variation = mix(0.7, 1.0, fract(uTime * 0.1 + c * 0.3));
    float inkFinal = mix(finalInk, variation, c);
    
    // Final color: dark ink on light paper, modulated by brightness and edge
    vec3 col = mix(vec3(0.95, 0.95, 0.9), vec3(0.0, 0.0, 0.0), inkFinal);
    col *= c;
    
    // Apply mask to preserve face center integrity
    col = mix(col, vec3(0.95), mask);
    
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
