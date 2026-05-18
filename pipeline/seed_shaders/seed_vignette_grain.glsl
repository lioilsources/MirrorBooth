// Vignette grain — cinematic darkened edges plus animated film grain.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec3 cam = texture(iChannel0, uv).rgb;
    float vig = smoothstep(0.9, 0.2, length(uv - 0.5));
    float grain = (hash(uv + fract(iTime)) - 0.5) * 0.12;
    fragColor = vec4(cam * vig + grain, 1.0);
}
