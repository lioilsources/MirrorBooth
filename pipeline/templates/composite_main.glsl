// --- ShaderGen composite template (procedural Shadertoy shader x camera) ---
// The procedural colour `fx` is blended over the camera frame `cam`.
// Blend mode is selected at port time: {{BLEND_MODE}}

float stLuma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

vec3 stOverlay(vec3 base, vec3 top) {
    return mix(2.0 * base * top, 1.0 - 2.0 * (1.0 - base) * (1.0 - top), step(0.5, base));
}

float stEdge(vec2 uv) {
    vec2 px = 1.0 / uResolution;
    float tl = stLuma(texture(uTexture, uv + vec2(-px.x, -px.y)).rgb);
    float t  = stLuma(texture(uTexture, uv + vec2(0.0, -px.y)).rgb);
    float tr = stLuma(texture(uTexture, uv + vec2(px.x, -px.y)).rgb);
    float l  = stLuma(texture(uTexture, uv + vec2(-px.x, 0.0)).rgb);
    float r  = stLuma(texture(uTexture, uv + vec2(px.x, 0.0)).rgb);
    float bl = stLuma(texture(uTexture, uv + vec2(-px.x, px.y)).rgb);
    float b  = stLuma(texture(uTexture, uv + vec2(0.0, px.y)).rgb);
    float br = stLuma(texture(uTexture, uv + vec2(px.x, px.y)).rgb);
    float gx = -tl - 2.0 * l - bl + tr + 2.0 * r + br;
    float gy = -tl - 2.0 * t - tr + bl + 2.0 * b + br;
    return clamp(length(vec2(gx, gy)) * 2.0, 0.0, 1.0);
}

vec3 stBlend(vec3 cam, vec3 fx, vec2 uv) {
{{BLEND_BODY}}
}

void main() {
    vec2 fc = FlutterFragCoord().xy;
    vec2 uv = fc / uResolution;
    vec3 cam = texture(uTexture, uv).rgb;
    fc.y = uResolution.y - fc.y;
    vec4 c = vec4(0.0);
    mainImage(c, fc);
    vec3 fx = clamp(c.rgb, 0.0, 1.0);
    fragColor = vec4(clamp(stBlend(cam, fx, uv), 0.0, 1.0), 1.0);
}
