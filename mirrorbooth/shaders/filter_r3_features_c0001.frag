#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 faceQ(vec2 uv) {
    vec2 q = (uv - uFaceCenter) / uFaceScale;
    q.x *= uResolution.x / uResolution.y;
    return q;
}

float ell(vec2 q, vec2 c, vec2 r) {
    return 1.0 - smoothstep(0.6, 1.0, length((q - c) / r));
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453),
            fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453), f.x),
        mix(fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453),
            fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453), f.x), f.y
    );
}

float lum(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 q = faceQ(uv);
    
    // Apply distortion from Shader B: magnify around face center using non-linear scaling
    vec2 d = q;
    float r = length(d);
    float R = 1.0;
    
    vec2 wQ = d;
    if (r < R && r > 0.0) {
        float scale = pow(r / R, 0.55);
        wQ = d * scale;
        wQ = mix(wQ, d, smoothstep(0.8 * R, R, r));
    }
    
    // Apply feature exaggeration from Shader A: focus on mouth, eyes, nose
    vec2 src = wQ;
    float mouth = ell(src, vec2(0.0, 0.35), vec2(0.30, 0.25));
    float eyes = ell(src, vec2(-0.30, -0.15), vec2(0.15, 0.15)) + ell(src, vec2(0.30, -0.15), vec2(0.15, 0.15));
    float nose = ell(src, vec2(0.0, 0.05), vec2(0.15, 0.25));
    
    // Combine exaggeration factors with non-linear amplification
    float exaggeration = 1.0 + 2.0 * (mouth + eyes + nose) * (1.0 - exp(-r * 3.0));
    src *= exaggeration;
    
    // Map back to texture coordinates
    src.x /= uResolution.x / uResolution.y;
    vec2 wUV = uFaceCenter + src * uFaceScale;
    wUV = clamp(wUV, 0.0, 1.0);
    
    fragColor = vec4(texture(uTexture, wUV).rgb, 1.0);
}
