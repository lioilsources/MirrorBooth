#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 faceQ(vec2 uv) { vec2 q = (uv - uFaceCenter) / uFaceScale; q.x *= uResolution.x / uResolution.y; return q; }
float ell(vec2 q, vec2 c, vec2 r) { return 1.0 - smoothstep(0.6, 1.0, length((q - c) / r)); }
vec2 exaggeratedFeature(vec2 uv, vec2 center, float scale) {
    vec2 d = uv - center;
    float r = length(d);
    float radialBoost = 0.5 * (1.0 - exp(-r * r * 2.0));
    float wave = 0.3 * radialBoost * sin(12.0 * d.x + 8.0 * d.y + 4.0 * scale);
    float factor = 1.0 + wave * (1.0 + r * 1.2);
    return center + d * factor * scale;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 q = faceQ(uv);
    
    vec2 warpedUV = exaggeratedFeature(uv, uFaceCenter, uFaceScale);
    float faceProximity = ell(q, vec2(0.0, 0.05), vec2(0.65, 0.90));
    vec2 finalUV = mix(uv, warpedUV, faceProximity);
    
    vec3 color = texture(uTexture, clamp(finalUV, 0.0, 1.0)).rgb;
    color = mix(color, smoothstep(0.0, 1.0, color), faceProximity * 0.3);
    
    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
