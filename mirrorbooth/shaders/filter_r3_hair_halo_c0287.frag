#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 faceQ(vec2 uv) { vec2 q = (uv - uFaceCenter) / uFaceScale; q.x *= uResolution.x / uResolution.y; return q; }
float ell(vec2 q, vec2 c, vec2 r) { return 1.0 - smoothstep(0.6, 1.0, length((q - c) / r)); }
float noise(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453), fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453), f.x),
               mix(fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453), fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453), f.x), f.y); }

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 q = faceQ(uv);
  vec3 col = texture(uTexture, uv).rgb;

  // Base golden halo: use face scale and center to position a soft glowing ring above head
  vec2 centerOffset = vec2(0.0, -1.0);
  vec2 scaledOffset = centerOffset * uFaceScale;
  vec2 d = (q - scaledOffset) / vec2(0.5, 0.15);
  float ring = exp(-(length(d) - 1.0) * (length(d) - 1.0) * 50.0);
  float pulse = 0.7 + 0.3 * sin(uTime * 4.0 + q.x * 10.0);
  vec3 golden = vec3(1.0, 0.8, 0.3) * (0.6 + 0.4 * pulse);
  col = mix(col, golden, ring * 0.8);

  // Colorful wave above head: apply harmonic motion modulated by face scale and center
  float wave = smoothstep(0.0, 0.1, q.y - 0.4) * (1.0 - ell(q, vec2(0.0, -0.3), vec2(0.8, 0.9)));
  float mod = 0.5 + 0.5 * noise(q * 8.0 + uFaceCenter * 3.0);
  vec3 colorWave = vec3(
    0.7 + 0.3 * sin(q.x * 7.0 + uFaceCenter.x * 5.0 + uTime * 1.5),
    0.4 + 0.6 * cos(q.y * 8.0 + uFaceCenter.y * 4.0 + uTime * 2.0),
    0.6 + 0.4 * sin(q.x * 6.0 + uFaceCenter.x * 6.0 + uTime * 1.8)
  );
  col = mix(col, colorWave, wave * mod * 0.6);

  // Dynamic glow edge with soft falloff, using face scale to adjust size and position
  float edge = smoothstep(0.0, 0.06, length(q - vec2(0.0, -0.4)) - 0.35);
  edge *= smoothstep(0.0, 0.1, q.y + 0.2);
  vec3 glow = vec3(0.9, 0.6, 0.2) * (0.5 + 0.5 * noise(q * 6.0 + uFaceCenter * 4.0));
  col = mix(col, glow, edge * 0.5);

  // Add subtle volume enhancement with side lighting, anchored to face center
  float side = q.x < 0.0 ? -1.0 : 1.0;
  vec2 offset = vec2(0.15 * side, -0.1);
  float light = ell(q, offset, vec2(0.1, 0.05)) * smoothstep(-0.1, -0.2, q.y);
  col = mix(col, col * vec3(0.6, 0.4, 0.9), light * 0.3);

  // Final top highlight layer with pulsing intensity, using face scale to maintain relative size
  float topGlow = smoothstep(0.0, 0.08, q.y + 0.1);
  col = mix(col, vec3(1.0, 0.9, 0.6), topGlow * 0.4);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
