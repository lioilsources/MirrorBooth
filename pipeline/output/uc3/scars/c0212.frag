#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

// face coordinates: eyes ~ (+-0.30, -0.15), nose ~ (0, 0.05), mouth ~ (0, 0.35)
vec2 faceQ(vec2 uv) { vec2 q = (uv - uFaceCenter) / uFaceScale; q.x *= uResolution.x / uResolution.y; return q; }
float ell(vec2 q, vec2 c, vec2 r) { return 1.0 - smoothstep(0.6, 1.0, length((q - c) / r)); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y); }
float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

// Transfer: Add subtle eye magnification from the "Chibi" filter to enhance the facial realism
// while keeping the scar/bruise theme. This subtly draws attention to the eyes, emphasizing
// the contrast between beauty and injury.
vec2 eyeLens(vec2 d, vec2 eye, float R) {
    vec2 k = d - eye;
    float sigma = 0.26 * R;
    float w = exp(-dot(k, k) / (sigma * sigma));
    return k * (1.0 - 0.20 * w) + eye - d;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float aspect = uResolution.x / uResolution.y;
    float R = uFaceScale;

    vec2 d = uv - uFaceCenter;
    d.x *= aspect;

    vec2 eyeL = vec2(-0.32 * R, -0.30 * R);
    vec2 eyeR = vec2(0.32 * R, -0.30 * R);

    // Apply eye lens distortion to subtly magnify the eyes — transferred from Chibi
    vec2 src = d + eyeLens(d, eyeL, R) + eyeLens(d, eyeR, R);
    src.x /= aspect;
    vec2 wUV = clamp(uFaceCenter + src, 0.0, 1.0);

    vec3 col = texture(uTexture, wUV).rgb;

    // Face-relative coordinates
    vec2 q = faceQ(uv);

    // Stitched scar: vertical line across center, with texture noise
    float scar = smoothstep(0.02, 0.0, abs(q.x)) * (1.0 - smoothstep(0.0, 0.05, abs(q.x))) * (1.0 - ell(q, vec2(0.0, 0.25), vec2(0.1, 0.05)));
    float scarNoise = noise(q * 12.0) * 0.5 + noise(q * 24.0) * 0.3;
    scar *= 0.8 + scarNoise;

    // Bruises: irregular dark patches around eyes and mouth
    float bruiseL = ell(q, vec2(-0.28, -0.10), vec2(0.12, 0.08)) * (1.0 - noise(q * 10.0) * 0.5);
    float bruiseR = ell(q, vec2(0.28, -0.10), vec2(0.12, 0.08)) * (1.0 - noise(q * 10.0 + 1.0) * 0.5);
    float bruiseMouth = ell(q, vec2(0.0, 0.30), vec2(0.18, 0.10)) * (1.0 - noise(q * 8.0 + 2.0) * 0.6);

    // Burn marks: jagged, red-orange patches with noise
    float burn = 0.0;
    float burnNoise = noise(q * 20.0 + 3.0);
    if (q.y > 0.1 && abs(q.x) < 0.3) {
        float dist = length(q - vec2(0.0, 0.2));
        float edge = smoothstep(0.08, 0.04, dist);
        burn = edge * (1.0 - 0.5 * noise(q * 15.0 + 4.0)) * (0.5 + 0.5 * sin(burnNoise * 6.28));
    }

    // Combine all damage elements
    float damage = max(scar, max(bruiseL, max(bruiseR, max(bruiseMouth, burn))));
    vec3 damageColor = vec3(0.7, 0.2, 0.1) * 0.8 + vec3(0.4, 0.0, 0.0) * 0.5; // Burn/bruise tone
    col = mix(col, damageColor, damage * 0.8);

    // Final touch: subtle brightness boost to keep the face readable
    col = pow(clamp(col, 0.0, 1.0), vec3(0.95));

    // Apply the stitched scar from Shader A: a dynamic, wobbling line across the face
    vec2 a = vec2(0.15, -0.05);
    vec2 b = vec2(0.55, 0.35);
    vec2 ab = b - a;
    float t = clamp(dot(q - a, ab) / dot(ab, ab), 0.0, 1.0);
    vec2 p = a + ab * t;
    float dist = length(q - p);
    float wob = 0.008 * sin(t * 40.0);
    float scarA = 1.0 - smoothstep(0.010, 0.022, abs(dist + wob));
    float rim = (1.0 - smoothstep(0.02, 0.06, dist)) * (1.0 - scarA);
    col = mix(col, col * vec3(1.15, 0.75, 0.75), rim * 0.6);
    col = mix(col, vec3(0.55, 0.15, 0.15), scarA * 0.8);
    vec2 n = normalize(vec2(-ab.y, ab.x));
    float st = step(abs(fract(t * 9.0) - 0.5), 0.06) * (1.0 - smoothstep(0.0, 0.05, abs(dot(q - p, n)))) * step(0.03, t) * step(t, 0.97);
    col = mix(col, vec3(0.08, 0.05, 0.05), st);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
