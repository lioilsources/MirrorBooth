// Tunnel — polar remap producing an infinite receding camera tunnel.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);
    vec2 uv = vec2(a / 6.2831853 + 0.5, 0.2 / r + iTime * 0.3);
    vec3 cam = texture(iChannel0, fract(uv)).rgb;
    fragColor = vec4(cam * smoothstep(0.0, 0.4, r), 1.0);
}
