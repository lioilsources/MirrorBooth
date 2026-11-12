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
    return mix(mix(fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453),
                     fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453), f.x),
           mix(fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453),
                     fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453), f.x), f.y);
}

float lum(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 q = faceQ(uv);
    vec3 col = texture(uTexture, uv).rgb;
    float l = lum(col);

    // Zombie decay: gray-green tint
    col = mix(vec3(l), col, 0.4) * vec3(0.62, 0.80, 0.58);

    // Face mask to localize effects
    vec2 d = uv - uFaceCenter;
    d.x *= uResolution.x / uResolution.y;
    float face = exp(-dot(d, d) / (0.9 * uFaceScale * uFaceScale));

    // Burned skin: noise-based blotches
    float n = 0.65 * noise(uv * 14.0) + 0.35 * noise(uv * 31.0);
    float blotch = smoothstep(0.60, 0.74, n) * face;
    col = mix(col, col * vec3(0.50, 0.55, 0.40), blotch);

    // Werewolf eyes: darkened eye sockets
    vec2 e = vec2(uFaceCenter.x, uFaceCenter.y - 0.35 * uFaceScale);
    vec2 k = uv - e;
    k.x *= (uResolution.x / uResolution.y) * 0.6;
    float sigma = 0.32 * uFaceScale;
    float w = exp(-dot(k, k) / (sigma * sigma));
    col *= 1.0 - 0.55 * w;

    // Cyborg metal plate: metallic sheen aligned with face
    float metal = noise(uv * 20.0 + uFaceCenter * 0.5) * 0.5 + 0.5;
    float plate = smoothstep(0.4, 0.6, abs(q.x * 0.8)) * face;
    col = mix(col, vec3(0.7, 0.7, 0.7) * (0.9 + 0.1 * l), plate * metal * 0.4);

    // Eyes deepened for undead/werewolf effect
    float eyes = max(ell(q, vec2(-0.30, -0.15), vec2(0.14, 0.20)), ell(q, vec2(0.30, -0.15), vec2(0.14, 0.20)));
    col = mix(col, vec3(0.05, 0.08, 0.12) + col * 0.2, eyes * 0.8);

    // Transfer: funhouse-style distortion from other filter
    vec2 displace = (uv - uFaceCenter) / uFaceScale;
    float r = length(displace);
    float R = uFaceScale;
    vec2 wUV = uv;
    if (r < R && r > 0.0) {
        vec2 dn = displace * pow(r / R, 0.55);
        dn = mix(dn, displace, smoothstep(0.8 * R, R, r));
        dn.x *= uResolution.x / uResolution.y;
        wUV = uFaceCenter + dn;
        wUV = clamp(wUV, 0.0, 1.0);
    }

    vec3 distortedColor = texture(uTexture, wUV).rgb;
    float mask = exp(-r * r * 2.0);
    col = mix(col, distortedColor, mask * 0.3);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
