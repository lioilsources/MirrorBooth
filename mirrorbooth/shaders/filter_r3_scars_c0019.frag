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

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 q = faceQ(uv);
  vec3 col = texture(uTexture, uv).rgb;

  // Transfer: Use the "slit" effect from the other filter (eye detail) to enhance the scar realism
  float side = q.x < 0.0 ? -1.0 : 1.0;
  vec2 d = q - vec2(0.30 * side, -0.15);
  float eye = 1.0 - smoothstep(0.8, 1.0, length(d / vec2(0.12, 0.07)));
  float slit = 1.0 - smoothstep(0.012, 0.022, abs(d.x));
  col = mix(col, mix(vec3(0.75, 0.70, 0.10), vec3(0.02), slit), eye * 0.9);

  // Stitched scar: diagonal scar across the cheek, using noise for uneven texture
  float scar = 1.0 - smoothstep(0.02, 0.03, abs(q.y - (q.x * 0.8 + 0.15)));
  float scarNoise = noise(q * 12.0) * 0.3;
  scar *= 0.8 + scarNoise;
  col = mix(col, vec3(0.25, 0.05, 0.05), scar * 0.8);

  // Bruises: circular, dark purple patches with noise variation
  float bruise1 = 1.0 - smoothstep(0.08, 0.12, length((q - vec2(0.35, 0.05)) / vec2(0.15, 0.10)));
  float bruise2 = 1.0 - smoothstep(0.06, 0.10, length((q - vec2(-0.30, 0.10)) / vec2(0.12, 0.08)));
  float bruiseNoise = noise(q * 15.0) * 0.5;
  col = mix(col, vec3(0.2, 0.0, 0.2) * (0.7 + bruiseNoise), (bruise1 + bruise2) * 0.6);

  // Burn marks: jagged, irregular shapes with gradient glow
  float burn = 0.0;
  for (int i = 0; i < 4; i++) {
    float angle = float(i) * 0.785;
    float radius = 0.15 + float(i) * 0.05;
    float x = q.x * cos(angle) - q.y * sin(angle);
    float y = q.x * sin(angle) + q.y * cos(angle);
    float dist = length(vec2(x, y));
    float mark = 1.0 - smoothstep(radius, radius + 0.04, dist);
    burn += mark * (0.5 + noise(q * 10.0 + float(i)) * 0.5);
  }
  col = mix(col, vec3(0.7, 0.2, 0.0) * 0.8, burn * 0.7);

  // Final blending: preserve skin tone while adding damage
  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
