// Hex grid — quantize the camera into a hexagonal mosaic.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
vec4 hexCenter(vec2 p) {
    vec2 r = vec2(1.0, 1.7320508);
    vec2 h = r * 0.5;
    vec2 a = mod(p, r) - h;
    vec2 b = mod(p - h, r) - h;
    vec2 gv = dot(a, a) < dot(b, b) ? a : b;
    return vec4(p - gv, gv);
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    float scale = 18.0 + 6.0 * sin(iTime * 0.5);
    vec4 hc = hexCenter(uv * scale);
    vec2 sampleUv = hc.xy / scale;
    vec3 cam = texture(iChannel0, sampleUv).rgb;
    fragColor = vec4(cam, 1.0);
}
