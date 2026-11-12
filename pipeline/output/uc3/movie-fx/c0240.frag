#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 faceQ(vec2 uv) { vec2 q = (uv - uFaceCenter) / uFaceScale; q.x *= uResolution.x / uResolution.y; return q; }
float ell(vec2 q, vec2 c, vec2 r) { return 1.0 - smoothstep(0.6, 1.0, length((q - c) / r)); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y); }
float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

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

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 q = faceQ(uv);
    vec3 col = texture(uTexture, uv).rgb;
    float l = lum(col);

    // Core: zombie decay – gray-green tone, desaturated, with pulsing lifelessness
    col = mix(vec3(l), col, 0.4) * vec3(0.62, 0.80, 0.58);

    // Burned skin: high-contrast random dark patches with dynamic noise
    float burn = noise(uv * 18.0 + uTime * 0.4) * 0.4;
    burn = step(0.92, burn);
    col = mix(col, vec3(0.15, 0.05, 0.0), burn * 0.4);

    // Cyborg metal plate: irregular metallic sheen centered on face, reacting to face scale
    float plate = smoothstep(0.35, 0.65, abs(q.x * 0.9));
    float metal = noise(uv * 15.0 + uTime * 0.5) * 0.3 + 0.7;
    col = mix(col, vec3(0.7, 0.7, 0.7) * (0.9 + 0.1 * l), plate * metal * 0.5 * uFaceScale);

    // Werewolf transformation: glowing eyes and facial distortion
    vec2 e = vec2(uFaceCenter.x, uFaceCenter.y - 0.35 * uFaceScale);
    vec2 k = uv - e;
    k.x *= (uResolution.x / uResolution.y) * 0.6;
    float sigma = 0.35 * uFaceScale;
    float w = exp(-dot(k, k) / (sigma * sigma));
    col *= 1.0 - 0.6 * w;

    // Werewolf eyes: deepened with flickering glow
    float eyes = max(ell(q, vec2(-0.30, -0.15), vec2(0.15, 0.21)), ell(q, vec2(0.30, -0.15), vec2(0.15, 0.21)));
    col = mix(col, vec3(0.05, 0.08, 0.12) + col * 0.25, eyes * 0.9);

    // Mummy bandage wrap: crisscross pattern with tension on face
    float wrap = 0.0;
    float wrapX = abs(fract((uv.x + 0.5) * 12.0) - 0.5) * 2.0;
    float wrapY = abs(fract((uv.y + 0.5) * 12.0) - 0.5) * 2.0;
    wrap += smoothstep(0.75, 0.9, wrapX) * smoothstep(0.75, 0.9, wrapY);
    wrap *= 0.3 * exp(-length(q) * 0.8);
    col = mix(col, vec3(0.95, 0.90, 0.80), wrap);

    // Mummy mouth: decayed teeth with decayed lip effect
    float teeth = step(abs(q.x), 0.25) * (1.0 - smoothstep(0.08, 0.11, abs(q.y - 0.38)));
    float gaps = (1.0 - smoothstep(0.005, 0.01, (0.5 - abs(fract(q.x * 10.0) - 0.5)) / 10.0)) * teeth;
    float lip = (1.0 - smoothstep(0.006, 0.015, abs(q.y - 0.38))) * step(abs(q.x), 0.27);
    col = mix(col, vec3(0.03), max(lip, gaps) * 0.5);

    // Face-centered decay: skin rot and peeling texture using noise
    float face = exp(-dot((uv - uFaceCenter) * vec2(uResolution.x / uResolution.y, 1.0), (uv - uFaceCenter) * vec2(uResolution.x / uResolution.y, 1.0)) / (0.8 * uFaceScale * uFaceScale));
    float decay = noise(uv * 25.0 + uTime * 0.6) * 0.6;
    col = mix(col, col * vec3(0.45, 0.55, 0.40), decay * face * 0.4);

    // Heat shimmer (replaced with wobble effect): subtle wave distortion at bottom
    float amp = 0.002 * (0.3 + 0.7 * uv.y);
    vec2 sUV = uv;
    sUV.x += sin(uv.y * 50.0 + uTime * 8.0) * amp;
    sUV = clamp(sUV, 0.0, 1.0);
    col = mix(col, texture(uTexture, sUV).rgb, 0.1);

    // Infernal tint: dark red hue for dramatic mood
    col *= vec3(1.3, 0.5, 0.45);
    col = pow(clamp(col, 0.0, 1.0), vec3(1.1));

    // Eye flicker: sudden flashes of red glow
    float flicker = 0.7 + 0.3 * sin(uTime * 10.0) + 0.05 * sin(uTime * 25.0);
    col += vec3(1.0, 0.2, 0.05) * w * flicker * 0.6;

    // Ember sparks: confined to edges, flickering with time
    vec2 d = uv - vec2(0.5);
    d.x *= uResolution.x / uResolution.y;
    float r = length(d);
    float edge = smoothstep(0.4, 0.7, r);
    vec2 cell = floor(uv * 100.0) + floor(uTime * 8.0);
    float spark = step(0.99, rand(cell));
    col += vec3(1.0, 0.6, 0.2) * spark * edge * 0.4;

    // Vignette: dark red fade to corners
    col = mix(col, vec3(0.12, 0.0, 0.0), smoothstep(0.6, 0.9, r));

    // Final: enhance metal plate with dynamic reflectivity
    float plateCenter = 0.5 * (1.0 - abs(q.y - 0.02));
    float plateEffect = smoothstep(0.3, 0.6, abs(q.x)) * plateCenter;
    float plateSheen = noise(q * 10.0 + uTime * 0.4) * 0.2 + 0.8;
    col = mix(col, vec3(0.7, 0.7, 0.8) * plateSheen, plateEffect * 0.5);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
