#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float rand(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

vec2 faceQ(vec2 uv) { vec2 q = (uv - uFaceCenter) / uFaceScale; q.x *= uResolution.x / uResolution.y; return q; }
float ell(vec2 q, vec2 c, vec2 r) { return 1.0 - smoothstep(0.6, 1.0, length((q - c) / r)); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y); }
float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 q = faceQ(uv);
    vec3 col = texture(uTexture, uv).rgb;
    float l = lum(col);

    // Apply the undead decay and rot blotches from the other filter
    float face = ell(q, vec2(0.0, 0.0), vec2(0.65, 0.92));
    col = mix(col, vec3(0.45, 0.75, 0.40) * (0.35 + l), face * 0.75);

    // Add dark eye sockets with intensity based on face scale
    float side = q.x < 0.0 ? -1.0 : 1.0;
    vec2 d = q - vec2(0.30 * side, -0.15);
    float ang = 0.45 * side;
    d = vec2(d.x * cos(ang) - d.y * sin(ang), d.x * sin(ang) + d.y * cos(ang));
    float eye = 1.0 - smoothstep(0.85, 1.0, length(d / vec2(0.22, 0.11)));
    col = mix(col, vec3(0.01, 0.02, 0.02), eye);

    // Add glow on the eyes
    col += eye * exp(-dot(d - vec2(-0.05, -0.03), d - vec2(-0.05, -0.03)) * 900.0) * 0.8;

    // Apply the zombie decay from the parent: gray-green tint, rot blotches
    float l_gray = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(l_gray), col, 0.4) * vec3(0.62, 0.80, 0.58);

    // Rot blotches using noise
    float n = 0.65 * vnoise(uv * 14.0) + 0.35 * vnoise(uv * 31.0);
    float blotch = smoothstep(0.60, 0.74, n) * face;
    col = mix(col, col * vec3(0.50, 0.55, 0.40), blotch);

    // Darken eye sockets further with face scale dependency
    vec2 e = vec2(uFaceCenter.x, uFaceCenter.y - 0.35 * uFaceScale);
    vec2 k = uv - e;
    k.x *= (uResolution.x / uResolution.y) * 0.6;
    float sigma = 0.32 * uFaceScale;
    float w = exp(-dot(k, k) / (sigma * sigma));
    col *= 1.0 - 0.55 * w;

    // Add cyborg metal plate using low-frequency noise
    float metal = 0.5 + 0.5 * vnoise(uv * 4.0 + uTime * 0.1);
    metal = smoothstep(0.6, 0.8, metal);
    col += vec3(0.8, 0.8, 0.8) * metal * 0.4;

    // Add burned skin patches with time-based randomness
    float burn = 0.3 + 0.7 * vnoise(uv * 20.0 + uTime * 0.3);
    burn = step(0.85, burn);
    col = mix(col, vec3(0.2, 0.05, 0.0), burn * 0.3);

    // Add werewolf fur texture
    float fur = vnoise(uv * 100.0 + uTime * 0.5);
    fur = smoothstep(0.4, 0.6, fur);
    col = mix(col, col * vec3(1.0, 1.0, 1.0), fur * 0.1);

    // Add mummy wrappings with diagonal banding
    float mummy = abs(sin(uv.y * 10.0 + uTime * 0.2)) * 0.5;
    mummy = smoothstep(0.3, 0.7, mummy);
    col = mix(col, vec3(0.8, 0.8, 0.8), mummy * 0.1);

    // Final color clamping
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
