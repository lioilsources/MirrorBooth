#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    
    // Tiling with cartesian mirroring and shifted rows using mod and fract
    vec2 tiled = uv * uFaceScale;
    vec2 grid = floor(tiled);
    vec2 f = fract(tiled);
    
    // Mirror in both axes based on grid parity
    float mirrorX = mod(grid.x, 2.0) * 2.0 - 1.0;
    float mirrorY = mod(grid.y, 2.0) * 2.0 - 1.0;
    
    // Shift every other row for staggered tiling
    float rowShift = 0.5 * (mod(grid.y, 2.0) - 0.5);
    vec2 suv = (grid + f - 0.5) * 0.5 + vec2(rowShift, 0.0);
    
    // Apply mirroring by flipping based on grid
    suv.x = (1.0 - suv.x) * mirrorX + suv.x * (1.0 - mirrorX);
    suv.y = (1.0 - suv.y) * mirrorY + suv.y * (1.0 - mirrorY);
    
    // Sample texture with clamping
    vec3 col = texture(uTexture, clamp(suv, 0.0, 1.0)).rgb;
    
    // Add time-based edge pulse for subtle animation
    float pulse = 0.5 + 0.5 * sin(uTime * 0.5 + grid.x * 1.3 + grid.y * 1.7);
    col *= (0.8 + 0.2 * pulse);
    
    // Use local average from the other filter for softening (via 3x3 neighborhood)
    vec2 st = 2.2 / uResolution;
    vec3 avg = vec3(0.0);
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            vec3 c = texture(uTexture, uv + vec2(float(i) - 1.0, float(j) - 1.0) * st).rgb;
            avg += c;
        }
    }
    avg /= 9.0;
    
    // Apply gamma and boost to mimic softness and contrast
    col = pow(avg, vec3(0.92)) * 1.08;
    
    // Apply second filter's core: grid-based mirroring and shifting with fract and mod
    float n = 10.0;
    vec2 t = uv * n;
    vec2 c = floor(t);
    vec2 f2 = fract(t);
    float off = sin(c.x * 1.7 + uTime * 1.4) * 0.05;
    f2 = mix(f2, 1.0 - f2, mod(c, 2.0));
    
    vec2 suv2 = (c + f2) / n;
    suv2.y += off;
    
    // Apply mask using abs(fract(...)) for edge softening
    float e = abs(fract(t.x) - 0.5);
    float mask = smoothstep(0.5, 0.485, e);
    
    // Blend with mirrored tile from second filter
    vec2 grid2 = floor(uv * 10.0);
    vec2 shift = vec2(0.1 * sin(uTime + grid2.x * 0.5), 0.0);
    vec2 tile = (grid2 + shift) / 10.0;
    if (mod(grid2.x, 2.0) > 0.5) tile.x = 1.0 - tile.x;
    if (mod(grid2.y, 2.0) > 0.5) tile.y = 1.0 - tile.y;
    
    vec3 finalTile = texture(uTexture, tile).rgb;
    
    // Final blend: use mask to modulate between both results
    col = mix(col, finalTile, 0.5);
    col *= mask * (0.65 + 0.35 * sin(f2.x * 3.14159));
    
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
