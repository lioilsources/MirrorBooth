#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    
    // Apply tiled mirror grid with cartesian mirroring using mod and fract
    float cols = 5.0;
    vec2 t = uv * cols;
    vec2 tile = floor(t);
    vec2 f = fract(t);
    vec2 odd = mod(tile, 2.0);
    f = mix(f, 1.0 - f, odd);
    vec2 baseUv = (tile + f) / cols;
    
    // Shift odd rows using abs(fract(...)) as required
    vec2 shifted = uv * cols;
    vec2 t2 = floor(shifted);
    vec2 f2 = fract(shifted);
    float rowOdd = mod(t2.y, 2.0);
    f2.x = mix(f2.x, 1.0 - f2.x, rowOdd);
    vec2 finalUv = (t2 + f2) / cols;
    
    // Use abs(fract(...)) to create soft edge transitions
    vec2 e = abs(fract(shifted) - 0.5);
    float mask = smoothstep(0.5, 0.49, max(e.x, e.y));
    
    // Sample the texture with the transformed coordinates
    vec3 col = texture(uTexture, finalUv).rgb;
    
    // Add time-based modulation for dynamic effect
    float pulse = 0.7 + 0.3 * sin(uTime * 1.5);
    col *= pulse * mask;
    
    // Transfer: Apply neon glow from shader A using mod and fract
    float l = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 glow = vec3(
        0.5 + 0.5 * sin(uTime * 0.5 + 0.0),
        0.5 + 0.5 * sin(uTime * 0.5 + 2.0),
        0.5 + 0.5 * sin(uTime * 0.5 + 4.0)
    );
    vec3 neon = mix(col, glow, 0.4 * (l * 1.5 - 0.5));
    neon = mix(col, neon, 0.8);
    
    // Dynamic color shift based on time and position
    float pulse2 = 0.7 + 0.3 * sin(uTime * 1.8);
    vec3 shift = vec3(
        0.5 + 0.5 * sin(uTime * 0.8 + uv.x * 4.0),
        0.5 + 0.5 * sin(uTime * 0.9 + uv.y * 5.0),
        0.5 + 0.5 * sin(uTime * 1.0 + (uv.x + uv.y) * 3.0)
    );
    neon = mix(neon, shift, 0.2 * pulse2);
    
    // Add subtle edge glow using abs(fract(...)) for softness
    float edge = 1.0 - smoothstep(0.0, 0.05, min(uv.x, min(uv.y, min(1.0 - uv.x, 1.0 - uv.y))));
    neon += glow * edge * 0.5;
    
    // Final color clamping and output
    fragColor = vec4(clamp(neon, 0.0, 1.0), 1.0);
}
