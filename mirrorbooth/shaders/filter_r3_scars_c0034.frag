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

// Transfer: Add the glow effect from the other filter — subtle ambient glow around the face
vec3 getGlow(vec2 uv, vec2 q) {
    vec3 b = vec3(0.0);
    for (int i = 0; i < 8; i++) {
        float a = float(i) * 0.785398;
        b += texture(uTexture, uv + vec2(cos(a), sin(a)) * 0.012).rgb;
    }
    b /= 8.0;
    float face = ell(q, vec2(0.0, 0.05), vec2(0.65, 0.90));
    vec3 glow = max(b - 0.45, 0.0) * 1.6;
    return mix(b, b + glow * vec3(1.0, 0.85, 0.7), face);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 q = faceQ(uv);

  // Apply glow effect from the other filter (transferred)
  vec3 col = texture(uTexture, uv).rgb;
  vec3 glow = getGlow(uv, q);
  col = mix(col, col + glow * vec3(1.0, 0.85, 0.7), ell(q, vec2(0.0, 0.05), vec2(0.65, 0.90)) * 0.3);

  // Define scar path: from near left eye to lower mouth
  vec2 a = vec2(0.15, -0.05); 
  vec2 b = vec2(0.55, 0.35);
  vec2 ab = b - a; 
  float t = clamp(dot(q - a, ab) / dot(ab, ab), 0.0, 1.0);
  vec2 p = a + ab * t; 
  float dist = length(q - p);
  float wob = 0.008 * sin(t * 40.0);
  float scar = 1.0 - smoothstep(0.010, 0.022, abs(dist + wob));
  float rim = (1.0 - smoothstep(0.02, 0.06, dist)) * (1.0 - scar);
  col = mix(col, col * vec3(1.15, 0.75, 0.75), rim * 0.6);
  col = mix(col, vec3(0.55, 0.15, 0.15), scar * 0.8);

  // Stitching effect: small white dots along the scar
  vec2 n = normalize(vec2(-ab.y, ab.x));
  float st = step(abs(fract(t * 9.0) - 0.5), 0.06) * (1.0 - smoothstep(0.0, 0.05, abs(dot(q - p, n)))) * step(0.03, t) * step(t, 0.97);
  col = mix(col, vec3(0.08, 0.05, 0.05), st);

  // Add bruise: dark purple swelling around the nose and cheek
  float bruise = ell(q, vec2(0.0, 0.1), vec2(0.12, 0.08));
  col = mix(col, vec3(0.3, 0.05, 0.35), bruise * 0.4);

  // Add burn mark: irregular red patch near the jawline
  float burn = 1.0 - smoothstep(0.04, 0.07, length(q - vec2(0.3, 0.2)));
  burn *= noise(q * 8.0 + 0.5);
  col = mix(col, vec3(0.8, 0.3, 0.1), burn * 0.5);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
