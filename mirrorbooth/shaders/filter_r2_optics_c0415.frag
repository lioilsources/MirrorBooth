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
    float r = length(d);
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

    vec2 t = uv * 3.0;
    vec2 c = floor(t);
    vec2 f = fract(t);
    vec2 odd = mod(c, 2.0);
    f = mix(f, 1.0 - f, odd);
    vec3 gridCol = texture(uTexture, f).rgb;
    vec2 e = abs(fract(t) - 0.5);
    gridCol *= smoothstep(0.5, 0.485, max(e.x, e.y));

    float shift = sin(uTime * 2.0 + r * 5.0) * (0.01 * (1.0 - core));
    vec2 ref = d * 0.01;
    ref.x += shift * d.y;
    ref.y -= shift * d.x;
    vec2 refracted = uv + ref;
    vec3 refractCol = texture(uTexture, refracted).rgb;

    col = mix(col, refractCol, 0.3);

    float aspect = uResolution.x / uResolution.y;
    float dx = uv.x - uFaceCenter.x;
    float dy = uv.y - uFaceCenter.y;

    float gx = exp(-(dx * dx * aspect * aspect) / (uFaceScale * uFaceScale));

    float headMask = smoothstep(0.45 * uFaceScale, -0.2 * uFaceScale, dy);
    float srcY = uFaceCenter.y + dy * (1.0 + 0.35 * headMask);
    float srcX = uFaceCenter.x + dx * (1.0 + 0.28 * headMask * gx);

    float neckMask = smoothstep(0.45 * uFaceScale, 1.4 * uFaceScale, dy);
    srcY = uFaceCenter.y + (srcY - uFaceCenter.y) * (1.0 - 0.40 * neckMask);

    srcY = mix(uv.y, srcY, gx);
    srcX = mix(uv.x, srcX, gx);

    vec2 wUV = clamp(vec2(srcX, srcY), 0.0, 1.0);
    vec3 finalCol = texture(uTexture, wUV).rgb;

    float l = dot(finalCol, vec3(0.299, 0.587, 0.114));
    finalCol = mix(vec3(l), finalCol, 0.75);
    float mid = smoothstep(0.15, 0.5, l) * (1.0 - smoothstep(0.6, 0.95, l));
    finalCol *= mix(vec3(1.0), vec3(0.92, 1.10, 0.92), mid * 0.6);

    finalCol *= 1.0 - 0.4 * smoothstep(0.2, 0.6, r);

    vec2 distUV = FlutterFragCoord().xy / uResolution;
    vec2 distD = distUV - uFaceCenter;
    distD.x *= uResolution.x / uResolution.y;
    float distR = length(distD);
    float distRScale = uFaceScale * 0.7;
    if (distR < distRScale && distR > 0.0) {
        float theta = atan(distD.y, distD.x);
        float radius = max(abs(distR / distRScale), 0.001);
        float distorted = pow(radius, 1.4);
        vec2 distortedDir = vec2(cos(theta), sin(theta)) * distorted;
        vec2 displaced = uFaceCenter + distortedDir * distRScale;
        distUV = mix(distUV, displaced, smoothstep(0.7 * distRScale, distRScale, distR));
        distUV.x /= uResolution.x / uResolution.y;
    }

    vec3 fisheyeCol = texture(uTexture, distUV).rgb;
    fragColor = vec4(mix(col, fisheyeCol, 0.5), 1.0);
}
