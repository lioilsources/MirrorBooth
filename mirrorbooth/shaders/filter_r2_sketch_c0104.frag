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
    float gray = luma(src);
    
    // Apply face-aware distortion and intensity modulation
    vec2 faceOffset = (uv - uFaceCenter) * uFaceScale;
    float faceMask = step(0.4, length(faceOffset));
    float intensity = mix(1.0, 0.3, faceMask);
    
    // Use smoothstep and fract to create controlled hatching lines
    float angle = sin(uTime * 0.4) * 0.3 + 0.15;
    float pattern = fract(sin(dot(uv, vec2(17.893, 92.456)) + uTime * 0.1) * 43758.5453);
    float hatching = sin(uv.x * 140.0 + uv.y * 110.0 + angle * 8.0);
    float line = abs(fract(hatching * 0.6 + gray * 0.4) - 0.5) * 2.0;
    float lineStrength = smoothstep(0.1, 0.2, line);
    
    // Combine with edge detection using step and mix for engraving effect
    vec2 d = 1.5 / uResolution;
    float a = luma(texture(uTexture, uv - d).rgb);
    float b = luma(texture(uTexture, uv + d).rgb);
    float edge = step(0.08, abs(a - b));
    
    // Final ink: mix edge and hatching, modulated by brightness
    float ink = mix(edge, lineStrength, 0.7);
    float finalLuma = mix(gray, ink, 0.9 * intensity);
    
    // Final sketch color with paper texture and contrast
    vec3 sketch = vec3(finalLuma);
    sketch *= vec3(0.8, 0.75, 0.7);
    
    fragColor = vec4(sketch, 1.0);
}
