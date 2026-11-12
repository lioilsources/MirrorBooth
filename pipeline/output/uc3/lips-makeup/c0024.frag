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
  vec2 uv = FlutterFragCoord().xy / uResolution; vec2 q = faceQ(uv);
  vec3 col = texture(uTexture, uv).rgb;
  
  // Replace: original lips + blush + eyeliner logic with enhanced glossy red lips, rosy blush, and dark eyeliner/eyeshadow
  float lips = ell(q, vec2(0.0, 0.35), vec2(0.24, 0.10));
  float gloss = pow(smoothstep(0.0, 0.2, lips), 2.0) * (1.0 - smoothstep(0.0, 0.1, abs(q.y - 0.35))) * 0.8;
  vec3 redLip = vec3(0.9, 0.1, 0.1);
  col = mix(col, redLip, lips * 0.7);
  col += gloss * vec3(0.9, 0.3, 0.3) * 0.5; // glossy highlight
  
  // Rosy blush on cheeks with subtle noise for natural look
  float blush = ell(q, vec2(-0.40, 0.18), vec2(0.20, 0.13)) + ell(q, vec2(0.40, 0.18), vec2(0.20, 0.13));
  float noiseBlush = noise(q * 4.0 + 123.0) * 0.3;
  col = mix(col, col * vec3(1.2, 0.9, 0.95), (blush + noiseBlush) * 0.4);
  
  // Dark eyeliner and eyeshadow: focus on upper eyelid area
  float upperLid = smoothstep(0.1, 0.3, q.y + 0.15) * (1.0 - smoothstep(0.0, 0.2, abs(q.x)));
  float eyeliner = smoothstep(0.0, 0.1, upperLid) * 0.8;
  float shadow = ell(q, vec2(0.0, -0.15), vec2(0.25, 0.1)) * 0.4;
  col = mix(col, vec3(0.1, 0.1, 0.2), (eyeliner + shadow) * 0.6);
  
  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
