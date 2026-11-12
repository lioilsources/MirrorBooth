#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    
    // Tiled mirror with cartesian mirroring using mod and fract
    float cols = 6.0;
    vec2 tile = floor(uv * cols);
    vec2 f = fract(uv * cols);
    vec2 mirrored = abs(fract(f - 0.5) - 0.5) * 2.0;
    vec2 baseUv = (tile + mirrored) / cols;
    
    // Apply shifted rows using abs(fract(...)) as required
    vec2 shifted = uv * cols;
    vec2 t = floor(shifted);
    vec2 f2 = fract(shifted);
    float rowOdd = mod(t.y, 2.0);
    f2.x = mix(f2.x, 1.0 - f2.x, rowOdd);
    
    // Combine mirrored grid with row shift
    vec2 finalUv = (t + f2) / cols;
    
    // Use abs(fract(...)) to create soft transitions
    vec2 e = abs(fract(shifted) - 0.5);
    float mask = smoothstep(0.5, 0.49, max(e.x, e.y));
    
    // Sample texture with mirrored and shifted coordinates
    vec3 col = texture(uTexture, finalUv).rgb;
    
    // Add time-based color modulation
    float pulse = 0.8 + 0.2 * sin(uTime * 1.3);
    col *= pulse * mask;
    
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
