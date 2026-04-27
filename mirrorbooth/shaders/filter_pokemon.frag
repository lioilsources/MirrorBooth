#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;
    vec2 px = 1.0 / uResolution;

    vec3 col = texture(uTexture, uv).rgb;
    float l = lum(col);

    // Vivid cel-shade: 4-band toon
    float toon;
    if      (l < 0.22) toon = 0.10;
    else if (l < 0.48) toon = 0.40;
    else if (l < 0.72) toon = 0.70;
    else               toon = 1.00;
    col = col * (toon / max(l, 0.001));
    col = mix(vec3(toon), col, 1.35);

    // Sobel for edge detection
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
    float edgeStrength = sqrt(gx*gx + gy*gy);

    // Chromatic aberration on edges
    float aberr = smoothstep(0.15, 0.40, edgeStrength) * 2.5;
    vec3 colR = texture(uTexture, uv + vec2( aberr, 0.0) * px).rgb;
    vec3 colB = texture(uTexture, uv + vec2(-aberr, 0.0) * px).rgb;
    col.r = mix(col.r, colR.r, 0.6);
    col.b = mix(col.b, colB.b, 0.6);

    // Black outlines
    float outline = smoothstep(0.18, 0.42, edgeStrength);
    col = mix(col, vec3(0.0), outline * 0.9);

    // Animated radial speed lines (12 spokes)
    vec2 dir = uv - 0.5;
    float r = length(dir);
    float angle = atan(dir.y, dir.x);
    float spoke = fract(angle * 12.0 / 3.14159 + uTime * 0.5);
    float speedLine = smoothstep(0.88, 1.0, spoke)
                    * smoothstep(0.12, 0.30, r)
                    * (1.0 - smoothstep(0.28, 0.46, r));
    col = mix(col, vec3(1.0, 0.95, 0.2), speedLine * 0.65);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
