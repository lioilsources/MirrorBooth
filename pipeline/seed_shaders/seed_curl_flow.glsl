// Curl flow — advect camera UVs along a divergence-free noise flow field.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
               mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
vec2 curl(vec2 p) {
    float e = 0.01;
    float nx = noise(p + vec2(0.0, e)) - noise(p - vec2(0.0, e));
    float ny = noise(p + vec2(e, 0.0)) - noise(p - vec2(e, 0.0));
    return vec2(nx, -ny) / (2.0 * e);
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 v = curl(uv * 3.0 + iTime * 0.2);
    fragColor = vec4(texture(iChannel0, uv + 0.01 * v).rgb, 1.0);
}
