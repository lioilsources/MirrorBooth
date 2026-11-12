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
  vec2 uv = FlutterFragCoord().xy / uResolution; vec2 q = faceQ(uv);
  vec3 col = texture(uTexture, uv).rgb; float l = lum(col);
  float face = ell(q, vec2(0.0, -0.05), vec2(0.66, 0.95));
  // Apply alien skin: green or grey base with enhanced face mask
  col = mix(col, vec3(0.25, 0.55, 0.35) * (0.3 + l), face * 0.7);
  
  // Elongated skull: stretch the face vertically and horizontally
  q.y *= 1.4;
  q.x *= 1.2;
  vec2 q2 = faceQ(uv); // Re-calculate for accurate eye placement

  // Huge black almond eyes — inherited from other filter's dot pattern but adapted
  float eyeL = ell(q2, vec2(-0.30, -0.15), vec2(0.25, 0.45));
  float eyeR = ell(q2, vec2(0.30, -0.15), vec2(0.25, 0.45));
  float eyeMask = max(eyeL, eyeR);
  col = mix(col, vec3(0.0), eyeMask * 1.0);

  // Antennae: from parent — two thin lines with wobble
  float ant = 0.0;
  for (int i = 0; i < 2; i++) {
    float s = i == 0 ? -1.0 : 1.0;
    vec2 a = vec2(0.20 * s, -0.85); vec2 b = vec2(0.45 * s + 0.03 * sin(uTime * 2.0), -1.45);
    vec2 ab = b - a; float t = clamp(dot(q - a, ab) / dot(ab, ab), 0.0, 1.0);
    ant = max(ant, 1.0 - smoothstep(0.015, 0.03, length(q - a - ab * t)));
    ant = max(ant, 1.0 - smoothstep(0.05, 0.07, length(q - b)));
  }
  col = mix(col, vec3(0.35, 0.85, 0.35), ant);

  // Transfer: use the other filter's "dot pattern" for subtle alien texture on face
  float zone = ell(q2, vec2(0.0, 0.10), vec2(0.55, 0.22)) * (1.0 - ell(q2, vec2(0.0, 0.35), vec2(0.20, 0.08)));
  vec2 g = q2 * 55.0; vec2 id = floor(g); vec2 f = fract(g) - 0.5;
  float h = hash(id);
  float dot1 = (1.0 - smoothstep(0.10, 0.25, length(f - (vec2(hash(id + 3.1), hash(id + 7.7)) - 0.5) * 0.4))) * step(0.72, h);
  col = mix(col, col * vec3(0.62, 0.42, 0.30), dot1 * zone * 0.7);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
