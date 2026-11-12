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

vec2 jellyWobble(vec2 uv, vec2 center, float scale) {
    float aspect = uResolution.x / uResolution.y;
    vec2 d = (uv - center) * vec2(aspect, 1.0);
    float dist = length(d);
    float influence = exp(-dist * dist / (0.3 * scale * scale));
    float wobble = 0.15 * influence * sin(2.0 * 3.14159 * dist / (0.4 * scale));
    d.x += wobble * aspect;
    return center + d / vec2(aspect, 1.0);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 src = jellyWobble(uv, uFaceCenter, uFaceScale);
    vec3 col = texture(uTexture, clamp(src, 0.0, 1.0)).rgb;

    // Apply zombie decay: greenish desaturation, pale skin
    float l = lum(col);
    col = mix(vec3(l), col, 0.4) * vec3(0.65, 0.85, 0.60);

    // Apply burned skin: irregular charred patches
    float n = 0.55 * noise(uv * 12.0) + 0.45 * noise(uv * 28.0);
    float burn = smoothstep(0.65, 0.78, n);
    col = mix(col, col * vec3(0.45, 0.50, 0.35), burn * 0.3);

    // Apply werewolf eyes with glow: deep red glow around eyes
    vec2 eye = vec2(uFaceCenter.x, uFaceCenter.y - 0.35 * uFaceScale);
    vec2 e = uv - eye;
    e.x *= (uResolution.x / uResolution.y) * 0.6;
    float glow = exp(-dot(e, e) / (0.25 * uFaceScale * uFaceScale));
    col = mix(col, vec3(0.1, 0.2, 0.4) + col * 0.6, glow * 0.7);

    // Apply cyborg metal plate: metallic sheen on forehead
    float metal = noise(uv * 20.0 + uFaceCenter * 0.5) * 0.5 + 0.5;
    float plate = smoothstep(0.4, 0.6, abs(faceQ(uv).x * 0.8)) * faceQ(uv).y;
    col = mix(col, vec3(0.7, 0.7, 0.7) * (0.9 + 0.1 * l), plate * metal * 0.4);

    // Apply mummy wrappings: diagonal bandage noise
    float mummy = noise(uv * 10.0 + uFaceCenter * 0.3) * 0.7 + 0.3;
    float wrap = smoothstep(0.45, 0.55, abs(faceQ(uv).x * 0.7 + faceQ(uv).y * 0.3)) * mummy;
    col = mix(col, vec3(0.85, 0.80, 0.70), wrap * 0.4);

    // Apply funhouse distortion: transfer via displacement
    vec2 displace = (uv - uFaceCenter) / uFaceScale;
    float r = length(displace);
    float mask = exp(-r * r * 2.0);
    float wave = 0.5 * mask * (1.0 + cos(12.0 * displace.x + 9.0 * displace.y + 3.0 * uFaceScale));
    float stretch = 1.0 + wave * (1.0 + r * 0.8);
    vec2 distortedUV = uFaceCenter + displace * stretch * uFaceScale;
    vec3 distortedColor = texture(uTexture, distortedUV).rgb;
    col = mix(col, distortedColor, mask * 0.3);

    // Final face mask to preserve structure using uFaceCenter and uFaceScale
    vec2 d = uv - uFaceCenter;
    d.x *= uResolution.x / uResolution.y;
    float face = exp(-dot(d, d) / (0.9 * uFaceScale * uFaceScale));
    col *= face;

    // Final touch: apply jelly wobble again to simulate unstable flesh
    vec2 wobbleUV = jellyWobble(uv, uFaceCenter, uFaceScale);
    vec3 wobbleColor = texture(uTexture, wobbleUV).rgb;
    col = mix(col, wobbleColor, 0.15 * face);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
