#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float sobelAt(vec2 uv, vec2 scale) {
    vec2 px = scale / uResolution;
    float tl = lum(texture(uTexture, uv + vec2(-px.x,  px.y)).rgb);
    float tc = lum(texture(uTexture, uv + vec2( 0.0,   px.y)).rgb);
    float tr = lum(texture(uTexture, uv + vec2( px.x,  px.y)).rgb);
    float ml = lum(texture(uTexture, uv + vec2(-px.x,  0.0 )).rgb);
    float mr = lum(texture(uTexture, uv + vec2( px.x,  0.0 )).rgb);
    float bl = lum(texture(uTexture, uv + vec2(-px.x, -px.y)).rgb);
    float bc = lum(texture(uTexture, uv + vec2( 0.0,  -px.y)).rgb);
    float br = lum(texture(uTexture, uv + vec2( px.x, -px.y)).rgb);
    float gx = -tl - 2.0*ml - bl + tr + 2.0*mr + br;
    float gy = -tl - 2.0*tc - tr + bl + 2.0*bc + br;
    return sqrt(gx*gx + gy*gy);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 fragCoord = FlutterFragCoord().xy;

    float l = lum(texture(uTexture, uv).rgb);

    // Multi-scale edges for heavy strokes
    float e1 = sobelAt(uv, vec2(1.0));
    float e2 = sobelAt(uv, vec2(2.5));
    float e3 = sobelAt(uv, vec2(5.0));
    float edges = e1 * 0.5 + e2 * 0.8 + e3 * 0.35;

    // Two-direction hatching; lines every ~7px, angled ±30°
    float h1 = abs(sin((fragCoord.x * 0.866 + fragCoord.y * 0.5) * 3.14159 / 7.0));
    float h2 = abs(sin((-fragCoord.x * 0.5  + fragCoord.y * 0.866) * 3.14159 / 7.0));
    float hatch1 = smoothstep(0.4, 0.75, h1);
    float hatch2 = smoothstep(0.4, 0.75, h2);

    // Dense areas get both hatch directions; light areas get none
    float hatchMix = clamp((1.0 - l) * 1.3, 0.0, 1.0);
    float hatchA   = mix(1.0, hatch1, hatchMix);
    float hatchB   = mix(1.0, hatch2, hatchMix * 0.6);
    float hatching = hatchA * hatchB;

    // Paper grain
    float grain = rand(floor(fragCoord * 0.5)) * 0.07 - 0.035;

    float stroke = smoothstep(0.08, 0.55, edges);
    float paper  = (0.92 + grain) * hatching * (1.0 - stroke * 0.95);

    // Slight warm paper tint
    vec3 col = clamp(vec3(paper), 0.0, 1.0) * vec3(0.96, 0.95, 0.90);
    fragColor = vec4(col, 1.0);
}
