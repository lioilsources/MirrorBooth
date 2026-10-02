// Ported from https://www.shadertoy.com/view/stWebInv — "Webcam Invert Wave" by alice, MIT
// Converted to the MirrorBooth/Flutter shader contract by ShaderGen v2 (pipeline/shadertoy/transpile.py).

#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

#define iResolution vec3(uResolution, 1.0)
#define iTime uTime

// Shadertoy UV (bottom-left origin) -> camera texture (top-left origin)
vec4 stSample(vec2 uv) { return texture(uTexture, vec2(uv.x, 1.0 - uv.y)); }

// ---- Shadertoy: Image ----
// The MIT License
// Copyright (c) 2024 Test Author
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software.

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    uv.x += 0.01 * sin(uv.y * 20.0 + iTime);
    vec3 col = stSample(uv).rgb;
    fragColor = vec4(1.0 - col, 1.0);
}

// ---- MirrorBooth entry point ----
void main() {
    vec2 fc = FlutterFragCoord().xy;
    fc.y = uResolution.y - fc.y;  // Flutter: top-left origin, Shadertoy: bottom-left
    vec4 c = vec4(0.0);
    mainImage(c, fc);
    fragColor = vec4(clamp(c.rgb, 0.0, 1.0), 1.0);
}
