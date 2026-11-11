#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 px = 2.0 / uResolution;
    vec3 center = texture(uTexture, uv).rgb;

    // Bilateral-like smoothing: gentler similarity falloff than the oil
    // filter so skin blends while eyes/hair edges survive.
    vec3  accum  = vec3(0.0);
    float wTotal = 0.0;
    vec3  bloom  = vec3(0.0);

    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            vec3  s = texture(uTexture, uv + vec2(float(i), float(j)) * px).rgb;
            float d = length(s - center);
            float w = exp(-d * d * 10.0);
            accum  += s * w;
            wTotal += w;
            bloom  += max(s - 0.7, 0.0);
        }
    }

    vec3 smoothed = accum / wTotal;
    vec3 col = mix(center, smoothed, 0.65);

    // Soft bloom from the blurred highlights
    col += (bloom / 25.0) * 0.35;

    // Warm grade + gentle lift
    col *= vec3(1.06, 1.0, 0.94);
    col = pow(clamp(col, 0.0, 1.0), vec3(0.92));

    // Soft vignette
    vec2 vig = uv * 2.0 - 1.0;
    float vignette = pow(clamp(1.0 - dot(vig * 0.45, vig * 0.45), 0.0, 1.0), 0.4);
    col *= mix(0.85, 1.0, vignette);

    // Light rays effect: radial glow from center with time modulation
    vec2 rayDir = uv - 0.5;
    float rayDist = length(rayDir);
    float rayFade = 1.0 - smoothstep(0.1, 0.5, rayDist);
    float rayIntensity = pow(rayFade, 1.5) * 0.6;
    float rayPattern = sin(rayDist * 20.0 + uTime * 0.5) * 0.5 + 0.5;
    col += vec3(rayIntensity * rayPattern);

    // Bokeh circles: simulate out-of-focus highlights with soft glow
    float bright = lum(col);
    float bokeh = 1.0 - smoothstep(0.8, 1.0, bright);
    float bokehSize = 0.02 + 0.03 * sin(uTime * 0.7) * 0.5;
    float bokehBlur = exp(-pow(length(rayDir * 2.0), 2.0) / (bokehSize * bokehSize));
    col += vec3(bokeh * bokehBlur * 1.2);

    // Final clamp and output
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
