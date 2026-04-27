#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;
    vec2 px = 1.0 / uResolution;

    // Chromatic shift (retro analog offset)
    float shift = 1.8;
    float r = texture(uTexture, uv + vec2( shift, 0.0) * px).r;
    float g = texture(uTexture, uv).g;
    float b = texture(uTexture, uv + vec2(-shift, 0.0) * px).b;
    vec3 col = vec3(r, g, b);

    // Neon 4-level posterize with boosted saturation
    col = floor(col * 4.0 + 0.5) / 4.0;
    float l = lum(col);
    col = mix(vec3(l), col, 1.75);

    // Thick Sobel + 2px combined outline
    vec2 px2 = px * 2.0;
    float tl1 = lum(texture(uTexture, uv + vec2(-px.x,  px.y)).rgb);
    float tc1 = lum(texture(uTexture, uv + vec2( 0.0,   px.y)).rgb);
    float tr1 = lum(texture(uTexture, uv + vec2( px.x,  px.y)).rgb);
    float ml1 = lum(texture(uTexture, uv + vec2(-px.x,  0.0 )).rgb);
    float mr1 = lum(texture(uTexture, uv + vec2( px.x,  0.0 )).rgb);
    float bl1 = lum(texture(uTexture, uv + vec2(-px.x, -px.y)).rgb);
    float bc1 = lum(texture(uTexture, uv + vec2( 0.0,  -px.y)).rgb);
    float br1 = lum(texture(uTexture, uv + vec2( px.x, -px.y)).rgb);
    float gx1 = -tl1-2.0*ml1-bl1+tr1+2.0*mr1+br1;
    float gy1 = -tl1-2.0*tc1-tr1+bl1+2.0*bc1+br1;
    float tl2 = lum(texture(uTexture, uv + vec2(-px2.x,  px2.y)).rgb);
    float tr2 = lum(texture(uTexture, uv + vec2( px2.x,  px2.y)).rgb);
    float bl2 = lum(texture(uTexture, uv + vec2(-px2.x, -px2.y)).rgb);
    float br2 = lum(texture(uTexture, uv + vec2( px2.x, -px2.y)).rgb);
    float gx2 = tr2+br2-tl2-bl2;
    float gy2 = tl2+tr2-bl2-br2;
    float edge = max(sqrt(gx1*gx1+gy1*gy1), sqrt(gx2*gx2+gy2*gy2)*0.6);
    float outline = smoothstep(0.15, 0.38, edge);
    col = mix(col, vec3(0.0), outline);

    // Horizontal scanlines
    float scanline = 0.5 + 0.5 * sin(fragCoord.y * 3.14159 * 0.5);
    col *= mix(0.78, 1.0, scanline);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
