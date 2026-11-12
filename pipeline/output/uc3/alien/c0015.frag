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
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 q = faceQ(uv);
  vec3 col = texture(uTexture, uv).rgb;
  float l = lum(col);

  // Distort face: elongate skull and scale features
  q.y *= 1.4;
  q.x *= 1.1;
  float face = ell(q, vec2(0.0, -0.05), vec2(0.66, 1.15));

  // Apply alien skin: green or grey, with subtle noise
  vec3 alienSkin = mix(vec3(0.2, 0.4, 0.15), vec3(0.5, 0.5, 0.6), 0.5 + 0.5 * noise(q * 10.0));
  col = mix(col, alienSkin, face * 0.8);

  // Huge black almond eyes
  vec2 eyeOffset = vec2(0.32, -0.25);
  float leftEye = ell(q + eyeOffset, vec2(0.0), vec2(0.2, 0.3));
  float rightEye = ell(q - eyeOffset, vec2(0.0), vec2(0.2, 0.3));
  col = mix(col, vec3(0.0), (leftEye + rightEye) * 0.9);

  // Antennae: longer, wobbly, more visible
  float ant = 0.0;
  for (int i = 0; i < 2; i++) {
    float s = i == 0 ? -1.0 : 1.0;
    vec2 a = vec2(0.22 * s, -0.80); 
    vec2 b = vec2(0.48 * s + 0.05 * sin(uTime * 3.0 + float(i)), -1.60);
    vec2 ab = b - a;
    float t = clamp(dot(q - a, ab) / dot(ab, ab), 0.0, 1.0);
    ant = max(ant, 1.0 - smoothstep(0.01, 0.025, length(q - a - ab * t)));
    ant = max(ant, 1.0 - smoothstep(0.04, 0.06, length(q - b)));
  }
  col = mix(col, vec3(0.3, 0.8, 0.3), ant * 0.7);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
