#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

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

    // Bone-pale grade: heavy desaturation, lifted midtones, cool cast
    float l = lum(col);
    col = mix(vec3(l), col, 0.35);
    col = pow(clamp(col, 0.0, 1.0), vec3(0.85)) * vec3(0.98, 0.97, 1.03);

    // Red eye band, weighted by darkness so the tint hugs the eyes
    vec2 e = vec2(uFaceCenter.x, uFaceCenter.y - 0.35 * uFaceScale);
    vec2 k = uv - e;
    k.x *= uResolution.x / uResolution.y;
    float sigma = 0.32 * uFaceScale;
    float w = exp(-dot(k, k) / (sigma * sigma));
    float dark = 0.35 + 0.65 * smoothstep(0.55, 0.15, l);
    col = mix(col, vec3(0.60, 0.05, 0.08), 0.9 * w * dark);

    // Deep red-black vignette + mild contrast lift
    vec2 d = uv - vec2(0.5);
    d.x *= uResolution.x / uResolution.y;
    float vig = smoothstep(0.42, 0.9, length(d));
    col = mix(col, vec3(0.08, 0.0, 0.02), vig);
    col = mix(vec3(0.5), col, 1.1);

    // Apply zombie burn: irregular dark patches near face center
    vec2 burnOffset = uv - uFaceCenter;
    burnOffset.x *= uResolution.x / uResolution.y;
    float burnDist = length(burnOffset) / uFaceScale;
    float burnNoise = smoothstep(0.5, 0.8, burnDist) * smoothstep(0.3, 0.6, sin(burnDist * 5.0 + 2.0) * 0.5 + 0.5);
    col = mix(col, vec3(0.0, 0.0, 0.0), 0.2 * burnNoise);

    // Apply cyborg metal plate: a metallic sheen on the forehead
    vec2 plateCenter = vec2(uFaceCenter.x, uFaceCenter.y - 0.1 * uFaceScale);
    vec2 plateOffset = uv - plateCenter;
    plateOffset.x *= uResolution.x / uResolution.y;
    float plateDist = length(plateOffset);
    float plateMask = smoothstep(0.2, 0.1, plateDist / (0.15 * uFaceScale));
    vec3 metalTint = vec3(0.8, 0.8, 1.0) * (0.5 + 0.5 * sin(uFaceScale * 10.0 + uv.y * 100.0));
    col = mix(col, metalTint, 0.3 * plateMask);

    // Apply werewolf fur: coarse grain overlay
    float furNoise = fract(uv.x * 100.0 + uv.y * 150.0 + uFaceCenter.x * 200.0);
    furNoise = smoothstep(0.2, 0.8, furNoise);
    col = mix(col, col * vec3(0.9, 1.0, 0.8), 0.1 * furNoise);

    // Apply mummy wrap: tight white bandage effect around face
    vec2 wrapOffset = uv - uFaceCenter;
    wrapOffset.x *= uResolution.x / uResolution.y;
    float wrapDist = length(wrapOffset);
    float wrapMask = smoothstep(0.3, 0.25, wrapDist / (0.7 * uFaceScale));
    float wrapNoise = abs(sin(wrapDist * 10.0 + uFaceCenter.y * 20.0)) * 0.5 + 0.5;
    col = mix(col, vec3(1.0), 0.4 * wrapMask * wrapNoise);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
