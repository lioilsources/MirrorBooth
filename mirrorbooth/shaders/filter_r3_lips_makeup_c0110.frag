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

  // Glossy red lipstick on mouth
  float mouth = ell(q, vec2(0.0, 0.35), vec2(0.30, 0.18));
  vec3 lipColor = vec3(0.8, 0.05, 0.1); // Deep red
  col = mix(col, lipColor, mouth * 0.8);
  
  // Add glossy highlight to lips
  float lipGloss = ell(q, vec2(0.0, 0.35), vec2(0.15, 0.08)) * (1.0 - smoothstep(0.0, 0.05, abs(q.y - 0.35)));
  col = mix(col, vec3(1.0, 0.7, 0.7), lipGloss * 0.6);

  // Rosy blush on cheeks
  float cheek = ell(q, vec2(-0.35, 0.05), vec2(0.25, 0.20)) + ell(q, vec2(0.35, 0.05), vec2(0.25, 0.20));
  col = mix(col, vec3(1.0, 0.5, 0.6), cheek * 0.4);

  // Dark eyeliner and eyeshadow
  float eyeLid = ell(q, vec2(-0.30, -0.15), vec2(0.15, 0.06)) * smoothstep(-0.10, -0.25, q.y);
  col = mix(col, vec3(0.05, 0.05, 0.05), eyeLid * 0.7);

  // Eyeshadow (deeper dark)
  float eyeShadow = ell(q, vec2(-0.30, -0.15), vec2(0.25, 0.15)) * (1.0 - smoothstep(0.0, 0.03, abs(q.y + 0.15)));
  col = mix(col, vec3(0.1, 0.1, 0.2), eyeShadow * 0.6);

  // Transfer: Red eye band from other filter (weighted by darkness) — adds subtle red glow around eyes
  vec2 e = vec2(uFaceCenter.x, uFaceCenter.y - 0.35 * uFaceScale);
  vec2 k = uv - e;
  k.x *= uResolution.x / uResolution.y * 0.6;
  float sigma = 0.32 * uFaceScale;
  float w = exp(-dot(k, k) / (sigma * sigma));
  float dark = 0.35 + 0.65 * smoothstep(0.55, 0.15, lum(col));
  col = mix(col, vec3(0.60, 0.05, 0.08), 0.9 * w * dark);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
