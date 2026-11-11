#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 base = texture(uTexture, uv).rgb;
    
    // Apply Shader B's bokeh and glow: multiple samples in circles
    float dist = abs(uv.y - uFaceCenter.y);
    float amt = smoothstep(0.12, 0.42, dist);
    vec2 rad = amt * 9.0 / uResolution;
    vec3 acc = base;
    for (int i = 0; i < 12; i++) {
        float a = 2.3999632 * float(i);
        float r = sqrt((float(i) + 0.5) / 12.0);
        acc += texture(uTexture, uv + vec2(cos(a), sin(a)) * r * rad).rgb;
    }
    vec3 bokeh = acc / 13.0;
    bokeh = mix(vec3(luma(bokeh)), bokeh, 1.45);
    bokeh = (bokeh - 0.5) * 1.12 + 0.5;
    
    // Apply Shader A's light rays: radial sampling from face center
    vec2 dir = uFaceCenter - uv;
    vec3 rays = vec3(0.0);
    float wsum = 0.0;
    for (int i = 0; i < 18; i++) {
        float t = float(i) / 18.0;
        vec3 c = texture(uTexture, uv + dir * t * 0.55).rgb;
        float w = 1.0 - t;
        rays += max(c - 0.72, 0.0) * w;
        wsum += w;
    }
    rays = rays / wsum * 2.4;
    
    // Combine bokeh and rays with bloom-like glow
    vec3 glow = mix(bokeh, rays, 0.7);
    vec3 final = base * 0.9 + glow * vec3(1.0, 0.9, 0.7);
    
    // Add vignette using max and smoothstep
    float vignette = smoothstep(0.0, 1.0, max(1.0 - length(uv - 0.5) * 1.5, 0.0));
    final *= vignette;
    
    fragColor = vec4(clamp(final, 0.0, 1.0), 1.0);
}
