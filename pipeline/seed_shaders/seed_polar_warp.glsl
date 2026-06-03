// Polar warp — swirl the camera around center with time-varying twist.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float r = length(uv);
    float a = atan(uv.y, uv.x);
    a += (0.6 + 0.4 * sin(iTime)) * exp(-r * 2.0);
    vec2 sw = vec2(cos(a), sin(a)) * r;
    sw = sw * (iResolution.y / iResolution.xy) + 0.5;
    fragColor = vec4(texture(iChannel0, fract(sw)).rgb, 1.0);
}
