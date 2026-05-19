// Metaballs — smooth implicit blobs masking a stylized camera.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float f = 0.0;
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        vec2 c = 0.4 * vec2(sin(iTime + fi * 1.7), cos(iTime * 1.3 + fi));
        f += 0.03 / dot(uv - c, uv - c);
    }
    float m = smoothstep(0.8, 1.2, f);
    vec3 cam = texture(iChannel0, fragCoord / iResolution.xy).rgb;
    vec3 blob = vec3(0.1, 0.8, 0.9);
    fragColor = vec4(mix(cam, blob, m), 1.0);
}
