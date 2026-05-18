// Domain warp — feed UVs through a noise field before sampling the camera.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
               mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 q = vec2(noise(uv * 3.0 + iTime * 0.1),
                  noise(uv * 3.0 + vec2(5.2, 1.3) - iTime * 0.1));
    vec2 warped = uv + 0.06 * (q - 0.5);
    fragColor = vec4(texture(iChannel0, warped).rgb, 1.0);
}
