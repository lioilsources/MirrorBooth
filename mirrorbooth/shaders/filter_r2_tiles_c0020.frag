#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    
    // Apply Shader B's concept: tiled grid with shifted rows based on time
    float n = 10.0;
    float id = floor(uv.x * n);
    float f = fract(uv.x * n);
    float off = sin(id * 1.7 + uTime * 1.4) * 0.05;
    vec2 suv = vec2((id + 0.5 + (f - 0.5) * 1.7) / n, uv.y + off);
    
    // Sample from Shader B's output (with clamping)
    vec3 col = texture(uTexture, clamp(suv, 0.0, 1.0)).rgb;
    
    // Apply Shader A's mirroring technique: cartesian mirroring in grid
    vec2 t = suv * n;
    vec2 c = floor(t);
    vec2 f2 = fract(t);
    vec2 odd = mod(c, 2.0);
    f2 = mix(f2, 1.0 - f2, odd);
    
    // Use abs(fract(...)) as required by the rules
    vec2 e = abs(fract(t) - 0.5);
    float mask = smoothstep(0.5, 0.485, max(e.x, e.y));
    
    // Combine both effects: mirror grid + time-shifted tiles
    col *= mask;
    float shade = 0.65 + 0.35 * sin(f * 3.14159);
    col *= shade;
    
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
