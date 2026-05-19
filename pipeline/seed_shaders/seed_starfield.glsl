// Starfield — procedural drifting stars composited over the camera.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec3 cam = texture(iChannel0, uv).rgb;
    vec2 g = floor(uv * 60.0 + vec2(iTime * 4.0, 0.0));
    float s = step(0.985, hash(g));
    float tw = 0.5 + 0.5 * sin(iTime * 3.0 + hash(g) * 6.2831);
    vec3 col = cam * 0.7 + vec3(s * tw);
    fragColor = vec4(col, 1.0);
}
