#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 barrelDistort(vec2 uv, float k) {
    vec2 c = uv * 2.0 - 1.0;
    c.x *= uResolution.x / uResolution.y;
    float r2 = dot(c, c);
    c *= 1.0 + k * r2;
    c.x /= (uResolution.x / uResolution.y);
    return c * 0.5 + 0.5;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // Apply barrel distortion (CRT curvature) from the other filter
    vec2 wUV = barrelDistort(uv, 0.14);

    // Black bezel outside screen
    if (wUV.x < 0.0 || wUV.x > 1.0 || wUV.y < 0.0 || wUV.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // Tiled mirror grid with cartesian mirroring using mod and fract
    float cols = 5.0;
    vec2 t = wUV * cols;
    vec2 tile = floor(t);
    vec2 f = fract(t);
    vec2 odd = mod(tile, 2.0);
    f = mix(f, 1.0 - f, odd);
    vec2 baseUv = (tile + f) / cols;

    // Shift odd rows using abs(fract(...)) for soft transitions
    vec2 shifted = wUV * cols;
    vec2 t2 = floor(shifted);
    vec2 f2 = fract(shifted);
    float rowOdd = mod(t2.y, 2.0);
    f2.x = mix(f2.x, 1.0 - f2.x, rowOdd);
    vec2 finalUv = (t2 + f2) / cols;

    // Use abs(fract(...)) to create soft edge transitions
    vec2 e = abs(fract(shifted) - 0.5);
    float mask = smoothstep(0.5, 0.49, max(e.x, e.y));

    // Chromatic aberration (RGB fringing)
    float ca = 0.0028;
    float r = texture(uTexture, finalUv + vec2(ca, 0.0)).r;
    float g = texture(uTexture, finalUv).g;
    float b = texture(uTexture, finalUv - vec2(ca, 0.0)).b;
    vec3 col = vec3(r, g, b);

    // Scanlines: horizontal dark bars every 2 physical rows
    float scan = 0.72 + 0.28 * sin(FlutterFragCoord().y * 3.14159);
    col *= scan;

    // Phosphor warmth: slight green tint on bright areas
    float bright = dot(col, vec3(0.333));
    col *= mix(vec3(1.0), vec3(0.88, 1.12, 0.78), bright * 0.18);

    // Vignette
    vec2 vig = wUV * 2.0 - 1.0;
    float vignette = pow(clamp(1.0 - dot(vig * vec2(0.55, 0.65), vig * vec2(0.55, 0.65)), 0.0, 1.0), 0.7);
    col *= vignette;

    // Add time-based modulation for dynamic effect
    float pulse = 0.7 + 0.3 * sin(uTime * 1.5);
    col *= pulse * mask;

    // Compensate for scanline + vignette darkening
    col *= 1.18;

    // Final color clamping and output
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
