// Procedural stand-in for Shadertoy's preset noise textures (/media/a/*.png).
// stNoiseTex(uv) mimics a 256x256 RGBA white-noise texture sampled with
// linear filtering and repeat wrap: smooth value noise over a 256-cell grid.
vec4 stHash44(vec2 p) {
    vec4 p4 = fract(vec4(p.xyxy) * vec4(0.1031, 0.1030, 0.0973, 0.1099));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

vec4 stNoiseTex(vec2 uv) {
    vec2 x = uv * 256.0 - 0.5;
    vec2 i = floor(x);
    vec2 f = fract(x);
    vec4 a = stHash44(mod(i, 256.0));
    vec4 b = stHash44(mod(i + vec2(1.0, 0.0), 256.0));
    vec4 c = stHash44(mod(i + vec2(0.0, 1.0), 256.0));
    vec4 d = stHash44(mod(i + vec2(1.0, 1.0), 256.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
