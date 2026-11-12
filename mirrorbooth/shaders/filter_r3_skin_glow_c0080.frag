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

// Replaced: Original bilateral filter replaced with a glow + skin smoothing + freckle layer
void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 q = faceQ(uv);
  vec3 c0 = texture(uTexture, uv).rgb;

  // Soft glow effect using radial blur and luminance-based intensity
  vec3 glow = vec3(0.0);
  float glowRadius = 0.01 * uFaceScale;
  for (int i = 0; i < 8; i++) {
    float a = float(i) * 3.14159265 / 4.0;
    vec2 offset = vec2(cos(a), sin(a)) * glowRadius;
    glow += texture(uTexture, uv + offset).rgb * (0.125 + 0.125 * sin(float(i) * 0.5));
  }
  glow /= 8.0;

  // Smooth skin using median filter with face-aware weighting
  vec2 px = 2.0 / uResolution;
  vec3 acc = vec3(0.0);
  float wsum = 0.0;
  for (int i = -1; i <= 1; i++) {
    for (int j = -1; j <= 1; j++) {
      vec3 s = texture(uTexture, uv + vec2(float(i), float(j)) * px).rgb;
      float w = exp(-dot(s - c0, s - c0) * 20.0);
      acc += s * w;
      wsum += w;
    }
  }
  vec3 smoothed = acc / wsum;

  // Apply face mask: stronger effect on central face, softer on edges
  float faceMask = ell(q, vec2(0.0, 0.05), vec2(0.7, 1.0)) * (1.0 - ell(q, vec2(0.0, 0.35), vec2(0.25, 0.12)));
  vec3 finalColor = mix(c0, smoothed, faceMask * 0.7);
  finalColor = mix(finalColor, finalColor * vec3(1.06, 1.03, 1.0), faceMask * 0.4); // Subtle warmth

  // Add light freckles using noise, only on face
  float freckleNoise = noise(q * 15.0 + uFaceCenter * 0.5);
  float freckleMask = step(0.92, freckleNoise) * faceMask * 0.05;
  finalColor += vec3(freckleMask * 0.15, freckleMask * 0.05, freckleMask * 0.02);

  // Add glow only on face, intensity based on luminance
  vec3 glowColor = vec3(1.0, 0.9, 0.8) * (0.5 + 0.5 * lum(c0)) * faceMask * 0.2;
  finalColor += glowColor;

  fragColor = vec4(clamp(finalColor, 0.0, 1.0), 1.0);
}
