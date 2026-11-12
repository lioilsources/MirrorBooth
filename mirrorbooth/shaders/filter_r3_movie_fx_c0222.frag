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

vec3 applyDistortion(vec2 uv, float time) {
    vec2 grid = floor(uv * 18.0) + floor(time * 3.0);
    float warp = fract(sin(dot(grid, vec2(11.7, 83.9))) * 12345.6);
    return texture(uTexture, uv + vec2(warp - 0.5, warp - 0.5) * 0.008).rgb;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 q = faceQ(uv);

    vec3 baseColor = applyDistortion(uv, uTime);

    // Zombie: decaying skin with deep cracks and greenish hue
    float zombieEffect = 1.0 - smoothstep(0.6, 1.0, length(q));
    baseColor += vec3(0.08, 0.28, 0.18) * zombieEffect * (0.7 + 0.3 * sin(uTime * 3.2));

    // Burned skin: intense red-orange flares with flicker
    float burnEffect = smoothstep(0.72, 1.0, length(q));
    baseColor += vec3(0.85, 0.35, 0.15) * burnEffect * (0.5 + 0.5 * sin(uTime * 2.8 + uv.x * 12.0));

    // Cyborg metal plate: angular reflective panel on temple
    vec2 plateCenter = uFaceCenter + vec2(0.2, -0.1) * uFaceScale;
    vec2 plateOffset = (uv - plateCenter) * vec2(uResolution.x / uResolution.y, 1.0) / (0.13 * uFaceScale);
    float plateEffect = 1.0 - smoothstep(0.58, 0.82, length(plateOffset));
    vec3 metalColor = vec3(0.75, 0.8, 0.95) * plateEffect;
    metalColor += vec3(1.0, 1.0, 1.0) * 0.8 * plateEffect * sin(uTime * 6.2 + uv.x * 16.0 + uv.y * 9.0);
    baseColor += metalColor * 0.6;

    // Werewolf: coarse, dark fur texture with subtle movement
    float furEffect = smoothstep(0.78, 1.0, length(q));
    float furNoise = noise(vec2(q.x * 30.0, q.y * 90.0)) * 0.6 + noise(q * 140.0) * 0.4;
    baseColor += vec3(0.12, 0.12, 0.18) * furEffect * (0.4 + 0.6 * furNoise);

    // Mummy: tight, dusty bandage wrap around forehead
    vec2 bandageCenter = uFaceCenter + vec2(0.0, 0.06) * uFaceScale;
    vec2 bandageOffset = (uv - bandageCenter) * vec2(uResolution.x / uResolution.y, 1.0) / (0.32 * uFaceScale);
    float bandageEffect = 1.0 - smoothstep(0.52, 0.9, length(bandageOffset));
    baseColor += vec3(0.92, 0.88, 0.75) * bandageEffect * 0.45;

    // Transfer: enhanced facial texture from other filter (fur + darkness)
    float face = ell(q, vec2(0.0, 0.0), vec2(0.70, 0.95));
    float darkening = ell(q, vec2(0.0, 0.14), vec2(0.09, 0.06));
    baseColor = mix(baseColor, baseColor * vec3(0.85, 0.65, 0.45) * (0.7 + 0.6 * furNoise), face * 0.6);
    baseColor = mix(baseColor, vec3(0.08, 0.05, 0.05), darkening);

    // Final dark edge glow
    vec2 d = uv - vec2(0.5);
    d.x *= uResolution.x / uResolution.y;
    float r = length(d);
    vec3 vignette = mix(baseColor, vec3(0.09, 0.03, 0.06), smoothstep(0.62, 0.92, r));

    fragColor = vec4(clamp(vignette, 0.0, 1.0), 1.0);
}
