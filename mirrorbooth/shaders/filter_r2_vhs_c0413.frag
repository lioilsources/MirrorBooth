#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uFaceCenter;
uniform float uFaceScale;

out vec4 fragColor;

vec2 distortion(vec2 uv, float strength) {
    vec2 c = (uv - 0.5) * 2.0;
    c.x *= uResolution.x / uResolution.y;
    float r2 = c.x * c.x + c.y * c.y;
    c *= 1.0 + strength * r2 * (1.0 - r2);
    c.x /= (uResolution.x / uResolution.y);
    return c * 0.5 + 0.5;
}

float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float bayer4(vec2 a) {
    return 0.25 * fract(a.x / 2.0 + a.y * a.y * 0.75) + fract(a.x + a.y * 0.75);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // Apply CRT curvature from Shader A
    vec2 wUV = distortion(uv, 0.16);
    if (wUV.x < 0.0 || wUV.x > 1.0 || wUV.y < 0.0 || wUV.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // Extract base color from Shader B with tracking jitter and chroma bleed
    float band = fract(uv.y * 0.9 - uTime * 0.17);
    float tear = smoothstep(0.0, 0.03, band) * (1.0 - smoothstep(0.03, 0.09, band));
    float jitter = (fract(floor(uv.y * 240.0) + uTime * 30.0) - 0.5) * 0.004;
    vec2 suv = vec2(uv.x + jitter + tear * 0.035 * sin(uv.y * 90.0 + uTime * 20.0), uv.y);
    suv.x = clamp(suv.x, 0.0, 1.0);

    float y = dot(texture(uTexture, suv).rgb, vec3(0.299, 0.587, 0.114));
    vec3 cl = texture(uTexture, vec2(clamp(suv.x - 0.012, 0.0, 1.0), suv.y)).rgb;
    vec3 cr = texture(uTexture, vec2(clamp(suv.x + 0.012, 0.0, 1.0), suv.y)).rgb;
    vec3 chroma = 0.5 * (cl + cr) - vec3(dot(0.5 * (cl + cr), vec3(0.299, 0.587, 0.114)));
    vec3 col = vec3(y) + chroma * 1.25 + vec3(0.03, 0.0, 0.05);

    float n = fract(floor(FlutterFragCoord().y * 240.0) + uTime * 61.0);
    col += (n - 0.5) * 0.09 + tear * 0.18 * n;
    col *= 0.9 + 0.1 * sin(FlutterFragCoord().y * 2.2);

    // Apply shadow mask from Shader A: vertical stripes
    float mask = mod(wUV.x * 3.0, 1.0);
    float maskIntensity = step(0.33, mask) - step(0.66, mask);
    vec3 shadow = vec3(maskIntensity);

    // Apply scanlines from Shader A: alternating dark lines
    float scan = 0.6 + 0.4 * sin(FlutterFragCoord().y * 2.0);
    vec3 color = col * scan;

    // Add grain and flicker noise
    float noiseVal = noise(wUV * 300.0 + uTime * 13.0);
    color += (noiseVal - 0.5) * 0.05;

    // Vignette from Shader A: darken edges
    vec2 vig = wUV * 2.0 - 1.0;
    float vignette = pow(clamp(1.0 - dot(vig, vig) * 1.2, 0.0, 1.0), 0.9);
    color *= vignette;

    // Apply bayer dithering from Shader A for dot crawl effect
    float px = max(2.0, floor(uResolution.x / 180.0));
    vec2 cell = floor(FlutterFragCoord().xy / px);
    vec2 cuv = (cell + 0.5) * px / uResolution;
    float l = dot(texture(uTexture, cuv).rgb, vec3(0.299, 0.587, 0.114));
    l = clamp((l - 0.5) * 1.3 + 0.5, 0.0, 1.0);
    float on = step(bayer4(cell) + 0.03, l);
    color = mix(vec3(0.07, 0.09, 0.22), vec3(0.95, 0.91, 0.78), on);

    // Final color adjustment: warm tint and contrast
    color = mix(vec3(0.95, 0.9, 0.85), color, 0.7);
    color *= 1.1;

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
