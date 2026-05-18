// Palette cycle — map camera luminance through an animated cosine palette.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
vec3 palette(float t) {
    return 0.5 + 0.5 * cos(6.2831853 * (vec3(1.0, 1.0, 1.0) * t
            + vec3(0.0, 0.33, 0.67)));
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec3 cam = texture(iChannel0, uv).rgb;
    float lum = dot(cam, vec3(0.299, 0.587, 0.114));
    vec3 pal = palette(lum + iTime * 0.15);
    fragColor = vec4(mix(cam, pal, 0.6), 1.0);
}
