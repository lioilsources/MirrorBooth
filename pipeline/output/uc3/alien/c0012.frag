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

// Modified: replaced the original eye shape with a more elongated, almond-shaped black pupil using a rotated ellipse
float almondEye(vec2 q, vec2 center, float scale, float angle) {
  vec2 rotated = vec2(q.x * cos(angle) - q.y * sin(angle), q.x * sin(angle) + q.y * cos(angle));
  vec2 offset = rotated - center;
  return 1.0 - smoothstep(0.9, 1.0, length(offset / vec2(scale * 0.4, scale * 0.2)));
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 q = faceQ(uv);
  vec3 col = texture(uTexture, uv).rgb;
  float l = lum(col);

  // Alien skin: green or grey base
  float face = ell(q, vec2(0.0, 0.0), vec2(0.65, 0.92));
  col = mix(col, vec3(0.35, 0.65, 0.45) * (0.3 + l), face * 0.8); // greenish tone

  // Elongated skull: stretch the face vertically and horizontally
  float skull = ell(q, vec2(0.0, -0.05), vec2(0.75, 1.1));
  col = mix(col, vec3(0.4, 0.45, 0.5), skull * 0.2);

  // Antennae: thin vertical lines with noise texture
  float antennae = 0.0;
  vec2 antPos = vec2(0.0, -0.35);
  vec2 antDir = normalize(vec2(0.0, 1.0));
  float antLength = 0.5;
  float antWidth = 0.015;
  float antOffset = noise(q * 10.0 + uFaceCenter * 0.5) * 0.05;
  vec2 antBase = antPos + antDir * antLength * 0.5;
  vec2 antTip = antBase + antDir * antLength;
  vec2 antDirPerp = vec2(-antDir.y, antDir.x);
  float antDist = abs(dot(uv - antBase, antDirPerp)) / antWidth;
  float antLine = 1.0 - smoothstep(0.0, 0.02, antDist);
  antennae += antLine * (1.0 - smoothstep(0.0, 0.3, length(uv - antBase))); // fade at base
  antennae += antLine * (1.0 - smoothstep(0.0, 0.3, length(uv - antTip))); // fade at tip
  col = mix(col, vec3(0.1, 0.1, 0.1), antennae * 0.6);

  // Eyes: huge black almond eyes with rotation and depth
  float side = q.x < 0.0 ? -1.0 : 1.0;
  vec2 eyeCenter = vec2(0.30 * side, -0.15);
  float eyeAngle = 0.35 * side;
  float eye = almondEye(q, eyeCenter, 0.6, eyeAngle);
  col = mix(col, vec3(0.0, 0.0, 0.0), eye * 0.9); // Black almond eyes

  // Add a small reflective highlight in the eye
  vec2 eyeRel = (q - eyeCenter) * mat2(cos(eyeAngle), -sin(eyeAngle), sin(eyeAngle), cos(eyeAngle));
  float highlight = exp(-dot(eyeRel - vec2(-0.03, 0.01), eyeRel - vec2(-0.03, 0.01)) * 1000.0) * 0.8;
  col += eye * highlight * 0.6;

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
