// Plasma test fixture - Shadertoy convention, no input channels.
#version 330
void mainImage( out vec4 O, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    float t = iTime;
    float v = sin(uv.x * 10.0 + t) + cos(uv.y * 10.0 - t);
    vec3 col = 0.5 + 0.5 * cos(vec3(0.0, 2.0, 4.0) + v + iResolution.x * 0.0);
    O = vec4(col, 1.0);
}
