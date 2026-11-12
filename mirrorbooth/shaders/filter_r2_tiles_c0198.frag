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
    vec2 offset = fract(tiled) - 0.5;
    
    // Mirror logic: flip horizontally and vertically based on grid position
    float mirrorX = mod(grid.x, 2.0) * 2.0 - 1.0;
    float mirrorY = mod(grid.y, 2.0) * 2.0 - 1.0;
    
    // Shift every other row for a staggered tile effect
    float rowShift = 0.5 * (mod(grid.y, 2.0) - 0.5);
    vec2 sampledUV = (grid + offset * 0.5 + vec2(rowShift, 0.0)) / uFaceScale;
    
    // Apply mirroring
    sampledUV.x = (1.0 - sampledUV.x) * mirrorX + sampledUV.x * (1.0 - mirrorX);
    sampledUV.y = (1.0 - sampledUV.y) * mirrorY + sampledUV.y * (1.0 - mirrorY);
    
    // Sample texture with clamping to avoid artifacts
    vec3 col = texture(uTexture, clamp(sampledUV, 0.0, 1.0)).rgb;
    
    // Add subtle time-based animation to the tile edges
    float pulse = 0.5 + 0.5 * sin(uTime * 0.5 + grid.x * 1.3 + grid.y * 1.7);
    col *= (0.8 + 0.2 * pulse);
    
    // Transfer: Use local average from the other filter for subtle softening
    vec2 st = 2.2 / uResolution;
    vec3 best = vec3(0.0);
    float bestVar = 1e9;
    for (int q = 0; q < 4; q++) {
        vec2 dir = vec2(q == 0 || q == 2 ? -1.0 : 1.0, q < 2 ? -1.0 : 1.0);
        vec3 m = vec3(0.0);
        vec3 s2 = vec3(0.0);
        for (int j = 0; j < 3; j++) {
            for (int i = 0; i < 3; i++) {
                vec3 c = texture(uTexture, uv + dir * vec2(float(i), float(j)) * st).rgb;
                m += c;
                s2 += c * c;
            }
        }
        m /= 9.0;
        s2 = abs(s2 / 9.0 - m * m);
        float v = s2.r + s2.g + s2.b;
        if (v < bestVar) { bestVar = v; best = m; }
    }
    col = pow(best, vec3(0.92)) * 1.08;
    
    // Apply second filter's mask using abs(fract(...)) and modulation
    float n = 10.0;
    vec2 t = uv * n;
    vec2 c = floor(t);
    vec2 f = fract(t);
    float off = sin(c.x * 1.7 + uTime * 1.4) * 0.05;
    f = mix(f, 1.0 - f, mod(c, 2.0));
    
    vec2 suv = (c + f) / n;
    suv.y += off;
    
    // Sample and apply mask using abs(fract(...))
    vec3 col2 = texture(uTexture, clamp(suv, 0.0, 1.0)).rgb;
    float e = abs(fract(t.x) - 0.5);
    float mask = smoothstep(0.5, 0.485, e);
    
    // Final color adjustment: blend both results with mask
    col *= mask * (0.65 + 0.35 * sin(f.x * 3.14159));
    
    // Transfer: Incorporate the glyph-based detail from the other filter using abs(fract)
    float cell = uResolution.x / 56.0;
    vec2 g = FlutterFragCoord().xy / cell;
    vec2 f2 = fract(g);
    vec3 src = texture(uTexture, (floor(g) + 0.5) * cell / uResolution).rgb;
    float lvl = floor(clamp(dot(src, vec3(0.299, 0.587, 0.114)) * 1.15, 0.0, 0.999) * 6.0);
    vec2 a = abs(f2 - 0.5);
    float glyph = 0.0;
    if (lvl > 4.5) { glyph = step(max(a.x, a.y), 0.42); }
    else if (lvl > 3.5) { glyph = max(step(abs(a.x - 0.18), 0.07), step(abs(a.y - 0.18), 0.07)) * step(max(a.x, a.y), 0.42); }
    else if (lvl > 2.5) { glyph = max(step(a.x, 0.07) * step(a.y, 0.34), step(a.y, 0.07) * step(a.x, 0.34)); }
    else if (lvl > 1.5) { glyph = step(a.y, 0.07) * step(a.x, 0.3); }
    else if (lvl > 0.5) { glyph = step(length(f2 - 0.5), 0.13); }
    vec3 tint = mix(vec3(0.2, 1.0, 0.45), src * 1.6, 0.35);
    col += glyph * tint * 0.2;
    
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
