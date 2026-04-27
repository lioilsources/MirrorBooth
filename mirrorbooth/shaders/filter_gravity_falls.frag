#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;
    vec2 px = 1.0 / uResolution;

    vec3 col = texture(uTexture, uv).rgb;
    float l = lum(col);

    // Grayscale → sepia
    vec3 sepia = vec3(l * 1.12, l * 0.96, l * 0.72);
    col = mix(col, sepia, 0.80);

    // Multi-scale Sobel sketch (1px + 3px)
    float tl1 = lum(texture(uTexture, uv + vec2(-px.x,  px.y)).rgb);
    float tc1 = lum(texture(uTexture, uv + vec2( 0.0,   px.y)).rgb);
    float tr1 = lum(texture(uTexture, uv + vec2( px.x,  px.y)).rgb);
    float ml1 = lum(texture(uTexture, uv + vec2(-px.x,  0.0 )).rgb);
    float mr1 = lum(texture(uTexture, uv + vec2( px.x,  0.0 )).rgb);
    float bl1 = lum(texture(uTexture, uv + vec2(-px.x, -px.y)).rgb);
    float bc1 = lum(texture(uTexture, uv + vec2( 0.0,  -px.y)).rgb);
    float br1 = lum(texture(uTexture, uv + vec2( px.x, -px.y)).rgb);
    float e1 = sqrt(pow(-tl1-2.0*ml1-bl1+tr1+2.0*mr1+br1,2.0) + pow(-tl1-2.0*tc1-tr1+bl1+2.0*bc1+br1,2.0));

    vec2 px3 = px * 3.0;
    float tl3 = lum(texture(uTexture, uv + vec2(-px3.x,  px3.y)).rgb);
    float tc3 = lum(texture(uTexture, uv + vec2(  0.0,   px3.y)).rgb);
    float tr3 = lum(texture(uTexture, uv + vec2( px3.x,  px3.y)).rgb);
    float ml3 = lum(texture(uTexture, uv + vec2(-px3.x,   0.0 )).rgb);
    float mr3 = lum(texture(uTexture, uv + vec2( px3.x,   0.0 )).rgb);
    float bl3 = lum(texture(uTexture, uv + vec2(-px3.x, -px3.y)).rgb);
    float bc3 = lum(texture(uTexture, uv + vec2(  0.0,  -px3.y)).rgb);
    float br3 = lum(texture(uTexture, uv + vec2( px3.x, -px3.y)).rgb);
    float e3 = sqrt(pow(-tl3-2.0*ml3-bl3+tr3+2.0*mr3+br3,2.0) + pow(-tl3-2.0*tc3-tr3+bl3+2.0*bc3+br3,2.0));

    float sketch = smoothstep(0.10, 0.40, max(e1, e3 * 0.55));
    col = mix(col, vec3(0.12, 0.06, 0.02), sketch * 0.90);

    // Paper grain
    float grain = hash(fragCoord) * 0.08 - 0.04;
    col += grain;

    // Vignette
    float vignette = 1.0 - smoothstep(0.35, 0.90, length(uv - 0.5) * 1.4);
    col *= mix(0.55, 1.0, vignette);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
