#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 d = uv - uFaceCenter;
    float r = max(length(d), 0.0001);
    float R = max(uFaceScale * 0.55, 0.08) * (1.0 + 0.12 * sin(uTime * 1.3));
    float bend = (R * R) / (r * r);
    vec2 sd = d * (1.0 - bend);
    vec2 suv = uFaceCenter + sd;
    suv = abs(mod(suv, 2.0) - 1.0);
    suv = 1.0 - suv;
    vec3 col = texture(uTexture, clamp(suv, 0.0, 1.0)).rgb;
    float core = smoothstep(R * 0.72, R * 0.6, r);
    float ring = exp(-pow((r - R) / (R * 0.12), 2.0));
    float swirl = 0.5 + 0.5 * sin(atan(d.y, d.x) * 3.0 - uTime * 3.0);
    col = mix(col, vec3(0.0), core);
    col += vec3(1.0, 0.62, 0.25) * ring * (0.5 + 0.7 * swirl);

    // Replace grid distortion with glass refraction: simulate a warped glass surface
    vec2 t = uv * 3.0;
    vec2 c = floor(t);
    vec2 f = fract(t);
    vec2 odd = mod(c, 2.0);
    f = mix(f, 1.0 - f, odd);
    vec3 gridCol = texture(uTexture, f).rgb;
    vec2 e = abs(fract(t) - 0.5);
    gridCol *= smoothstep(0.5, 0.485, max(e.x, e.y));
    
    // Apply refraction: shift texture coordinates based on a sine wave distorted by face proximity
    float shift = sin(uTime * 2.0 + r * 5.0) * (0.01 * (1.0 - core));
    vec2 ref = d * 0.01;
    ref.x += shift * d.y;
    ref.y -= shift * d.x;
    vec2 refracted = uv + ref;
    vec3 refractCol = texture(uTexture, refracted).rgb;
    
    // Blend refraction with base color
    col = mix(col, refractCol, 0.3);
    
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
