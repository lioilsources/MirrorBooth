#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;

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
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 px = 1.0 / uResolution;

    vec3 col = texture(uTexture, uv).rgb;
    float l = lum(col);

    // Pastelizace: light desaturate + push to white
    col = mix(vec3(l), col, 0.72);
    col = mix(col, vec3(1.0), 0.22);

    // 6-level posterize
    col = floor(col * 6.0 + 0.5) / 6.0;

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
    float outline = smoothstep(0.12, 0.40, sqrt(gx*gx + gy*gy));
    col = mix(col, vec3(0.18, 0.05, 0.22), outline * 0.88);

    // Rainbow shimmer on bright highlights (cutie mark sparkle)
    float highlight = smoothstep(0.72, 0.92, l);
    float hueShift = uv.x * 0.7 + uv.y * 0.5;
    vec3 rainbow = hue2rgb(hueShift);
    rainbow = mix(vec3(lum(rainbow)), rainbow, 0.5);
    rainbow = mix(rainbow, vec3(1.0), 0.35);
    col = mix(col, rainbow, highlight * 0.55);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
