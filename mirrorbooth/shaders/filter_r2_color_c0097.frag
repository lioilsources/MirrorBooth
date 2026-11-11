#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 src = texture(uTexture, uv).rgb;

    // Apply Shader B's core: posterized duotone with edge-aware blending
    float n = 6.0;
    float l = luma(src);
    float q = floor(clamp(l, 0.0, 0.999) * n);
    vec2 off = vec2(-4.0, -6.0) / uResolution;
    float ls = luma(texture(uTexture, uv + off).rgb);
    float qs = floor(clamp(ls, 0.0, 0.999) * n);
    vec3 col = vec3(0.12, 0.15, 0.32);
    if (q > 4.5) { col = vec3(0.98, 0.94, 0.84); }
    else if (q > 3.5) { col = vec3(0.97, 0.74, 0.34); }
    else if (q > 2.5) { col = vec3(0.89, 0.35, 0.32); }
    else if (q > 1.5) { col = vec3(0.39, 0.19, 0.44); }
    col *= 1.0 - 0.3 * step(q + 0.5, qs);

    // Apply bilateral-like blur (from Shader B) but use Shader A's motion offset
    vec2 px = 2.0 / uResolution;
    vec3 center = src;
    vec3 accum = vec3(0.0);
    float wTotal = 0.0;

    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            vec3 s = texture(uTexture, uv + vec2(float(i), float(j)) * px).rgb;
            float d = length(s - center);
            float w = exp(-d * d * 18.0);
            accum += s * w;
            wTotal += w;
        }
    }

    vec3 blurred = accum / wTotal;
    col = mix(vec3(luma(col)), blurred, 0.6);

    // Apply smoothstep edge darkening (from Shader B) for impasto effect
    float eL = luma(texture(uTexture, uv + vec2(-px.x, 0.0)).rgb);
    float eR = luma(texture(uTexture, uv + vec2(px.x, 0.0)).rgb);
    float eU = luma(texture(uTexture, uv + vec2(0.0, px.y)).rgb);
    float eD = luma(texture(uTexture, uv + vec2(0.0, -px.y)).rgb);
    float edge = sqrt((eR - eL) * (eR - eL) + (eU - eD) * (eU - eD));
    col *= 1.0 - smoothstep(0.08, 0.35, edge) * 0.25;

    // Now apply Shader A's dynamic motion distortion and color grading
    vec2 aspect = vec2(uResolution.x / uResolution.y, 1.0);
    vec2 offs = vec2(0.0);
    float spec = 0.0;
    for (int k = 0; k < 2; k++) {
        float sc = k == 0 ? 7.0 : 12.0;
        vec2 p = vec2(uv.x * aspect.x, uv.y) * sc;
        vec2 id = floor(p);
        p.y -= uTime * (0.35 + 0.5 * fract(dot(id, vec2(123.34, 456.21))) + 0.1 * float(k)) * sc * 0.25;
        id = floor(p);
        vec2 f = fract(p) - 0.5;
        vec2 h = vec2(fract(dot(id, vec2(123.34, 456.21))), fract(dot(id + 17.1, vec2(456.21, 123.34))));
        if (h.x > 0.45) {
            vec2 c = (h - 0.5) * 0.5;
            vec2 d = f - c;
            d.y *= 0.7;
            float r = 0.16 + 0.1 * h.y;
            float m = smoothstep(r, r * 0.6, length(d));
            offs -= d * m * 0.5 / sc * 3.0;
            spec += m * smoothstep(0.06, 0.0, length(d - vec2(-0.05, -0.06)));
        }
    }

    vec2 suv = clamp(uv + vec2(offs.x / aspect.x, offs.y), 0.0, 1.0);
    vec3 base = texture(uTexture, suv).rgb;
    base *= vec3(0.86, 0.93, 1.0);
    base += spec * 0.8;

    // Final color grading: duotone + posterize + gradient mapping
    float lBase = luma(base);
    lBase = smoothstep(0.05, 0.95, lBase);
    vec3 lo = vec3(0.1, 0.05, 0.38);
    vec3 mid = vec3(0.93, 0.18, 0.5);
    vec3 hi = vec3(1.0, 0.92, 0.45);
    vec3 graded = lBase < 0.5 ? mix(lo, mid, lBase * 2.0) : mix(mid, hi, lBase * 2.0 - 1.0);
    graded = floor(graded * 4.0) / 4.0;

    // Final blend: mix Shader B's result with Shader A's graded base using smoothstep and floor
    float blend = smoothstep(0.1, 0.9, luma(src));
    vec3 finalColor = mix(col, graded, blend);

    // Apply thermal effect via floor and smoothstep
    float gray = luma(src);
    float t = (gray + 0.5 * sin(uTime * 0.3)) * 0.5;
    vec3 thermal = vec3(
        smoothstep(0.0, 0.4, t),
        smoothstep(0.3, 0.6, t),
        smoothstep(0.6, 1.0, t)
    );

    // Final output: blend with thermal using mix and floor-based modulation
    float timeFactor = floor(uTime * 3.0) * 0.1;
    float adjusted = (t + timeFactor) * 0.9;
    finalColor = mix(finalColor, thermal, smoothstep(0.2, 0.8, adjusted));

    fragColor = vec4(finalColor, 1.0);
}
