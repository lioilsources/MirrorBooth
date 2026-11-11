#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 bulgeDistort(vec2 uv, vec2 center, float strength, float radius) {
    vec2 d = uv - center;
    float r = length(d);
    float theta = atan(d.y, d.x);
    float distortedR = r + strength * r * r * (1.0 - r / radius);
    return center + vec2(cos(theta), sin(theta)) * distortedR;
}

float hash21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
vec2 hash22(vec2 p) { float n = hash21(p); return vec2(n, hash21(p + n + 17.1)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float aspect = uResolution.x / uResolution.y;
    float R = uFaceScale;

    vec2 d = uv - uFaceCenter;
    d.x *= aspect;
    float r = max(length(d), 0.0001);

    float distortStrength = 0.9;
    float maxDist = 0.4 * R;

    vec2 distortedUV = bulgeDistort(uv, uFaceCenter, distortStrength, maxDist);
    distortedUV.x /= aspect;

    vec2 wUV = clamp(uFaceCenter + (distortedUV - uFaceCenter) * 1.2, 0.0, 1.0);

    vec3 col = texture(uTexture, wUV).rgb;

    // Transfer glass refraction effect from Other Filter: Voronoi-like distortion with time
    vec2 p = vec2(uv.x * aspect, uv.y) * 13.0;
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    float d1 = 9.0;
    float d2 = 9.0;
    vec2 best = vec2(0.0);
    for (int j = 0; j < 3; j++) {
        for (int i = 0; i < 3; i++) {
            vec2 o = vec2(float(i) - 1.0, float(j) - 1.0);
            vec2 h = hash22(ip + o);
            vec2 pt = o + 0.5 + 0.4 * sin(uTime * 0.6 + 6.2831 * h);
            float d = length(pt - fp);
            if (d < d1) { d2 = d1; d1 = d; best = ip + pt; }
            else if (d < d2) { d2 = d; }
        }
    }
    vec2 c = best / 13.0;
    vec3 gridCol = texture(uTexture, clamp(vec2(c.x / aspect, c.y), 0.0, 1.0)).rgb;
    gridCol *= smoothstep(0.02, 0.09, d2 - d1);

    // Apply swirl from Parent Filter: angle-based twist with time
    float swirl = 0.5 + 0.5 * sin(atan(d.y, d.x) * 3.0 - uTime * 3.0);
    col = mix(col, gridCol, 0.3 * (0.5 + 0.7 * swirl));

    // Final color correction
    col = pow(clamp(col, 0.0, 1.0), vec3(0.88));

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
