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

// Replace eye lens distortion with a gentle, soft skin smoothing effect using a radial blur only on the face
vec2 skinSmooth(vec2 uv) {
    vec2 q = faceQ(uv);
    float dist = length(q);
    float strength = smoothstep(0.0, 0.3, dist) * 0.01;
    return uv + (q * strength);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  float aspect = uResolution.x / uResolution.y;
  float R = uFaceScale;

  vec2 q = faceQ(uv);
  float face = ell(q, vec2(0.0, 0.05), vec2(0.65, 0.90));

  // Apply soft skin smoothing only on the face region
  vec2 wUV = skinSmooth(uv);

  // Sample the original and smoothed texture
  vec3 col = texture(uTexture, wUV).rgb;
  vec3 orig = texture(uTexture, uv).rgb;

  // Replace the Gaussian blur with a single high-quality bilateral blur (approximated with a small kernel)
  vec3 b = vec3(0.0);
  for (int i = -1; i <= 1; i++) {
    float w = 0.5 - 0.25 * float(i * i);
    b += texture(uTexture, uv + vec2(0.0, float(i) * 0.006)).rgb * w;
  }
  b *= 1.0 / (0.5 * 3.0 - 0.25 * 3.0);

  // Glow effect: subtle, warm, skin-enhancing glow based on face mask
  vec3 glow = max(b - 0.35, 0.0) * 2.0;
  col = mix(col, col + glow * vec3(1.15, 0.95, 0.85), face * 0.7);

  // Add soft, natural freckles using low-frequency noise
  float freckle = noise(q * 8.0 + uFaceCenter * 0.05) * 0.025;
  col += vec3(freckle, freckle * 0.7, freckle * 0.5);

  // Soften and brighten skin tone only where face is detected
  col = mix(col, vec3(0.97, 0.91, 0.87), face * 0.35);

  // Final touch: a gentle tone curve to enhance luminance and give a soft glow
  col = pow(clamp(col, 0.0, 1.0), vec3(0.96));

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
