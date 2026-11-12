#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

vec2 faceQ(vec2 uv) {
    vec2 q = (uv - uFaceCenter) / uFaceScale;
    q.x *= uResolution.x / uResolution.y;
    return q;
}

float ell(vec2 q, vec2 c, vec2 r) {
    return 1.0 - smoothstep(0.6, 1.0, length((q - c) / r));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 q = faceQ(uv);

    // Apply alien skin base: green or grey with subtle texture
    vec3 col = texture(uTexture, uv).rgb;
    float face = ell(q, vec2(0.0, -0.05), vec2(0.66, 0.95));
    col = mix(col, vec3(0.25, 0.55, 0.35) * (0.3 + lum(col)), face * 0.7);

    // Elongated skull: stretch face vertically and horizontally using uFaceScale for control
    float scale = 1.0 + 0.4 * uFaceScale;
    q.y *= scale;
    q.x *= 1.2;

    // Re-calculate face coordinates after deformation
    vec2 q2 = faceQ(uv);

    // Huge black almond eyes — adapted from Shader B
    float eyeL = ell(q2, vec2(-0.30, -0.15), vec2(0.25, 0.45));
    float eyeR = ell(q2, vec2(0.30, -0.15), vec2(0.25, 0.45));
    float eyeMask = max(eyeL, eyeR);
    col = mix(col, vec3(0.0), eyeMask * 1.0);

    // Antennae: two wobbling lines from Shader B, using uTime
    float ant = 0.0;
    for (int i = 0; i < 2; i++) {
        float s = i == 0 ? -1.0 : 1.0;
        vec2 a = vec2(0.20 * s, -0.85);
        vec2 b = vec2(0.45 * s + 0.03 * sin(uTime * 2.0 + float(i)), -1.45);
        vec2 ab = b - a;
        float t = clamp(dot(q - a, ab) / dot(ab, ab), 0.0, 1.0);
        ant = max(ant, 1.0 - smoothstep(0.015, 0.03, length(q - a - ab * t)));
        ant = max(ant, 1.0 - smoothstep(0.05, 0.07, length(q - b)));
    }
    col = mix(col, vec3(0.35, 0.85, 0.35), ant);

    // Subtle alien texture using dot pattern from Shader B
    float zone = ell(q2, vec2(0.0, 0.10), vec2(0.55, 0.22)) * (1.0 - ell(q2, vec2(0.0, 0.35), vec2(0.20, 0.08)));
    vec2 g = q2 * 55.0;
    vec2 id = floor(g);
    vec2 f = fract(g) - 0.5;
    float h = hash(id);
    float dot1 = (1.0 - smoothstep(0.10, 0.25, length(f - (vec2(hash(id + 3.1), hash(id + 7.7)) - 0.5) * 0.4))) * step(0.72, h);
    col = mix(col, col * vec3(0.62, 0.42, 0.30), dot1 * zone * 0.7);

    // Apply head deformation from Shader A: compressed forehead, stretched chin
    float dy = uv.y - uFaceCenter.y;
    float srcY;
    if (dy < 0.0) {
        srcY = uFaceCenter.y + dy * (1.0 - 0.35 * smoothstep(0.0, uFaceScale, -dy));
    } else {
        srcY = uFaceCenter.y + dy * (1.0 + 0.30 * smoothstep(0.0, 0.8 * uFaceScale, dy));
    }

    // Confine horizontally with face-scale-dependent tapering
    float dx = uv.x - uFaceCenter.x;
    float gx = exp(-(dx * dx * (uResolution.x / uResolution.y) * (uResolution.x / uResolution.y)) / (uFaceScale * uFaceScale));
    srcY = mix(uv.y, srcY, gx);

    // Taper the cranium: sample wider toward top using uFaceScale
    float taper = smoothstep(0.0, uFaceScale, -dy) * gx;
    float srcX = uFaceCenter.x + dx * (1.0 + 0.12 * taper);

    vec2 wUV = clamp(vec2(srcX, srcY), 0.0, 1.0);
    vec3 warpedCol = texture(uTexture, wUV).rgb;

    // Final color: blend warped texture with alien effects
    col = mix(col, warpedCol, 0.3);

    // Final desaturation and green cast on midtones
    float l = lum(col);
    col = mix(vec3(l), col, 0.75);
    float mid = smoothstep(0.15, 0.5, l) * (1.0 - smoothstep(0.6, 0.95, l));
    col *= mix(vec3(1.0), vec3(0.92, 1.10, 0.92), mid * 0.6);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
