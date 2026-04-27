#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 px = 1.0 / uResolution;

    vec3 col = texture(uTexture, uv).rgb;

    // Vivid 4-level posterize
    col = floor(col * 4.0 + 0.5) / 4.0;
    float l = lum(col);
    col = mix(vec3(l), col, 1.45);

    // Thick 2px Sobel outlines
    vec2 px2 = px * 2.0;
    float tl1 = lum(texture(uTexture, uv + vec2(-px.x,  px.y)).rgb);
    float tc1 = lum(texture(uTexture, uv + vec2( 0.0,   px.y)).rgb);
    float tr1 = lum(texture(uTexture, uv + vec2( px.x,  px.y)).rgb);
    float ml1 = lum(texture(uTexture, uv + vec2(-px.x,  0.0 )).rgb);
    float mr1 = lum(texture(uTexture, uv + vec2( px.x,  0.0 )).rgb);
    float bl1 = lum(texture(uTexture, uv + vec2(-px.x, -px.y)).rgb);
    float bc1 = lum(texture(uTexture, uv + vec2( 0.0,  -px.y)).rgb);
    float br1 = lum(texture(uTexture, uv + vec2( px.x, -px.y)).rgb);
    float gx1 = -tl1 - 2.0*ml1 - bl1 + tr1 + 2.0*mr1 + br1;
    float gy1 = -tl1 - 2.0*tc1 - tr1 + bl1 + 2.0*bc1 + br1;

    float tl2 = lum(texture(uTexture, uv + vec2(-px2.x,  px2.y)).rgb);
    float tc2 = lum(texture(uTexture, uv + vec2(  0.0,   px2.y)).rgb);
    float tr2 = lum(texture(uTexture, uv + vec2( px2.x,  px2.y)).rgb);
    float ml2 = lum(texture(uTexture, uv + vec2(-px2.x,   0.0 )).rgb);
    float mr2 = lum(texture(uTexture, uv + vec2( px2.x,   0.0 )).rgb);
    float bl2 = lum(texture(uTexture, uv + vec2(-px2.x, -px2.y)).rgb);
    float bc2 = lum(texture(uTexture, uv + vec2(  0.0,  -px2.y)).rgb);
    float br2 = lum(texture(uTexture, uv + vec2( px2.x, -px2.y)).rgb);
    float gx2 = -tl2 - 2.0*ml2 - bl2 + tr2 + 2.0*mr2 + br2;
    float gy2 = -tl2 - 2.0*tc2 - tr2 + bl2 + 2.0*bc2 + br2;

    float edge = max(sqrt(gx1*gx1 + gy1*gy1), sqrt(gx2*gx2 + gy2*gy2) * 0.7);
    float outline = smoothstep(0.14, 0.38, edge);
    col = mix(col, vec3(0.0), outline);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
