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

  // Replace the original blur with a Gaussian blur using a more controlled, softer approach
  vec3 b = vec3(0.0);
  for (int i = -2; i <= 2; i++) {
    float w = 0.25 - 0.125 * float(i * i);
    b += texture(uTexture, uv + vec2(0.0, float(i) * 0.008)).rgb * w;
  }
  b *= 1.0 / (0.25 * 5.0 - 0.125 * 5.0); // normalize

  float face = ell(q, vec2(0.0, 0.05), vec2(0.65, 0.90));
  vec3 glow = max(b - 0.4, 0.0) * 1.8;
  col = mix(col, col + glow * vec3(1.1, 0.9, 0.8), face * 0.8);
  
  // Add subtle, soft freckles using noise with low frequency and amplitude
  float freckle = noise(q * 10.0 + uFaceCenter * 0.1) * 0.03;
  col += vec3(freckle, freckle * 0.8, freckle * 0.6);

  // Soften skin tone with a gentle tone adjustment only on the face
  col = mix(col, vec3(0.98, 0.92, 0.88), face * 0.3);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
