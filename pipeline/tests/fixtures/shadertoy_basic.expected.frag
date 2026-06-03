#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

// Plasma test fixture - Shadertoy convention, no input channels.

void main(){
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;
    float t = uTime;
    float v = sin(uv.x * 10.0 + t) + cos(uv.y * 10.0 - t);
    vec3 col = 0.5 + 0.5 * cos(vec3(0.0, 2.0, 4.0) + v + uResolution.x * 0.0);
    fragColor = vec4(col, 1.0);
}
