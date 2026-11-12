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
  vec2 c = vec2(q.x < 0.0 ? -0.30 : 0.30, -0.15);
  vec2 d = q - c; float r = length(d / vec2(0.16, 0.10));
  float w = exp(-r * r * 2.0);
  vec2 src = uFaceCenter + (c + d * (1.0 - 0.12 * w)) * uFaceScale / vec2(uResolution.x / uResolution.y, 1.0);
  vec3 col = texture(uTexture, clamp(src, 0.0, 1.0)).rgb;
  vec2 s = d - vec2(0.03, -0.02);
  float star = exp(-abs(s.x) * 90.0) * exp(-abs(s.y) * 18.0) + exp(-abs(s.y) * 90.0) * exp(-abs(s.x) * 18.0);
  col += vec3(1.0, 0.97, 0.9) * star * 0.8 * w;

  // Apply shader A's eye enhancement: brighter, larger eyes with vivid color
  float eyeMask = 1.0 - smoothstep(0.15, 0.22, r);
  col *= (1.0 + eyeMask * 0.6); // Brighten eyes
  col = mix(col, vec3(0.9, 0.4, 1.0), eyeMask * 0.4); // Add vivid color tint

  // Apply shader B's hair tinting logic to subtly enhance eye color via context
  float head = ell(q, vec2(0.0, -0.35), vec2(0.95, 0.85));
  float hair = head * max(smoothstep(-0.45, -0.70, q.y), smoothstep(0.50, 0.70, abs(q.x)));
  float l = lum(col);
  vec3 tint = mix(vec3(0.9, 0.3, 0.7), vec3(0.3, 0.6, 1.0), smoothstep(-1.2, -0.4, q.y)) * (0.35 + l);
  col = mix(col, tint, hair * 0.65);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
