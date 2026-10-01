// Ported from https://www.shadertoy.com/view/stCommon — "Posterize Common" by ivy, Unlicense
// Converted to the MirrorBooth/Flutter shader contract by ShaderGen v2 (pipeline/shadertoy/transpile.py).

#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

#define iResolution vec3(uResolution, 1.0)

// Shadertoy UV (bottom-left origin) -> camera texture (top-left origin)
vec4 stSample(vec2 uv) { return texture(uTexture, vec2(uv.x, 1.0 - uv.y)); }

// ---- Shadertoy: Common ----
// Unlicense
vec3 posterize(vec3 c, float n) { return floor(c * n) / n; }

// ---- Shadertoy: Image ----
// Unlicense (see Common)
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = vec4(posterize(stSample(uv).rgb, 4.0), 1.0);
}

// ---- MirrorBooth entry point ----
void main() {
    vec2 fc = FlutterFragCoord().xy;
    fc.y = uResolution.y - fc.y;  // Flutter: top-left origin, Shadertoy: bottom-left
    vec4 c = vec4(0.0);
    mainImage(c, fc);
    fragColor = vec4(clamp(c.rgb, 0.0, 1.0), 1.0);
}
