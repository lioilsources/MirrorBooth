// Truchet — randomized arc tiles masking the camera into a weave.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 g = uv * 10.0;
    vec2 id = floor(g);
    vec2 f = fract(g) - 0.5;
    if (hash(id) < 0.5) f.x = -f.x;
    float d = abs(length(f - 0.5) - 0.5);
    d = min(d, abs(length(f + 0.5) - 0.5));
    float line = smoothstep(0.08, 0.0, d - 0.05 * sin(iTime));
    vec3 cam = texture(iChannel0, uv).rgb;
    fragColor = vec4(mix(cam, vec3(1.0) - cam, line), 1.0);
}
