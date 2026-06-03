// Scanline CRT — barrel distortion, scanlines and aperture grille.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 c = uv - 0.5;
    uv += c * dot(c, c) * 0.25;            // barrel
    vec3 col = texture(iChannel0, uv).rgb;
    float scan = 0.85 + 0.15 * sin(uv.y * iResolution.y * 3.14159 + iTime * 6.0);
    float grille = 0.9 + 0.1 * sin(uv.x * iResolution.x * 3.14159);
    col *= scan * grille;
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) col = vec3(0.0);
    fragColor = vec4(col, 1.0);
}
