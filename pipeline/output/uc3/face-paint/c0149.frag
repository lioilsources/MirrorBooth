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

  // Apply Shader B's base structure: Gaussian window + bilateral smoothing
  float aspect = uResolution.x / uResolution.y;
  float dx = uv.x - uFaceCenter.x;
  float dy = uv.y - uFaceCenter.y;
  float gy = exp(-(dy * dy) / (2.0 * uFaceScale * uFaceScale));
  float gx = exp(-(dx * dx * aspect * aspect) / (uFaceScale * uFaceScale));
  float srcX = uFaceCenter.x + dx * (1.0 + 0.18 * gy * gx);
  vec2 wUV = clamp(vec2(srcX, uv.y), 0.0, 1.0);

  vec2 px = 1.5 / uResolution;
  vec3 center = texture(uTexture, wUV).rgb;
  vec3 accum = vec3(0.0);
  float wTotal = 0.0;
  for (int i = -1; i <= 1; i++) {
    for (int j = -1; j <= 1; j++) {
      vec3 s = texture(uTexture, clamp(wUV + vec2(float(i), float(j)) * px, 0.0, 1.0)).rgb;
      float d = length(s - center);
      float w = exp(-d * d * 12.0);
      accum += s * w;
      wTotal += w;
    }
  }
  vec3 col = mix(center, accum / wTotal, 0.5);

  // Apply Shader A's joker smile and eye details on top of Shader B's smoothed base
  float face = ell(q, vec2(0.0, 0.05), vec2(0.62, 0.88));
  col = mix(col, vec3(0.92) * (0.55 + 0.5 * lum(col)), face * 0.85);

  // Joker smile
  float smile = (1.0 - smoothstep(0.03, 0.06, abs(q.y - (0.36 - 0.55 * q.x * q.x)))) * step(abs(q.x), 0.48);
  col = mix(col, vec3(0.75, 0.02, 0.05) * (0.6 + lum(col)), smile * face);

  // Eyes: darkened with a bit of shadow
  float eyes = max(ell(q, vec2(-0.30, -0.15), vec2(0.14, 0.20)), ell(q, vec2(0.30, -0.15), vec2(0.14, 0.20)));
  col = mix(col, vec3(0.05, 0.08, 0.12) + col * 0.2, eyes * 0.8);

  // Now apply Shader B's tribal stripes and white skull details on top
  float stripes = abs(noise(q * 8.0 + 2.0 * uFaceScale) - 0.5) * 2.0;
  stripes = smoothstep(0.4, 0.6, stripes);
  col = mix(col, vec3(0.1, 0.1, 0.1), stripes * face * 0.6);

  // White skull makeup: emphasize nose and eye sockets
  float sock = max(ell(q, vec2(-0.30, -0.15), vec2(0.17, 0.15)), ell(q, vec2(0.30, -0.15), vec2(0.17, 0.15)));
  float nose = ell(q, vec2(0.0, 0.10), vec2(0.07, 0.10));
  col = mix(col, vec3(0.02), max(sock, nose) * face);

  // Teeth: subtle highlight
  float teeth = step(abs(q.x), 0.24) * (1.0 - smoothstep(0.08, 0.10, abs(q.y - 0.38)));
  float gaps = (1.0 - smoothstep(0.004, 0.008, (0.5 - abs(fract(q.x * 12.0) - 0.5)) / 12.0)) * teeth;
  float lip = (1.0 - smoothstep(0.005, 0.012, abs(q.y - 0.38))) * step(abs(q.x), 0.26);
  col = mix(col, vec3(0.03), max(lip, gaps) * face);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
