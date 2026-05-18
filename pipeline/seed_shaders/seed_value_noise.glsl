// Value noise — hash-lattice noise modulating camera brightness.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    float n = vnoise(uv * 8.0 + iTime * 0.5);
    vec3 cam = texture(iChannel0, uv).rgb;
    fragColor = vec4(cam * (0.6 + 0.8 * n), 1.0);
}
