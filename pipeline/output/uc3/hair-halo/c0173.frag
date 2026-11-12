#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 faceQ(vec2 uv) { vec2 q = (uv - uFaceCenter) / uFaceScale; q.x *= uResolution.x / uResolution.y; return q; }
float ell(vec2 q, vec2 c, vec2 r) { return 1.0 - smoothstep(0.6, 1.0, length((q - c) / r)); }
float noise(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f); return mix(mix(fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453), fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453), f.x), mix(fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453), fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453), f.x), f.y); }
float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 q = faceQ(uv);
  vec3 col = texture(uTexture, uv).rgb;

  // Transfer: Add the eyeliner effect from the other filter (a subtle, colored line along the upper eyelid)
  float side = q.x < 0.0 ? -1.0 : 1.0;
  vec2 c = vec2(0.30 * side, -0.20);
  float lid = ell(q, c, vec2(0.17, 0.08)) * smoothstep(-0.10, -0.20, q.y);
  col = mix(col, col * vec3(0.55, 0.35, 0.85), lid * 0.7);
  float liner = (1.0 - smoothstep(0.006, 0.014, abs(q.y - (-0.10 - 1.2 * (q.x - c.x) * (q.x - c.x)))))
                * ell(q, c + vec2(0.03 * side, 0.0), vec2(0.20, 0.10));
  col = mix(col, vec3(0.03), liner * 0.85);

  // Halo effect: glowing ring above the head (from Shader A)
  vec2 d = (q - vec2(0.0, -1.05)) / vec2(0.55, 0.12);
  float ring = exp(-(length(d) - 1.0) * (length(d) - 1.0) * 60.0);
  float shimmer = 0.8 + 0.2 * sin(uTime * 3.0 + q.x * 12.0);
  col += vec3(1.0, 0.85, 0.4) * ring * shimmer;

  // Hair glow: soft colored tint above head (from Shader B)
  float hairGlow = exp(-dot(q - vec2(0.0, -0.8), q - vec2(0.0, -0.8)) * 2.0) * 0.3;
  col += vec3(0.6, 0.3, 0.9) * hairGlow * (0.5 + 0.5 * sin(uTime * 1.0 + q.y * 4.0));

  // Sparkle at center (from Shader B)
  float gem = 1.0 - smoothstep(0.03, 0.045, length(q - vec2(0.0, -0.91)));
  col = mix(col, vec3(0.8, 0.05, 0.2), gem);

  // Add golden crown tint above the head (from Shader A, enhanced with noise)
  float crown = exp(-dot(q - vec2(0.0, -0.9), q - vec2(0.0, -0.9)) * 3.0) * 0.12;
  vec3 crownColor = vec3(1.0, 0.75, 0.2) + 0.2 * vec3(
    sin(uTime * 0.5 + q.x * 2.0),
    sin(uTime * 0.7 + q.y * 1.5),
    sin(uTime * 0.3 + q.x * 1.0)
  );
  col += crownColor * crown * (0.5 + 0.5 * noise(q * 4.0 + uTime * 0.7));

  // Final output with all effects combined
  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
