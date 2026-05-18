// Voronoi — cellular partition recoloring the camera by nearest seed.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
vec2 hash2(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)),
                          dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 g = floor(uv * 8.0);
    vec2 f = fract(uv * 8.0);
    float md = 8.0;
    vec2 mc = vec2(0.0);
    for (int y = -1; y <= 1; y++)
    for (int x = -1; x <= 1; x++) {
        vec2 o = vec2(float(x), float(y));
        vec2 p = o + hash2(g + o) * (0.5 + 0.5 * sin(iTime + 6.2831 * hash2(g + o).x)) - f;
        float d = dot(p, p);
        if (d < md) { md = d; mc = g + o; }
    }
    vec3 cell = 0.5 + 0.5 * cos(vec3(0.0, 2.0, 4.0) + dot(mc, vec2(0.7)));
    vec3 cam = texture(iChannel0, uv).rgb;
    fragColor = vec4(mix(cam, cell, 0.5), 1.0);
}
