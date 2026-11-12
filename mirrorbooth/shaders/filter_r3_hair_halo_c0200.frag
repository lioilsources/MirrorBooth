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
float noise(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y); }
float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 q = faceQ(uv);
  vec3 col = texture(uTexture, uv).rgb;

  // Transfer: Add subtle colored line along upper eyelid using face center and scale
  float side = q.x < 0.0 ? -1.0 : 1.0;
  vec2 c = vec2(0.30 * side, -0.20);
  float lid = ell(q, c, vec2(0.17, 0.08)) * smoothstep(-0.10, -0.20, q.y);
  col = mix(col, col * vec3(0.55, 0.35, 0.85), lid * 0.7);
  float liner = (1.0 - smoothstep(0.006, 0.014, abs(q.y - (-0.10 - 1.2 * (q.x - c.x) * (q.x - c.x)))))
                * ell(q, c + vec2(0.03 * side, 0.0), vec2(0.20, 0.10));
  col = mix(col, vec3(0.03), liner * 0.85);

  // Replace ring with a pulsing golden glow above head using face scale and center
  vec2 centerOffset = vec2(0.0, -1.05);
  vec2 scaledOffset = centerOffset * uFaceScale;
  vec2 d = (q - scaledOffset) / vec2(0.55, 0.12);
  float ring = exp(-(length(d) - 1.0) * (length(d) - 1.0) * 60.0);
  float pulse = 0.8 + 0.2 * sin(uTime * 3.0 + q.x * 12.0);
  col += vec3(1.0, 0.85, 0.4) * ring * pulse;

  // Replace halo with a dynamic crown-like color wave using face scale and center
  float crownRadius = 0.75;
  float crownEdge = 0.06;
  float crownDist = length(q - vec2(0.0, -0.90));
  float crown = smoothstep(crownRadius - crownEdge, crownRadius + crownEdge, crownDist);
  crown *= 0.8 + 0.2 * sin(uTime * 2.5 + q.x * 10.0);
  float wave = (0.7 + 0.3 * sin(uv.x * 5.0 + uFaceCenter.x * 2.0)) * crown * (0.5 + 0.5 * noise(q * 5.0 + uFaceCenter * 0.5));
  vec3 crownColor = vec3(1.0, 0.8, 0.4) * (1.0 + 0.5 * sin(wave * 10.0 + uFaceCenter.y * 3.0));
  col = mix(col, crownColor, wave * 0.8);

  // Replace hair tint with a colorful wave above the head using face scale and center
  float hairWave = smoothstep(0.0, 0.1, q.y - 0.45) * (1.0 - ell(q, vec2(0.0, -0.35), vec2(0.95, 0.85))) * (0.5 + 0.5 * noise(q * 10.0));
  vec3 hairTint = vec3(0.8, 0.3, 1.0) * (0.5 + 0.5 * sin(q.x * 6.0 + uFaceCenter.x * 4.0));
  col = mix(col, hairTint, hairWave * 0.6);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
