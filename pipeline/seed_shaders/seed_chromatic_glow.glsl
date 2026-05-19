// Chromatic glow — radial RGB split plus bloom around bright camera areas.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 dir = uv - 0.5;
    float amt = 0.012 * (1.0 + 0.5 * sin(iTime));
    float r = texture(iChannel0, uv + dir * amt).r;
    float g = texture(iChannel0, uv).g;
    float b = texture(iChannel0, uv - dir * amt).b;
    vec3 col = vec3(r, g, b);
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    col += smoothstep(0.6, 1.0, lum) * 0.5;
    fragColor = vec4(col, 1.0);
}
