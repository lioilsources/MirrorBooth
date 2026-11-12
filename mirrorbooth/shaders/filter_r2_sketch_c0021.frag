#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 src = texture(uTexture, uv).rgb;
    float l = clamp(luma(src) * 1.1, 0.0, 1.0);
    
    // Step 1: Apply sketch edge detection from Shader A
    vec2 d = 1.6 / uResolution;
    float a = luma(texture(uTexture, uv - d).rgb);
    float b = luma(texture(uTexture, uv + d).rgb);
    float edge = clamp(0.5 + (a - b) * 4.0, 0.0, 1.0);
    
    // Step 2: Apply hatching lines from Shader B, modulated by edge strength
    float pitch = uResolution.x / 110.0;
    float y = FlutterFragCoord().y / pitch + sin(uv.x * 38.0) * 0.7 + (l - 0.5) * 1.5;
    float line = abs(fract(y) - 0.5) * 2.0;
    float w = 1.0 - l;
    float ink = smoothstep(w + 0.12, w - 0.12, line);
    
    // Step 3: Blend edge intensity with hatching
    float finalInk = mix(ink, edge, 0.5);
    vec3 col = mix(vec3(0.93, 0.95, 0.88), vec3(0.08, 0.22, 0.16), finalInk);
    
    // Final color with slight paper texture
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
