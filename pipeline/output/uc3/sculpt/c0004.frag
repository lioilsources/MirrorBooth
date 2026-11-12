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
  
  // Subtly slim cheeks: reduce horizontal spread around cheek areas
  float cheekMask = 1.0 - smoothstep(0.15, 0.25, abs(q.x));
  float cheekScale = 1.0 - 0.15 * cheekMask * (1.0 - exp(-2.0 * abs(q.y - 0.05))); // subtle inward pull
  
  // Smaller nose: compress vertically and slightly horizontally
  vec2 noseOffset = vec2(0.0, 0.05);
  float noseMask = 1.0 - smoothstep(0.08, 0.12, length(q - noseOffset));
  float noseScale = 1.0 - 0.1 * noseMask * (1.0 - exp(-5.0 * length(q - noseOffset)));
  
  // Bigger eyes: expand around eye positions
  float eyeOffsetX = 0.30;
  float eyeOffsetY = 0.15;
  float leftEyeMask = 1.0 - smoothstep(0.08, 0.12, length(q - vec2(-eyeOffsetX, -eyeOffsetY)));
  float rightEyeMask = 1.0 - smoothstep(0.08, 0.12, length(q - vec2(eyeOffsetX, -eyeOffsetY)));
  float eyeScale = 1.0 + 0.1 * (leftEyeMask + rightEyeMask) * (1.0 - exp(-3.0 * length(q - vec2(0.0, -eyeOffsetY))));
  
  // Fuller lips: expand around mouth
  float mouthOffsetY = 0.35;
  float mouthMask = 1.0 - smoothstep(0.08, 0.12, abs(q.y - mouthOffsetY));
  float lipScale = 1.0 + 0.12 * mouthMask * (1.0 - exp(-4.0 * abs(q.y - mouthOffsetY)));
  
  // Combined deformation: apply all adjustments to the face coordinate
  float deformFactor = cheekScale * noseScale * eyeScale * lipScale;
  vec2 src = q * deformFactor;
  src.x /= uResolution.x / uResolution.y;
  
  // Sample with corrected face center and scale
  vec3 col = texture(uTexture, clamp(uFaceCenter + src * uFaceScale, 0.0, 1.0)).rgb;
  fragColor = vec4(col, 1.0);
}
