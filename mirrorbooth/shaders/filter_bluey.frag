#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 px = 1.0 / uResolution;

    // Soft blur (5-tap cross)
    vec3 col = texture(uTexture, uv).rgb * 2.0;
    col += texture(uTexture, uv + vec2( 1.5,  0.0) * px).rgb;
    col += texture(uTexture, uv + vec2(-1.5,  0.0) * px).rgb;
    col += texture(uTexture, uv + vec2( 0.0,  1.5) * px).rgb;
    col += texture(uTexture, uv + vec2( 0.0, -1.5) * px).rgb;
    col /= 6.0;

    // 6-level posterize
    col = floor(col * 6.0 + 0.5) / 6.0;

    // Pastelizace: desaturace + push k bílé
    float l = lum(col);
    col = mix(vec3(l), col, 0.70);
    col = mix(col, vec3(1.0), 0.24);

    // Thick Sobel (1px + 2px kombinace pro tučné Bluey obrysy)
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

    vec2 px2 = px * 2.0;
    float tl2 = lum(texture(uTexture, uv + vec2(-px2.x, px2.y)).rgb);
    float tr2 = lum(texture(uTexture, uv + vec2( px2.x, px2.y)).rgb);
    float bl2 = lum(texture(uTexture, uv + vec2(-px2.x,-px2.y)).rgb);
    float br2 = lum(texture(uTexture, uv + vec2( px2.x,-px2.y)).rgb);
    float gx2 = tr2 + br2 - tl2 - bl2;
    float gy2 = tl2 + tr2 - bl2 - br2;

    float edge = max(sqrt(gx1*gx1 + gy1*gy1), sqrt(gx2*gx2 + gy2*gy2) * 0.55);
    float outline = smoothstep(0.10, 0.40, edge);
    col = mix(col, vec3(0.05, 0.05, 0.12), outline * 0.95);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
