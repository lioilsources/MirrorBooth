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

// Replaced: Original noise-based tribal pattern replaced with a jagged skull stripe pattern
float skullStripes(vec2 q) {
  float s = 0.0;
  for (int i = 0; i < 6; i++) {
    float angle = float(i) * 0.8 + 1.2 * noise(q * 5.0 + float(i));
    float stripe = abs(q.y - 0.05 * float(i) - 0.02 * sin(q.x * 10.0 + angle));
    s += step(0.015, stripe) * (1.0 - step(0.03, stripe));
  }
  return s / 6.0;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 q = faceQ(uv);
  vec3 col = texture(uTexture, uv).rgb;
  float l = lum(col);

  // Base face mask: white skull makeup with glowing edges
  float face = ell(q, vec2(0.0, 0.0), vec2(0.62, 0.90));
  col = mix(col, vec3(0.95, 0.94, 0.9) * (0.5 + 0.6 * l), face * 0.9);

  // Add jagged skull stripes across forehead and cheeks
  float stripes = skullStripes(q);
  col = mix(col, vec3(0.02, 0.02, 0.02), stripes * face * 0.7);

  // Eyes: black hollows with white highlights
  float eyes = max(ell(q, vec2(-0.30, -0.15), vec2(0.17, 0.15)), ell(q, vec2(0.30, -0.15), vec2(0.17, 0.15)));
  col = mix(col, vec3(0.02), eyes * face * 0.8);

  // Nose: dark accent
  float nose = ell(q, vec2(0.0, 0.10), vec2(0.07, 0.10));
  col = mix(col, vec3(0.02), nose * face * 0.6);

  // Joker smile: red jagged teeth with white gaps
  float teeth = step(abs(q.x), 0.24) * (1.0 - smoothstep(0.08, 0.10, abs(q.y - 0.38)));
  float gaps = (1.0 - smoothstep(0.004, 0.008, (0.5 - abs(fract(q.x * 12.0) - 0.5)) / 12.0)) * teeth;
  float lip = (1.0 - smoothstep(0.005, 0.012, abs(q.y - 0.38))) * step(abs(q.x), 0.26);
  col = mix(col, vec3(0.8, 0.0, 0.0), max(lip, gaps) * face * 0.9);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
