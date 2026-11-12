#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 rand(vec2 p) {
    return vec2(hash(p), hash(p + vec2(1.0, 2.0)));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 baseColor = texture(uTexture, uv).rgb;

    // Apply Shader B's core technique: dynamic offsetting and streaks
    vec2 offs = vec2(0.0);
    float spec = 0.0;
    for (int k = 0; k < 2; k++) {
        float sc = k == 0 ? 7.0 : 12.0;
        vec2 p = vec2(uv.x * (uResolution.x / uResolution.y), uv.y) * sc;
        vec2 id = floor(p);
        p.y -= uTime * (0.35 + 0.5 * hash(vec2(id.x, float(k) + 3.0))) * sc * 0.25;
        id = floor(p);
        vec2 f = fract(p) - 0.5;
        vec2 h = rand(id + float(k) * 31.0);
        if (h.x > 0.45) {
            vec2 c = (h - 0.5) * 0.5;
            vec2 d = f - c;
            d.y *= 0.7;
            float r = 0.16 + 0.1 * h.y;
            float m = smoothstep(r, r * 0.6, length(d));
            offs -= d * m * 0.5 / sc * 3.0;
            spec += m * smoothstep(0.06, 0.0, length(d - vec2(-0.05, -0.06)));
        }
    }
    vec2 suv = clamp(uv + vec2(offs.x / (uResolution.x / uResolution.y), offs.y), 0.0, 1.0);
    vec3 color = baseColor * vec3(0.86, 0.93, 1.0);
    color += spec * 0.8;

    // Add weather overlay: rain, fog, sparks using fract(sin(...)) and uTime
    // Rain: vertical streaks with randomized timing via fract(sin(...))
    vec2 rainPos = uv * 30.0 + vec2(0.0, uTime * 2.0);
    vec2 rainId = floor(rainPos);
    float rainSeed = fract(sin(dot(rainId, vec2(12.9898, 78.233))) * 43758.5453);
    float rain = 0.0;
    if (rainSeed > 0.95) {
        float rainDist = abs(fract(rainPos.y) - 0.5);
        rain = 1.0 - smoothstep(0.03, 0.01, rainDist);
        rain *= 0.7 + 0.3 * sin(uTime * 0.5 + rainId.x * 0.3);
    }

    // Sparks: short-lived, bright flickers with time-dependent randomness
    vec2 sparkPos = uv * 20.0 + vec2(uTime * 0.8, 0.0);
    vec2 sparkId = floor(sparkPos);
    float sparkSeed = fract(sin(dot(sparkId, vec2(12.9898, 78.233))) * 43758.5453);
    float spark = 0.0;
    if (sparkSeed > 0.97) {
        float sparkSize = 0.005 + 0.002 * (1.0 - sparkSeed);
        float sparkDist = length(fract(sparkPos) - 0.5);
        spark = 1.0 - smoothstep(sparkSize, sparkSize * 0.5, sparkDist);
        spark *= 0.9 + 0.1 * sin(uTime * 1.5 + sparkId.x * 0.2);
    }

    // Fog: soft, drifting layer based on time and position
    float fog = 0.05 * sin(uTime * 0.4 + uv.x * 3.0) * (1.0 - uv.y);
    fog *= 0.8 + 0.2 * fract(sin(uTime * 0.1 + uv.y * 2.0) * 43758.5453);

    // Combine all overlays
    color += vec3(rain * 0.9) * (1.0 - fog);
    color += vec3(spark * 0.8);

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
