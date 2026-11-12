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
  vec3 col = texture(uTexture, uv).rgb;

  // Replace distortion function: use radial compression to simulate a soft lens flare effect, emphasizing the face center
  float aspect = uResolution.x / uResolution.y;
  vec2 d = uv - uFaceCenter;
  d.x *= aspect;
  float r = length(d);
  float R = uFaceScale * 0.8;
  vec2 wUV = uv;
  if (r < R && r > 0.0) {
    float compress = 1.0 - 0.1 * (r / R);
    vec2 dn = d * compress;
    dn.x /= aspect;
    wUV = uFaceCenter + dn;
  }
  col = texture(uTexture, wUV).rgb;

  // Glossy red lipstick on mouth
  float mouth = ell(q, vec2(0.0, 0.35), vec2(0.30, 0.18));
  vec3 lipColor = vec3(0.9, 0.0, 0.1); // Vibrant red
  col = mix(col, lipColor, mouth * 0.8);
  
  // Add glossy highlight to lips with subtle wave pattern
  float lipGloss = ell(q, vec2(0.0, 0.35), vec2(0.15, 0.08)) * (1.0 - smoothstep(0.0, 0.05, abs(q.y - 0.35)));
  float wave = noise(q * 10.0 + uFaceCenter * 5.0) * 0.2;
  col = mix(col, vec3(1.0, 0.8, 0.8), (lipGloss + wave) * 0.6);

  // Rosy blush on cheeks
  float cheek = ell(q, vec2(-0.35, 0.05), vec2(0.25, 0.20)) + ell(q, vec2(0.35, 0.05), vec2(0.25, 0.20));
  col = mix(col, vec3(1.0, 0.6, 0.7), cheek * 0.4);

  // Dark eyeliner and eyeshadow
  float eyeLid = ell(q, vec2(-0.30, -0.15), vec2(0.15, 0.06)) * smoothstep(-0.10, -0.25, q.y);
  col = mix(col, vec3(0.05, 0.05, 0.05), eyeLid * 0.7);

  // Eyeshadow (deeper dark with subtle gradient)
  float eyeShadow = ell(q, vec2(-0.30, -0.15), vec2(0.25, 0.15)) * (1.0 - smoothstep(0.0, 0.03, abs(q.y + 0.15)));
  float grad = smoothstep(0.0, 0.2, q.x + 0.2);
  col = mix(col, vec3(0.1, 0.05, 0.2), eyeShadow * 0.6 * grad);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
