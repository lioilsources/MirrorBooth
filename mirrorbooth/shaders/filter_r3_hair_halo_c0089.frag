#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 faceQ(vec2 uv) { vec2 q = (uv - uFaceCenter) / uFaceScale; q.x *= uResolution.x / uResolution.y; return q; }
float ell(vec2 q, vec2 c, vec2 r) { return 1.0 - smoothstep(0.6, 1.0, length((q - c) / r)); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f); return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y); }
float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 q = faceQ(uv);
  vec3 col = texture(uTexture, uv).rgb;

  // Transfer: Add subtle colored eyeliner along upper eyelid (from Shader B)
  float side = q.x < 0.0 ? -1.0 : 1.0;
  vec2 c = vec2(0.30 * side, -0.20);
  float lid = ell(q, c, vec2(0.17, 0.08)) * smoothstep(-0.10, -0.20, q.y);
  col = mix(col, col * vec3(0.55, 0.35, 0.85), lid * 0.7);
  float liner = (1.0 - smoothstep(0.006, 0.014, abs(q.y - (-0.10 - 1.2 * (q.x - c.x) * (q.x - c.x))))) * ell(q, c + vec2(0.03 * side, 0.0), vec2(0.20, 0.10));
  col = mix(col, vec3(0.03), liner * 0.85);

  // Main effect: Glowing halo above head (from Shader A, enhanced with pulsing and noise)
  float head = ell(q, vec2(0.0, -0.35), vec2(0.95, 0.85));
  float halo = smoothstep(0.0, 0.15, q.y - 0.65) * (1.0 - smoothstep(0.0, 0.25, abs(q.x))) * (1.0 - head);
  float glow = (0.7 + 0.3 * sin(uv.x * 5.0 + uFaceCenter.x * 2.0)) * halo * (0.5 + 0.5 * noise(q * 5.0 + uFaceCenter * 0.5));
  vec3 haloColor = vec3(1.0, 0.8, 0.4) * (1.0 + 0.5 * sin(glow * 10.0 + uFaceCenter.y * 3.0));
  col = mix(col, haloColor, glow * 0.8);

  // Colorful hair tint above head (from Shader A, modified with time-based animation)
  float hairTint = smoothstep(0.0, 0.1, q.y - 0.45) * (1.0 - head) * (0.5 + 0.5 * noise(q * 10.0));
  vec3 hairColor = vec3(0.8, 0.3, 1.0) * (0.5 + 0.5 * sin(q.x * 6.0 + uFaceCenter.x * 4.0 + uTime * 0.8));
  col = mix(col, hairColor, hairTint * 0.6);

  // Add golden crown glow (from Shader B) with dynamic color shifts
  vec2 d = (q - vec2(0.0, -1.05)) / vec2(0.55, 0.12);
  float ring = exp(-(length(d) - 1.0) * (length(d) - 1.0) * 60.0);
  float shimmer = 0.8 + 0.2 * sin(uTime * 3.0 + q.x * 12.0);
  col += vec3(1.0, 0.85, 0.4) * ring * shimmer;

  // Enhanced crown tint with multi-hue wave
  float crown = exp(-dot(q - vec2(0.0, -0.9), q - vec2(0.0, -0.9)) * 3.0) * 0.12;
  vec3 crownColor = vec3(1.0, 0.75, 0.2) + 0.2 * vec3(
    sin(uTime * 0.5 + q.x * 2.0),
    sin(uTime * 0.7 + q.y * 1.5),
    sin(uTime * 0.3 + q.x * 1.0)
  );
  col += crownColor * crown;

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
