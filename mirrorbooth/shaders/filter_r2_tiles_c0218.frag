#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 centered = (uv - uFaceCenter) * uFaceScale;
    vec2 t = centered * 3.0;
    vec2 c = floor(t);
    vec2 f = fract(t);
    vec2 odd = mod(c, 2.0);
    f = mix(f, 1.0 - f, odd);
    vec2 offset = vec2(0.0, sin(uTime * 0.5 + c.y * 1.3) * 0.02);
    vec2 suv = f + offset;
    vec3 col = texture(uTexture, suv).rgb;
    vec2 e = abs(fract(t) - 0.5);
    col *= smoothstep(0.6, 0.58, max(e.x, e.y));

    // Eye band sits above the face center; one horizontally stretched bulge
    // covers both eyes.
    vec2 e_band = vec2(uFaceCenter.x, uFaceCenter.y - 0.35 * uFaceScale);
    vec2 d = uv - e_band;
    d.x *= uResolution.x / uResolution.y;

    vec2 k = d;
    k.x *= 0.6;  // widen the kernel horizontally into a band
    float sigma = 0.35 * uFaceScale;
    float w = exp(-dot(k, k) / (sigma * sigma));

    // Sampling closer to the band center magnifies the eyes
    vec2 src = d * (1.0 - 0.25 * w);
    src.x /= uResolution.x / uResolution.y;
    vec2 wUV = clamp(e_band + src, 0.0, 1.0);

    vec3 eyeCol = texture(uTexture, wUV).rgb;

    // Brighten + pastel: mild desaturation with a faint pink cast
    eyeCol = pow(clamp(eyeCol, 0.0, 1.0), vec3(0.85));
    float l = lum(eyeCol);
    eyeCol = mix(vec3(l), eyeCol, 0.8) + vec3(0.04, 0.01, 0.03);

    vec2 grid = floor(uv * 6.0);
    vec2 shift = vec2(0.04 * sin(uTime * 0.9 + grid.y * 0.5), 0.0);
    vec2 tile = (grid + shift) / 6.0;
    vec2 mirroredTile = tile;
    if (mod(grid.x, 2.0) > 0.0) {
        mirroredTile.x = 1.0 - mirroredTile.x;
    }
    if (mod(grid.y, 2.0) > 0.0) {
        mirroredTile.y = 1.0 - mirroredTile.y;
    }
    vec3 finalCol = texture(uTexture, mirroredTile).rgb;

    fragColor = vec4(mix(col, finalCol, 0.7), 1.0);
    fragColor.rgb = mix(fragColor.rgb, eyeCol, 0.3);
}
