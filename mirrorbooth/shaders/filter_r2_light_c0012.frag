#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 base = texture(uTexture, uv).rgb;

    // Transfer: Apply the warping effect from the other filter (pow + smoothstep) to create a subtle lens distortion around the face
    vec2 d = uv - uFaceCenter;
    d.x *= uResolution.x / uResolution.y;
    float r = length(d);
    float R = uFaceScale;

    vec2 wUV = uv;
    if (r < R && r > 0.0) {
        vec2 dn = d * pow(r / R, 0.55);
        dn = mix(dn, d, smoothstep(0.8 * R, R, r));
        dn.x /= uResolution.x / uResolution.y;
        wUV = clamp(uFaceCenter + dn, 0.0, 1.0);
    }

    // Bloom and glow from bright areas
    float bright = max(luma(base) - 0.72, 0.0);
    vec3 glow = base * bright * 3.0;

    // Light rays using directional accumulation
    vec2 dir = uFaceCenter - uv;
    vec3 acc = vec3(0.0);
    float wsum = 0.0;
    for (int i = 0; i < 18; i++) {
        float t = float(i) / 18.0;
        vec3 c = texture(uTexture, uv + dir * t * 0.55).rgb;
        float w = 1.0 - t;
        acc += max(c - 0.72, 0.0) * w;
        wsum += w;
    }
    vec3 rays = acc / wsum * 2.4;

    // Bokeh circles: add circular bright spots based on luminance
    float bokeh = smoothstep(0.6, 0.9, bright) * 0.4;
    vec3 bokehColor = vec3(1.0, 0.9, 0.7) * bokeh;

    // Vignette: darken edges
    float vignette = 1.0 - pow(length(uv - 0.5) / 0.7, 2.0);

    // Final composite
    vec3 col = base * 0.9 + glow + rays + bokehColor;
    col *= vignette;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
