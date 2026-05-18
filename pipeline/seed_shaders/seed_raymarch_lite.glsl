// Raymarch lite — single sphere SDF sphere-trace, camera as environment.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
float sdSphere(vec3 p, float r) { return length(p) - r; }
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 ro = vec3(0.0, 0.0, -3.0);
    vec3 rd = normalize(vec3(uv, 1.5));
    float t = 0.0;
    float hit = 0.0;
    for (int i = 0; i < 48; i++) {
        vec3 p = ro + rd * t;
        float d = sdSphere(p, 1.0 + 0.1 * sin(iTime));
        if (d < 0.001) { hit = 1.0; break; }
        t += d;
        if (t > 10.0) break;
    }
    vec3 bg = texture(iChannel0, fragCoord / iResolution.xy).rgb;
    vec3 col = mix(bg, vec3(0.9, 0.6, 0.3), hit * 0.8);
    fragColor = vec4(col, 1.0);
}
