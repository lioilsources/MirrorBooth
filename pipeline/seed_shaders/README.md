# ToyShaders seed corpus

Original, CC0-licensed GLSL shaders written in the **Shadertoy convention**.
They are the realtime-technique knowledge base for the shader generator: the
RAG index ingests them (both as-is and auto-ported to the Flutter contract),
so `glsl_coder` can learn idioms like noise, domain warp, kaleidoscope,
sphere-trace, palette cycling, CRT and chromatic effects.

These files are **not** shipped in the Flutter app. They are reference
material only. See `LICENSE` (CC0-1.0) and `NOTICE` (provenance).

## Convention

```glsl
// <Title> — one-line technique summary
// Author: MirrorBooth
// SPDX-License-Identifier: CC0-1.0
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;   // iResolution: vec3 viewport
    // iTime      : float seconds (animation)
    // iChannel0  : the camera frame
    vec3 cam = texture(iChannel0, uv).rgb;
    fragColor = vec4(cam, 1.0);
}
```

`pipeline/agents/shadertoy_adapter.py` deterministically rewrites this to the
Flutter/Impeller contract (`FlutterFragCoord()`, `uResolution`, `uTime`,
`uTexture`, `#include <flutter/runtime_effect.glsl>`).

## Adding shaders

Prefer authoring new **original** effects (CC0). Each new file must keep the
header + SPDX line and sample `iChannel0` in at least one path so the camera
port is meaningful. Third-party files: see `NOTICE` (MIT/CC0 only).
