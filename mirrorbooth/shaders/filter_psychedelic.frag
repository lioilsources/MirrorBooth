#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

vec3 hsvToRgb(float h, float s, float v) {
    float h6 = fract(h) * 6.0;
    float c  = v * s;
    float x  = c * (1.0 - abs(mod(h6, 2.0) - 1.0));
    float m  = v - c;
    vec3 rgb;
    if      (h6 < 1.0) rgb = vec3(c, x, 0.0);
    else if (h6 < 2.0) rgb = vec3(x, c, 0.0);
    else if (h6 < 3.0) rgb = vec3(0.0, c, x);
    else if (h6 < 4.0) rgb = vec3(0.0, x, c);
    else if (h6 < 5.0) rgb = vec3(x, 0.0, c);
    else               rgb = vec3(c, 0.0, x);
    return rgb + m;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // Aspect-corrected center
    vec2 c = uv - 0.5;
    c.x *= uResolution.x / uResolution.y;

    float r     = length(c);
    float theta = atan(c.y, c.x);

    // Swirl + radial pulse
    float swirl = sin(r * 7.0 - uTime * 1.8) * 0.28;
    float wave  = sin(theta * 3.0 + uTime * 0.9) * 0.04 * (r + 0.1);
    theta += swirl + wave;
    r     += sin(theta * 4.0 + uTime * 1.2) * 0.025;

    // Back to UV
    vec2 wc = vec2(cos(theta), sin(theta)) * r;
    wc.x /= (uResolution.x / uResolution.y);
    vec2 wUV = clamp(wc + 0.5, 0.0, 1.0);

    vec3 src = texture(uTexture, wUV).rgb;
    float l = dot(src, vec3(0.299, 0.587, 0.114));

    // Map luminance → cycling hue
    float hue = fract(l * 1.8 + uTime * 0.18 + r * 0.4);
    vec3 col = hsvToRgb(hue, 0.95, 0.25 + l * 0.75);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
