// fBm — fractal Brownian motion clouds blended with the camera.
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(41.3, 289.1))) * 13571.97);
}
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
               mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
    float s = 0.0, a = 0.5;
    for (int k = 0; k < 5; k++) {
        s += a * noise(p);
        p *= 2.02;
        a *= 0.5;
    }
    return s;
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    float f = fbm(uv * 4.0 + vec2(iTime * 0.2, 0.0));
    vec3 cam = texture(iChannel0, uv).rgb;
    vec3 tint = vec3(0.2, 0.4, 0.7) * f;
    fragColor = vec4(cam * 0.6 + tint, 1.0);
}
