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

    // UV wobble (underwater wave)
    vec2 wobbleUV = uv + vec2(sin(uTime * 7.0 + uv.y * 18.0) * 0.007, 0.0);
    vec3 col = texture(uTexture, wobbleUV).rgb;

    // Warm sunny yellow tint
    col *= vec3(1.15, 1.08, 0.75);

    // 5-level posterize
    col = floor(col * 5.0 + 0.5) / 5.0;

    // Sobel outlines
    vec2 wu = wobbleUV;
    float tl = lum(texture(uTexture, wu + vec2(-px.x,  px.y)).rgb);
    float tc = lum(texture(uTexture, wu + vec2( 0.0,   px.y)).rgb);
    float tr = lum(texture(uTexture, wu + vec2( px.x,  px.y)).rgb);
    float ml = lum(texture(uTexture, wu + vec2(-px.x,  0.0 )).rgb);
    float mr = lum(texture(uTexture, wu + vec2( px.x,  0.0 )).rgb);
    float bl = lum(texture(uTexture, wu + vec2(-px.x, -px.y)).rgb);
    float bc = lum(texture(uTexture, wu + vec2( 0.0,  -px.y)).rgb);
    float br = lum(texture(uTexture, wu + vec2( px.x, -px.y)).rgb);
    float gx = -tl - 2.0*ml - bl + tr + 2.0*mr + br;
    float gy = -tl - 2.0*tc - tr + bl + 2.0*bc + br;
    float outline = smoothstep(0.18, 0.45, sqrt(gx*gx + gy*gy));
    col = mix(col, vec3(0.04, 0.02, 0.0), outline * 0.95);

    // Animated bubble rings
    vec2 bubble1Center = vec2(0.18, 0.25 + sin(uTime * 0.8) * 0.05);
    vec2 bubble2Center = vec2(0.75, 0.55 + cos(uTime * 0.6) * 0.06);
    vec2 bubble3Center = vec2(0.45, 0.80 + sin(uTime * 1.1) * 0.04);
    float r1 = length(uv - bubble1Center);
    float r2 = length(uv - bubble2Center);
    float r3 = length(uv - bubble3Center);
    float bubble = smoothstep(0.055, 0.06, r1) * (1.0 - smoothstep(0.06, 0.065, r1));
    bubble      += smoothstep(0.038, 0.040, r2) * (1.0 - smoothstep(0.040, 0.043, r2));
    bubble      += smoothstep(0.028, 0.030, r3) * (1.0 - smoothstep(0.030, 0.033, r3));
    col = mix(col, vec3(0.85, 0.95, 1.0), clamp(bubble, 0.0, 1.0) * 0.75);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
