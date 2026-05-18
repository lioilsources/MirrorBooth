// Plasma — layered sine field tinted over the camera feed.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    float t = iTime;
    float v = sin(uv.x * 10.0 + t)
            + sin((uv.y + uv.x) * 8.0 - t * 1.3)
            + sin(length(uv - 0.5) * 14.0 + t * 2.0);
    vec3 plasma = 0.5 + 0.5 * cos(vec3(0.0, 2.094, 4.188) + v);
    vec3 cam = texture(iChannel0, uv).rgb;
    fragColor = vec4(mix(cam, plasma, 0.45), 1.0);
}
