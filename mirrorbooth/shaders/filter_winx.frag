#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

vec3 hue2rgb(float h) {
    float h6 = fract(h) * 6.0;
    float x  = 1.0 - abs(mod(h6, 2.0) - 1.0);
    if      (h6 < 1.0) return vec3(1.0, x,   0.0);
    else if (h6 < 2.0) return vec3(x,   1.0, 0.0);
    else if (h6 < 3.0) return vec3(0.0, 1.0, x  );
    else if (h6 < 4.0) return vec3(0.0, x,   1.0);
    else if (h6 < 5.0) return vec3(x,   0.0, 1.0);
    else               return vec3(1.0, 0.0, x  );
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;
    vec2 px = 1.0 / uResolution;

    vec3 col = texture(uTexture, uv).rgb;
    float l = lum(col);

    // Vivid magical-girl saturation boost
    col = mix(vec3(l), col, 1.65);

    // 6-level posterize
    col = floor(col * 6.0 + 0.5) / 6.0;

    // Sobel
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
    float onEdge = smoothstep(0.18, 0.45, sqrt(gx*gx + gy*gy));

    // Rainbow outline (hue cycles with time + position)
    vec3 rainbowCol = hue2rgb(fract(uTime * 0.28 + uv.x * 0.55 + uv.y * 0.3));
    col = mix(col, rainbowCol, onEdge);

    // Animované sparkles: náhodné buňky s blikáním
    float n = fract(sin(dot(floor(fragCoord / 11.0), vec2(12.9898, 78.233))) * 43758.5453);
    float sparkle = step(0.965, n) * max(0.0, sin(uTime * 9.0 + n * 22.0));
    col = mix(col, vec3(1.0), sparkle);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
