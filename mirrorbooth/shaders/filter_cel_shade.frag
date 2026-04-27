#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float luminance(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

float sobelEdge(vec2 uv, vec2 px) {
    float tl = luminance(texture(uTexture, uv + vec2(-px.x,  px.y)).rgb);
    float tc = luminance(texture(uTexture, uv + vec2( 0.0,   px.y)).rgb);
    float tr = luminance(texture(uTexture, uv + vec2( px.x,  px.y)).rgb);
    float ml = luminance(texture(uTexture, uv + vec2(-px.x,  0.0 )).rgb);
    float mr = luminance(texture(uTexture, uv + vec2( px.x,  0.0 )).rgb);
    float bl = luminance(texture(uTexture, uv + vec2(-px.x, -px.y)).rgb);
    float bc = luminance(texture(uTexture, uv + vec2( 0.0,  -px.y)).rgb);
    float br = luminance(texture(uTexture, uv + vec2( px.x, -px.y)).rgb);
    float gx = -tl - 2.0*ml - bl + tr + 2.0*mr + br;
    float gy = -tl - 2.0*tc - tr + bl + 2.0*bc + br;
    return sqrt(gx*gx + gy*gy);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 px = 1.0 / uResolution;

    vec3 col = texture(uTexture, uv).rgb;
    float lum = luminance(col);

    float toon;
    if (lum < 0.25)      toon = 0.15;
    else if (lum < 0.60) toon = 0.55;
    else                 toon = 0.95;

    vec3 grey = vec3(lum);
    vec3 saturated = mix(grey, col, 1.4);
    vec3 toonColor = saturated * (toon / max(lum, 0.001));

    float edge = sobelEdge(uv, px);
    float outline = smoothstep(0.20, 0.38, edge);
    toonColor = mix(toonColor, vec3(0.0), outline * 0.95);

    fragColor = vec4(clamp(toonColor, 0.0, 1.0), 1.0);
}
