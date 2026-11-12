#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 faceQ(vec2 uv) { vec2 q = (uv - uFaceCenter) / uFaceScale; q.x *= uResolution.x / uResolution.y; return q; }
float ell(vec2 q, vec2 c, vec2 r) { return 1.0 - smoothstep(0.6, 1.0, length((q - c) / r)); }
float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 q = faceQ(uv);
  vec3 col = texture(uTexture, uv).rgb;
  float face = ell(q, vec2(0.0, 0.0), vec2(0.62, 0.90));
  col = mix(col, vec3(0.95, 0.94, 0.9) * (0.5 + 0.6 * lum(col)), face * 0.9);
  float sock = max(ell(q, vec2(-0.30, -0.15), vec2(0.17, 0.15)), ell(q, vec2(0.30, -0.15), vec2(0.17, 0.15)));
  float nose = ell(q, vec2(0.0, 0.10), vec2(0.07, 0.10));
  col = mix(col, vec3(0.02), max(sock, nose) * face);
  float lip = (1.0 - smoothstep(0.005, 0.012, abs(q.y - 0.38))) * step(abs(q.x), 0.26);
  col = mix(col, vec3(0.03), lip * face);
  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
