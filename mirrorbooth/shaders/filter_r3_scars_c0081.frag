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

  // Apply subtle warping from the other filter to enhance the scar's depth and realism
  float aspect = uResolution.x / uResolution.y;
  vec2 d = uv - uFaceCenter;
  d.x *= aspect;
  float r = length(d);
  float R = uFaceScale;
  vec2 wUV = uv;
  if (r < R && r > 0.0) {
    vec2 dn = d * pow(r / R, 0.55);
    dn = mix(dn, d, smoothstep(0.8 * R, R, r));
    dn.x /= aspect;
    wUV = clamp(uFaceCenter + dn, 0.0, 1.0);
  }

  vec3 col = texture(uTexture, wUV).rgb;

  // Add stitched scar: vertical line with texture noise and red-blue tint
  float scar = abs(q.x) < 0.02 ? 1.0 - smoothstep(0.0, 0.04, abs(q.y - 0.05)) : 0.0;
  float scarNoise = noise(q * 20.0 + vec2(0.0, uFaceScale * 2.0)) * 0.3;
  float scarCore = smoothstep(0.9, 1.0, scar + scarNoise);
  col = mix(col, vec3(0.7, 0.0, 0.1), scarCore * 0.8);

  // Add bruises: dark purple patches around eyes and cheek
  float bruiseLeft = length(q - vec2(-0.35, 0.05)) < 0.15 ? 1.0 : 0.0;
  float bruiseRight = length(q - vec2(0.35, 0.05)) < 0.15 ? 1.0 : 0.0;
  float bruiseNoise = noise(q * 15.0 + vec2(1.0, 2.0)) * 0.5;
  float bruise = (bruiseLeft + bruiseRight) * (1.0 - smoothstep(0.1, 0.2, bruiseNoise));
  col = mix(col, vec3(0.4, 0.0, 0.5), bruise * 0.6);

  // Add burn marks: jagged, red-orange texture near mouth
  float burn = length(q - vec2(0.0, 0.35)) < 0.1 ? 1.0 : 0.0;
  float burnNoise = noise(q * 30.0 + vec2(5.0, 10.0)) * 0.7;
  float burnCore = smoothstep(0.8, 1.0, burn + burnNoise);
  col = mix(col, vec3(1.0, 0.5, 0.0), burnCore * 0.7);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
