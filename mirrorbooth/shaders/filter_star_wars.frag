#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 px = 1.0 / uResolution;

    vec3 col = texture(uTexture, uv).rgb;
    float l = lum(col);

    // 4-band toon shading
    float toon;
    if      (l < 0.22) toon = 0.10;
    else if (l < 0.48) toon = 0.40;
    else if (l < 0.75) toon = 0.70;
    else               toon = 1.00;
    col = col * (toon / max(l, 0.001));

    // Cool sci-fi blue tint
    col = mix(col, col * vec3(0.82, 0.92, 1.10), 0.38);

    // Sobel outlines
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
    col = mix(col, vec3(0.0), smoothstep(0.20, 0.50, sqrt(gx*gx + gy*gy)));

    // Lightsaber glow: very bright areas → cyan/electric blue bloom
    float glow = smoothstep(0.80, 0.96, l);
    col = mix(col, vec3(0.15, 0.85, 1.0), glow * 0.85);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
