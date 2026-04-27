#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 px = 1.0 / uResolution;

    // Soft 3-tap blur for painted look
    vec3 col = texture(uTexture, uv).rgb * 2.0;
    col += texture(uTexture, uv + vec2( px.x, 0.0)).rgb;
    col += texture(uTexture, uv + vec2(-px.x, 0.0)).rgb;
    col /= 4.0;

    // 7-level soft posterize
    col = floor(col * 7.0 + 0.5) / 7.0;

    // Warm cinematic tint (golden afternoon light)
    col *= vec3(1.08, 1.02, 0.88);

    // Very gentle Sobel outlines
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
    float outline = smoothstep(0.22, 0.55, sqrt(gx*gx + gy*gy));
    col = mix(col, vec3(0.08, 0.04, 0.02), outline * 0.75);

    // Soft vignette
    float vignette = 1.0 - smoothstep(0.40, 0.95, length(uv - 0.5) * 1.35);
    col *= mix(0.70, 1.0, vignette);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
