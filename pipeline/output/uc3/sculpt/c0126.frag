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

  // Subtly slimmer cheeks: compress horizontally around cheeks
  float cheekMask = 1.0 - smoothstep(0.35, 0.45, abs(q.x));
  float cheekScale = 1.0 - 0.15 * cheekMask;
  vec2 adjustedQ = q;
  adjustedQ.x *= cheekScale;

  // Smaller nose: reduce nose width and slightly lift
  float nose = ell(q, vec2(0.0, 0.05), vec2(0.06, 0.04));
  col = mix(col, vec3(0.85, 0.45, 0.55), nose * 0.3);

  // Bigger eyes: expand eye area with subtle glow
  float side = q.x < 0.0 ? -1.0 : 1.0;
  vec2 eyeCenter = vec2(0.30 * side, -0.15);
  vec2 d = q - eyeCenter;
  float eye = 1.0 - smoothstep(0.8, 1.0, length(d / vec2(0.12, 0.07)));
  float eyeGlow = smoothstep(0.7, 0.8, length(d / vec2(0.12, 0.07)));
  col = mix(col, vec3(0.95, 0.90, 0.75), eye * 0.4 * eyeGlow);

  // Fuller lips: expand mouth region vertically
  float lip = 1.0 - smoothstep(0.30, 0.40, q.y - 0.35);
  float lipBase = 1.0 - smoothstep(0.01, 0.02, abs(q.y - 0.35));
  col = mix(col, vec3(0.90, 0.30, 0.40), lip * 0.5 * lipBase);

  // Transfer: add subtle soft glow from the other filter's eye enhancement
  float slit = 1.0 - smoothstep(0.012, 0.022, abs(d.x));
  col = mix(col, mix(vec3(0.75, 0.70, 0.10), vec3(0.02), slit), eye * 0.9);

  // Apply adjusted coordinates for a natural, soft transformation
  vec2 src = adjustedQ;
  src.x /= uResolution.x / uResolution.y;
  vec3 finalCol = texture(uTexture, clamp(uFaceCenter + src * uFaceScale, 0.0, 1.0)).rgb;

  fragColor = vec4(clamp(finalCol, 0.0, 1.0), 1.0);
}
