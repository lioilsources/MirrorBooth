#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

// Wobble test fixture - samples the camera channel (iChannel0).
void main(){
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;
    uv.x += 0.02 * sin(uv.y * 20.0 + uTime);
    vec4 cam = texture(uTexture, uv);
    fragColor = vec4(cam.rgb * 1.1, 1.0);
}
