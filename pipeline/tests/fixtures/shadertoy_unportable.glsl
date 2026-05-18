// Unportable fixture - relies on iMouse and a second channel.
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 m = iMouse.xy / iResolution.xy;
    vec4 a = texture(iChannel0, uv);
    vec4 b = texture(iChannel1, uv + m);
    fragColor = mix(a, b, 0.5);
}
