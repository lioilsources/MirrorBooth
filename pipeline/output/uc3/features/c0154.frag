#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

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

  // Enlarge the nose region: shift pixels toward center of face, exaggerating the nose
  float noseMask = ell(q, vec2(0.0, 0.05), vec2(0.35, 0.7));
  vec2 noseOffset = (q - vec2(0.0, 0.05)) * 0.8 * noseMask;
  vec2 warpedNose = uv + noseOffset * (1.0 + uFaceScale * 0.5);

  // Sample the texture at warped position for exaggerated nose
  vec3 noseColor = texture(uTexture, warpedNose).rgb;

  // Enhance mouth area: stretch vertically
  float mouthMask = ell(q, vec2(0.0, 0.35), vec2(0.45, 0.3));
  vec2 mouthOffset = vec2(0.0, (q.y - 0.35) * 2.0) * mouthMask * (1.0 + uFaceScale * 0.4);
  vec2 warpedMouth = uv + mouthOffset;

  vec3 mouthColor = texture(uTexture, warpedMouth).rgb;

  // Combine effects: use noseColor for nose, mouthColor for mouth, original elsewhere
  vec3 final = mix(col, noseColor, noseMask * 0.6);
  final = mix(final, mouthColor, mouthMask * 0.6);

  // Add subtle glow and contrast boost on face
  vec3 b = vec3(0.0);
  for (int i = 0; i < 8; i++) {
    float a = float(i) * 0.785398;
    b += texture(uTexture, uv + vec2(cos(a), sin(a)) * 0.012).rgb;
  }
  b /= 8.0;
  float face = ell(q, vec2(0.0, 0.05), vec2(0.65, 0.90));
  vec3 glow = max(b - 0.45, 0.0) * 1.6;
  final = mix(final, final + glow * vec3(1.0, 0.85, 0.7), face * 0.5);

  fragColor = vec4(clamp(final, 0.0, 1.0), 1.0);
}
