#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float cell = uResolution.x / 64.0;
    vec2 g = FlutterFragCoord().xy / cell;
    vec2 f = fract(g);
    vec3 src = texture(uTexture, (floor(g) + 0.5) * cell / uResolution).rgb;
    float third = floor(f.x * 3.0);
    vec3 mask = vec3(step(third, 0.5), step(abs(third - 1.0), 0.5), step(1.5, third));
    float sx = abs(fract(f.x * 3.0) - 0.5);
    float sy = abs(f.y - 0.5);
    float shape = smoothstep(0.5, 0.36, sx) * smoothstep(0.49, 0.4, sy);
    vec3 col = pow(src, vec3(0.75)) * (mask * 3.2 + 0.18) * shape;
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
