#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 faceQ(vec2 uv) { vec2 q = (uv - uFaceCenter) / uFaceScale; q.x *= uResolution.x / uResolution.y; return q; }
float ell(vec2 q, vec2 c, vec2 r) { return 1.0 - smoothstep(0.6, 1.0, length((q - c) / r)); }
float noise(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f); return mix(mix(fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453), fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453), f.x), mix(fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453), fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453), f.x), f.y); }
float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 q = faceQ(uv);
  vec3 col = texture(uTexture, uv).rgb;

  // Radial halo with pulsing color shift and noise
  float haloDist = length(q - vec2(0.0, -0.95));
  float halo = smoothstep(0.75, 0.85, haloDist) * (0.8 + 0.2 * sin(uTime * 2.0 + q.x * 8.0));
  vec3 haloColor = vec3(0.9, 0.6, 0.2) + 0.3 * vec3(sin(uTime * 1.5), sin(uTime * 1.2 + 2.0), sin(uTime * 1.8 + 4.0));
  col += haloColor * halo * (0.5 + 0.5 * noise(q * 5.0 + uTime * 0.5));

  // Hair glow: soft colored tint above head
  float hairGlow = exp(-dot(q - vec2(0.0, -0.8), q - vec2(0.0, -0.8)) * 2.0) * 0.3;
  col += vec3(0.6, 0.3, 0.9) * hairGlow * (0.5 + 0.5 * sin(uTime * 1.0 + q.y * 4.0));

  // Sparkle at center
  float gem = 1.0 - smoothstep(0.03, 0.045, length(q - vec2(0.0, -0.91)));
  col = mix(col, vec3(0.8, 0.05, 0.2), gem);

  // Eyeliner accent
  float side = q.x < 0.0 ? -1.0 : 1.0;
  vec2 c = vec2(0.30 * side, -0.20);
  float lid = ell(q, c, vec2(0.17, 0.08)) * smoothstep(-0.10, -0.20, q.y);
  col = mix(col, col * vec3(0.55, 0.35, 0.85), lid * 0.7);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
