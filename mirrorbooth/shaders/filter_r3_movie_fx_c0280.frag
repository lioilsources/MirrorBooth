#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

vec2 distortWave(vec2 uv, vec2 center, float scale) {
    float aspect = uResolution.x / uResolution.y;
    vec2 d = (uv - center) * vec2(aspect, 1.0);
    float dist = length(d);
    float ripple = 0.1 * sin(3.0 * dist / (0.2 * scale) + uFaceCenter.x * 10.0) * exp(-dist * dist / (0.25 * scale * scale));
    d += ripple * normalize(d) * vec2(aspect, 1.0);
    return center + d / vec2(aspect, 1.0);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 src = distortWave(uv, uFaceCenter, uFaceScale);
    vec3 col = texture(uTexture, clamp(src, 0.0, 1.0)).rgb;

    // Zombie decay: grayish pallor with unnatural skin tone
    float l = lum(col);
    col = mix(vec3(0.5), col, 0.5);
    col = mix(col, vec3(0.3, 0.35, 0.4), 0.2 * smoothstep(0.5, 0.7, l));

    // Burned skin: irregular charred patches near nose and cheeks
    vec2 burnPos = uv - uFaceCenter;
    burnPos.x *= uResolution.x / uResolution.y;
    float burnDist = length(burnPos) / uFaceScale;
    float burn = smoothstep(0.4, 0.55, burnDist) * smoothstep(0.6, 0.4, sin(burnDist * 7.0 + 1.5) * 0.5 + 0.5);
    col = mix(col, vec3(0.05, 0.05, 0.0), 0.3 * burn);

    // Cyborg metal plate: reflective forehead plate with dynamic tint
    vec2 platePos = vec2(uFaceCenter.x, uFaceCenter.y - 0.12 * uFaceScale);
    vec2 plateOffset = uv - platePos;
    plateOffset.x *= uResolution.x / uResolution.y;
    float plateDist = length(plateOffset);
    float plateMask = smoothstep(0.15, 0.1, plateDist / (0.1 * uFaceScale));
    vec3 plateColor = vec3(0.9, 0.8, 0.7) * (0.5 + 0.5 * cos(uFaceCenter.y * 10.0 + uv.x * 200.0));
    col = mix(col, plateColor, 0.4 * plateMask);

    // Werewolf transformation: coarse texture overlay with eye glow
    vec2 eyePos = vec2(uFaceCenter.x, uFaceCenter.y - 0.3 * uFaceScale);
    vec2 eyeOffset = uv - eyePos;
    eyeOffset.x *= uResolution.x / uResolution.y;
    float eyeDist = length(eyeOffset);
    float eyeGlow = exp(-eyeDist * eyeDist / (0.02 * uFaceScale * uFaceScale));
    float fur = fract(uv.x * 120.0 + uv.y * 180.0 + uFaceCenter.x * 100.0);
    fur = smoothstep(0.3, 0.7, fur);
    col = mix(col, vec3(0.9, 0.8, 0.6), 0.2 * fur * eyeGlow);

    // Mummy wrap: tight white bandage with uneven tension
    vec2 wrapPos = uv - uFaceCenter;
    wrapPos.x *= uResolution.x / uResolution.y;
    float wrapDist = length(wrapPos);
    float wrapMask = smoothstep(0.25, 0.2, wrapDist / (0.6 * uFaceScale));
    float wrapNoise = abs(sin(wrapDist * 12.0 + uFaceCenter.x * 30.0)) * 0.5 + 0.5;
    col = mix(col, vec3(0.95, 0.9, 0.85), 0.5 * wrapMask * wrapNoise);

    // Final deep shadow: subtle vignette with cool undertone
    vec2 center = vec2(0.5);
    vec2 d = uv - center;
    d.x *= uResolution.x / uResolution.y;
    float vignette = smoothstep(0.35, 0.9, length(d));
    col = mix(col, vec3(0.05, 0.08, 0.12), vignette * 0.3);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
