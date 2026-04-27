#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float quantize(float v, float steps) {
    return floor(v * steps + 0.5) / steps;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    float blockSize = 6.0;
    vec2 blockUV = floor(uv * uResolution / blockSize) * blockSize / uResolution;
    vec3 col = texture(uTexture, blockUV).rgb;

    col.r = quantize(col.r, 7.0);
    col.g = quantize(col.g, 7.0);
    col.b = quantize(col.b, 3.0);

    fragColor = vec4(col, 1.0);
}
