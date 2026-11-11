#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    
    // Apply shader A's core: grid tiling with cartesian mirroring and shifted rows using mod and fract
    vec2 t = uv * 5.0;
    vec2 c = floor(t);
    vec2 f = fract(t);
    vec2 odd = mod(c, 2.0);
    f = mix(f, 1.0 - f, odd);
    vec2 offset = vec2(0.0, sin(uTime * 0.5 + c.x * 1.3) * 0.05);
    vec2 suv = f + offset;
    vec3 col = texture(uTexture, suv).rgb;
    
    // Use abs(fract(...)) for edge softening
    vec2 e = abs(fract(t) - 0.5);
    col *= smoothstep(0.5, 0.485, max(e.x, e.y));
    
    // Apply shader B's grid-based mirroring and shifting using mod and fract
    float n = 10.0;
    vec2 t2 = uv * n;
    vec2 c2 = floor(t2);
    vec2 f2 = fract(t2);
    float off = sin(c2.x * 1.7 + uTime * 1.4) * 0.05;
    f2 = mix(f2, 1.0 - f2, mod(c2, 2.0));
    
    vec2 suv2 = (c2 + f2) / n;
    suv2.y += off;
    
    // Apply mirroring per grid cell based on parity
    vec2 grid2 = floor(uv * 10.0);
    vec2 shift = vec2(0.1 * sin(uTime + grid2.x * 0.5), 0.0);
    vec2 tile = (grid2 + shift) / 10.0;
    tile.x = mod(grid2.x, 2.0) > 0.5 ? 1.0 - tile.x : tile.x;
    tile.y = mod(grid2.y, 2.0) > 0.5 ? 1.0 - tile.y : tile.y;
    
    // Sample mirrored tile
    vec3 finalTile = texture(uTexture, tile).rgb;
    
    // Blend results using mask based on abs(fract(...))
    float e2 = abs(fract(t2.x) - 0.5);
    float mask = smoothstep(0.5, 0.485, e2);
    col = mix(col, finalTile, 0.5 * mask);
    
    // Final color adjustment
    col *= (0.65 + 0.35 * sin(f2.x * 3.14159));
    
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
