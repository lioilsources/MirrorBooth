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

// Transfer: Apply the "crown" stitch pattern from Shader A to Shader B's output
vec2 jellyWobble(vec2 uv, vec2 center, float scale) {
    float aspect = uResolution.x / uResolution.y;
    vec2 d = (uv - center) * vec2(aspect, 1.0);

    vec2 offset = vec2(0.6 * scale, 0.15 * scale);
    float dist = length(d - offset);
    float influence = exp(-dist * dist / (0.3 * scale * scale));
    float wobble = 0.15 * influence * sin(2.0 * 3.14159 * dist / (0.4 * scale));

    d.x += wobble * aspect;
    d.y += wobble * 0.4;

    return center + d / vec2(aspect, 1.0);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 q = faceQ(uv);

  // First, apply Shader B's core effect: a stitched scar along a facial path
  vec3 col = texture(uTexture, uv).rgb;
  vec2 a = vec2(0.15, -0.05);
  vec2 b = vec2(0.55, 0.35);
  vec2 ab = b - a;
  float t = clamp(dot(q - a, ab) / dot(ab, ab), 0.0, 1.0);
  vec2 p = a + ab * t;
  float dist = length(q - p);
  float wob = 0.008 * sin(t * 40.0);
  float scar = 1.0 - smoothstep(0.010, 0.022, abs(dist + wob));
  float rim = (1.0 - smoothstep(0.02, 0.06, dist)) * (1.0 - scar);
  col = mix(col, col * vec3(1.15, 0.75, 0.75), rim * 0.6);
  col = mix(col, vec3(0.55, 0.15, 0.15), scar * 0.8);
  vec2 n = normalize(vec2(-ab.y, ab.x));
  float st = step(abs(fract(t * 9.0) - 0.5), 0.06) * (1.0 - smoothstep(0.0, 0.05, abs(dot(q - p, n)))) * step(0.03, t) * step(t, 0.97);
  col = mix(col, vec3(0.08, 0.05, 0.05), st);

  // Apply jelly wobble distortion from Shader A to simulate uneven, stitched skin
  vec2 distortedUV = jellyWobble(uv, uFaceCenter, uFaceScale);
  col = mix(col, texture(uTexture, distortedUV).rgb, 0.15);

  // Transfer: Add the "crown" pattern (stitches) from Shader A
  float y = q.y + 0.95;
  float x = q.x;
  float band = step(abs(x), 0.45) * step(0.0, y) * step(y, 0.08);
  float spikes = step(abs(x), 0.45) * step(-0.25 + 0.25 * abs(fract(x * 3.0 + 0.5) * 2.0 - 1.0), y) * step(y, 0.0);
  float crown = max(band, spikes);
  vec3 gold = vec3(0.95, 0.75, 0.25) * (0.75 + 0.35 * smoothstep(-0.25, 0.08, y));
  col = mix(col, gold, crown * 0.92);

  // Add burn marks using noise and zone logic from Shader A
  float nBurn = noise(q * 7.0) * 0.5 + noise(q * 19.0) * 0.3 + noise(q * 41.0) * 0.2;
  float zone = smoothstep(0.75, 0.35, length((q - vec2(-0.38, 0.22)) / vec2(0.30, 0.38)) + (nBurn - 0.5) * 0.6);
  vec3 burn = mix(vec3(0.55, 0.12, 0.08), vec3(0.95, 0.55, 0.45), nBurn) * (0.5 + lum(col));
  col = mix(col, burn, zone * 0.8);
  col = mix(col, vec3(0.12, 0.06, 0.04), zone * smoothstep(0.62, 0.8, nBurn) * 0.7);

  // Add bruises: darker, purplish patches around face center
  float bruise = smoothstep(0.2, 0.1, length(q - vec2(0.0, 0.1))) * (1.0 - smoothstep(0.4, 0.6, length(q - vec2(0.0, 0.1))));
  vec3 bruiseColor = vec3(0.3, 0.0, 0.3) * 0.8;
  col = mix(col, bruiseColor, bruise * 0.6);

  // Final blend: ensure face remains recognizable with subtle texture
  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
