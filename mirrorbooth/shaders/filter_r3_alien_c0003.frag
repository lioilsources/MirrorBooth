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
  vec2 uv = FlutterFragCoord().xy / uResolution; vec2 q = faceQ(uv);
  vec3 col = texture(uTexture, uv).rgb; float l = lum(col);
  float face = ell(q, vec2(0.0, 0.0), vec2(0.65, 0.92));
  
  // Alien skin: green or grey
  vec3 alienSkin = mix(vec3(0.45, 0.75, 0.40), vec3(0.4, 0.4, 0.5), 0.5);
  col = mix(col, alienSkin * (0.35 + l), face * 0.75);

  // Elongated skull: stretch face vertically
  float skullStretch = smoothstep(0.0, 1.0, abs(q.y) / 0.7);
  q.y *= 1.4 + 0.6 * skullStretch;

  // Antennae: add two thin vertical lines above the head
  vec2 ant1 = vec2(0.0, 0.95); vec2 ant2 = vec2(0.0, 0.95);
  float ant1Dist = length(q - ant1); float ant2Dist = length(q - ant2);
  float antenna = (1.0 - smoothstep(0.005, 0.015, ant1Dist)) * 0.8;
  antenna += (1.0 - smoothstep(0.005, 0.015, ant2Dist)) * 0.8;
  col = mix(col, vec3(0.0), antenna);

  // Huge black almond eyes with pupil effect
  float side = q.x < 0.0 ? -1.0 : 1.0;
  vec2 eyePos = vec2(0.30 * side, -0.15);
  vec2 d = q - eyePos;
  float ang = 0.45 * side;
  d = vec2(d.x * cos(ang) - d.y * sin(ang), d.x * sin(ang) + d.y * cos(ang));
  float eye = 1.0 - smoothstep(0.85, 1.0, length(d / vec2(0.22, 0.11)));
  col = mix(col, vec3(0.01, 0.02, 0.02), eye);
  col += eye * exp(-dot(d - vec2(-0.05, -0.03), d - vec2(-0.05, -0.03)) * 900.0) * 0.8;

  // Transfer: scar effect from other filter — now used as a glowing forehead scar
  vec2 a = vec2(0.15, -0.05); vec2 b = vec2(0.55, 0.35);
  vec2 ab = b - a; float t = clamp(dot(q - a, ab) / dot(ab, ab), 0.0, 1.0);
  vec2 p = a + ab * t; float dist = length(q - p);
  float wob = 0.008 * sin(t * 40.0);
  float scar = 1.0 - smoothstep(0.010, 0.022, abs(dist + wob));
  float rim = (1.0 - smoothstep(0.02, 0.06, dist)) * (1.0 - scar);
  col = mix(col, col * vec3(1.15, 0.75, 0.75), rim * 0.6);
  col = mix(col, vec3(0.55, 0.15, 0.15), scar * 0.8);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
