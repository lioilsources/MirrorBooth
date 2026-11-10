#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 t = uv * 3.0;
    vec2 c = floor(t);
    vec2 f = fract(t);
    vec2 odd = mod(c, 2.0);
    f = mix(f, 1.0 - f, odd);
    vec3 col = texture(uTexture, f).rgb;
    vec2 e = abs(fract(t) - 0.5);
    col *= smoothstep(0.5, 0.485, max(e.x, e.y));
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
