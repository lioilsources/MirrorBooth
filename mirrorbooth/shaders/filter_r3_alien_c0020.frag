#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
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
  float l = lum(col);

  // Apply alien skin: green or grey based on face center and scale
  float face = ell(q, vec2(0.0, -0.05), vec2(0.66, 0.95));
  vec3 alienSkin = mix(vec3(0.35, 0.85, 0.35), vec3(0.4, 0.45, 0.5), 0.5 + 0.2 * sin(uTime * 0.7));
  col = mix(col, alienSkin, face * 0.7);

  // Elongated skull: stretch the face vertically and horizontally
  q.x *= 1.3;
  q.y *= 1.5;

  // Huge black almond eyes: centered on face, wider and taller
  float eyeLeft = ell(q, vec2(-0.30, -0.15), vec2(0.35, 0.25));
  float eyeRight = ell(q, vec2(0.30, -0.15), vec2(0.35, 0.25));
  float eyes = max(eyeLeft, eyeRight);
  col = mix(col, vec3(0.0), eyes * 0.8);

  // Antennae: replace the original noise-based one with a wave-like spiral pattern
  float ant = 0.0;
  for (int i = 0; i < 2; i++) {
    float s = i == 0 ? -1.0 : 1.0;
    vec2 a = vec2(0.20 * s, -0.85);
    float angle = uTime * 0.8 + 1.5 * s;
    vec2 b = a + 0.2 * vec2(cos(angle), sin(angle));
    float t = clamp(dot(q - a, b - a) / dot(b - a, b - a), 0.0, 1.0);
    ant = max(ant, 1.0 - smoothstep(0.01, 0.02, length(q - a - (b - a) * t)));
  }
  col = mix(col, vec3(0.35, 0.85, 0.35), ant * 0.6);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
