#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

float fract_sin(float x) { return fract(sin(x) * 12345.678); }
vec2 hash22(vec2 p) { float n = fract_sin(p.x + p.y * 17.0); return vec2(n, fract_sin(p.x * 13.0 + p.y + n)); }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float t = floor(uTime * 7.0);
    float block_y = floor(uv.y * 14.0);
    float block_x = floor(uv.x * 10.0);
    vec2 offset = hash22(vec2(block_x, block_y + t)) * 0.025;
    float jump = fract_sin(block_y + t * 1.5);
    float split = 0.005 + 0.02 * step(0.68, jump);
    vec2 base = uv + offset;
    vec2 r_uv = vec2(fract(base.x + split), base.y);
    vec2 g_uv = base;
    vec2 b_uv = vec2(fract(base.x - split), base.y);
    vec3 col;
    col.r = texture(uTexture, r_uv).r;
    col.g = texture(uTexture, g_uv).g;
    col.b = texture(uTexture, b_uv).b;

    // Apply color grading from Shader B based on luminance
    float l = dot(col, vec3(0.299, 0.587, 0.114));
    l = smoothstep(0.05, 0.95, l);
    vec3 lo = vec3(0.1, 0.05, 0.38);
    vec3 mid = vec3(0.93, 0.18, 0.5);
    vec3 hi = vec3(1.0, 0.92, 0.45);
    col = l < 0.5 ? mix(lo, mid, l * 2.0) : mix(mid, hi, l * 2.0 - 1.0);

    // Apply glitch effects from Shader B: block row jitter and pixel-level noise
    float cw = uResolution.x / 32.0;
    vec2 g = FlutterFragCoord().xy / vec2(cw, cw * 1.2);
    vec2 cell = floor(g);
    vec2 f = fract(g);
    float hcol = fract_sin(cell.x + 5.0);
    float rows = uResolution.y / (cw * 1.2);
    float head = fract(uTime * (0.18 + 0.35 * hcol) + hcol * 5.0) * (rows + 10.0);
    float dist = head - cell.y;
    float trail = dist > 0.0 ? exp(-dist * 0.3) : 0.0;
    float isHead = step(0.0, dist) * step(dist, 1.0);
    float tick = floor(uTime * (3.2 + 6.8 * fract_sin(cell.x + cell.y * 19.0)));
    vec2 bit = floor(f * vec2(3.0, 5.0));
    float glyph = step(0.6, fract_sin(bit.x + bit.y * 13.0 + cell.x * 7.0 + tick));
    glyph *= step(0.15, f.x) * step(f.x, 0.85) * step(0.1, f.y) * step(f.y, 0.9);
    float l2 = dot(texture(uTexture, (cell + 0.5) * vec2(cw, cw * 1.2) / uResolution).rgb, vec3(0.299, 0.587, 0.114));
    vec3 glitch_col = vec3(0.01, 0.3, 0.1) * l2;
    glitch_col += vec3(0.1, 0.9, 0.3) * glyph * (trail * (0.4 + 1.3 * l2) + 0.08 * l2);
    glitch_col += vec3(0.6, 0.9, 0.7) * glyph * isHead;

    // Transfer: Add rhythmic chromatic shift with time-based jitter and motion sync
    float glitch = 0.012 * sin(uTime * 4.8 + 10.0 * uv.x + 12.0 * uv.y + 1.5 * sin(uTime * 1.1));
    col.r = texture(uTexture, uv + vec2(glitch, 0.0)).r;
    col.g = texture(uTexture, uv + vec2(-glitch, 0.0)).g;
    col.b = texture(uTexture, uv + vec2(0.0, glitch)).b;

    // Transfer: Add subtle organic jitter synced to face and time
    float jitter = 0.006 * sin(uTime * 7.0 + uv.x * 18.0 + uv.y * 22.0);
    vec2 jitterUV = uv + vec2(jitter, jitter * 0.7);
    col = mix(col, texture(uTexture, clamp(jitterUV, 0.0, 1.0)).rgb, 0.2 * step(0.3, length(uv - uFaceCenter) / uFaceScale));

    // Transfer: Add dynamic neon glow with pulsing from center
    float glow = 1.0 - pow(length(uv - uFaceCenter) / (uFaceScale * 1.2), 0.1);
    float glowIntensity = 1.0 * (1.0 - l) * glow * (0.5 + 0.5 * sin(uTime * 1.5));
    vec3 neon = vec3(0.0, 0.8, 1.0) * (0.5 + 0.5 * sin(uTime * 0.7)) + vec3(1.0, 1.0, 0.5) * (0.5 + 0.5 * sin(uTime * 1.1));
    col = mix(col, neon, glowIntensity * 0.7);

    // Transfer: Add halftone CMYK screening from the other filter
    float cellSize = 10.0;
    float angleC = radians(105.0);
    float angleM = radians(75.0);
    float angleY = radians(90.0);
    float angleK = radians(45.0);
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 px = 1.0 / uResolution;
    vec3 src = texture(uTexture, uv).rgb;
    float C = 1.0 - src.r;
    float M = 1.0 - src.g;
    float Y = 1.0 - src.b;
    float K = min(C, min(M, Y));
    C = (C - K) / max(1.0 - K, 0.001);
    M = (M - K) / max(1.0 - K, 0.001);
    Y = (Y - K) / max(1.0 - K, 0.001);

    float dotC = fract_sin(fragCoord.x * cos(angleC) - fragCoord.y * sin(angleC) + 100.0) * 2.0;
    float dotM = fract_sin(fragCoord.x * cos(angleM) - fragCoord.y * sin(angleM) + 200.0) * 2.0;
    float dotY = fract_sin(fragCoord.x * cos(angleY) - fragCoord.y * sin(angleY) + 300.0) * 2.0;
    float dotK = fract_sin(fragCoord.x * cos(angleK) - fragCoord.y * sin(angleK) + 400.0) * 2.0;

    dotC = step(0.5, dotC);
    dotM = step(0.5, dotM);
    dotY = step(0.5, dotY);
    dotK = step(0.5, dotK);

    vec3 cmyk = vec3(dotC, dotM, dotY);
    float k = dotK;
    col.r = clamp(1.0 - cmyk.r - k, 0.0, 1.0);
    col.g = clamp(1.0 - cmyk.g - k, 0.0, 1.0);
    col.b = clamp(1.0 - cmyk.b - k, 0.0, 1.0);

    fragColor = vec4(col + glitch_col, 1.0);
}
