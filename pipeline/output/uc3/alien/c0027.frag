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

// Modified: replaced original face distortion with alien skull elongation and antennae
vec2 alienDistort(vec2 q) {
  // Stretch skull vertically and slightly horizontally
  q.y *= 1.4;
  q.x *= 1.2;
  // Add subtle wave distortion for organic alien feel
  q += vec2(noise(q * 10.0) * 0.03, noise(q * 10.0 + 123.4) * 0.02);
  return q;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 q = faceQ(uv);
  vec3 col = texture(uTexture, uv).rgb;
  float l = lum(col);

  // Apply alien skull elongation and distortion
  vec2 dq = alienDistort(q);
  
  // Define alien face shape with elongated skull
  float face = ell(dq, vec2(0.0, 0.0), vec2(0.6, 1.2)); // taller, narrower face
  col = mix(col, vec3(0.3, 0.5, 0.4) * (0.4 + l), face * 0.8); // greenish skin tone

  // Eyes: huge black almond-shaped, positioned slightly higher
  float side = q.x < 0.0 ? -1.0 : 1.0;
  vec2 eyeCenter = vec2(0.25 * side, -0.20); // higher and inward
  vec2 eyeOffset = dq - eyeCenter;
  float eyeAngle = 0.3 * side;
  eyeOffset = vec2(eyeOffset.x * cos(eyeAngle) - eyeOffset.y * sin(eyeAngle),
                   eyeOffset.x * sin(eyeAngle) + eyeOffset.y * cos(eyeAngle));
  float eye = 1.0 - smoothstep(0.9, 1.0, length(eyeOffset / vec2(0.18, 0.08)));
  col = mix(col, vec3(0.0, 0.0, 0.0), eye * 0.9);

  // Add small white specular highlight in the center of the eye
  float highlight = 1.0 - smoothstep(0.01, 0.02, length(eyeOffset - vec2(-0.04, -0.01)));
  col += eye * highlight * 0.7;

  // Antennae: two thin lines from top of head
  float antennae = 1.0 - smoothstep(0.02, 0.05, abs(dq.y - 0.7));
  antennae *= 1.0 - smoothstep(0.01, 0.02, abs(dq.x - 0.0));
  col = mix(col, vec3(0.2, 0.2, 0.2), antennae * 0.5);

  // Subtle glow around the antennae and eyes
  float glow = eye * 0.3 + antennae * 0.2;
  col += vec3(0.1, 0.4, 0.2) * glow * 0.8;

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
