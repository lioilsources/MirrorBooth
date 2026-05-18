// Kaleidoscope — radial mirror symmetry of the camera around center.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float a = atan(uv.y, uv.x);
    float r = length(uv);
    float seg = 6.2831853 / 8.0;
    a = mod(a + iTime * 0.2, seg);
    a = abs(a - 0.5 * seg);
    vec2 k = vec2(cos(a), sin(a)) * r + 0.5;
    vec3 cam = texture(iChannel0, fract(k)).rgb;
    fragColor = vec4(cam, 1.0);
}
