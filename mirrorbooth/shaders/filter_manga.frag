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

    // B&W halftone: dark areas → bigger dots
    float cellSize = 8.0;
    vec2 cellCenter = floor(fragCoord / cellSize) * cellSize + cellSize * 0.5;
    float cellLum = lum(texture(uTexture, cellCenter / uResolution).rgb);
    float dotR = (1.0 - cellLum) * cellSize * 0.52;
    float inDot = 1.0 - smoothstep(dotR - 0.6, dotR + 0.6, length(fragCoord - cellCenter));
    float halftone = 1.0 - inDot; // 1=white paper, 0=black dot

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
    float outline = smoothstep(0.12, 0.45, sqrt(gx*gx + gy*gy));

    // Radiální speed lines ze středu, animované
    vec2 dir = uv - 0.5;
    float r = length(dir);
    float angle = atan(dir.y, dir.x);
    float spoke = fract(angle * 10.0 / 3.14159 + uTime * 0.25);
    float speedLine = smoothstep(0.88, 1.0, spoke)
                    * smoothstep(0.15, 0.38, r)
                    * (1.0 - smoothstep(0.36, 0.48, r));

    float paper = min(halftone, 1.0 - outline);
    float result = paper * (1.0 - speedLine * 0.9);

    fragColor = vec4(vec3(clamp(result, 0.0, 1.0)), 1.0);
}
