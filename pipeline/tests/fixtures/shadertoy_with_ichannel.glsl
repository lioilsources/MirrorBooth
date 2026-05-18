// Wobble test fixture - samples the camera channel (iChannel0).
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    uv.x += 0.02 * sin(uv.y * 20.0 + iTime);
    vec4 cam = texture2D(iChannel0, uv);
    fragColor = vec4(cam.rgb * 1.1, 1.0);
}
