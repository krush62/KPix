#version 460 core
precision highp float;

// CMYK halftone dot shader, ported to Flutter.
// Dot grid in output pixel space, cell size set by uDotSize.

#include <flutter/runtime_effect.glsl>

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

uniform float uDotSize;   // halftone cell size in output pixels, e.g. 6.0

uniform sampler2D uSource;

out vec4 fragColor;

// 1.0 inside the dot of a rotated screen, 0.0 outside
// original: mul(m, v) = v * m
float screenDot(vec2 p, mat2 m, float freq, float ink)
{
    vec2 st = freq * (p * m);
    vec2 cell = 2.0 * fract(st) - 1.0;
    return step(0.0, sqrt(ink) - length(cell));
}

void main()
{
    vec2 pos = FlutterFragCoord().xy + uOffset;
    vec2 texel = floor(pos / uScale);
    vec2 uv = (texel + 0.5) / uSourceSize;
    uv.y = mix(uv.y, 1.0 - uv.y, uFlipY);

    vec4 src = texture(uSource, uv);

    float alpha = src.a;
    vec3 texcolor = alpha > 0.0 ? src.rgb / alpha : vec3(0.0);

    float freq = 1.0 / max(uDotSize, 1.0);

    // rough RGB -> CMYK
    vec4 cmyk;
    cmyk.xyz = 1.0 - texcolor;
    cmyk.w = min(cmyk.x, min(cmyk.y, cmyk.z));

    float k = screenDot(pos, mat2(0.707, 0.707, -0.707, 0.707), freq, cmyk.w); // 45°
    float c = screenDot(pos, mat2(0.966, 0.259, -0.259, 0.966), freq, cmyk.x); // 15°
    float m = screenDot(pos, mat2(0.966, -0.259, 0.259, 0.966), freq, cmyk.y); // -15°
    float y = screenDot(pos, mat2(1.0, 0.0, 0.0, 1.0), freq, cmyk.z);          // 0°

    vec3 rgbscreen = 1.0 - vec3(c, m, y);
    rgbscreen = mix(rgbscreen, texcolor, k);   // K dots show the original color

    // original: afwidth = 2 * frequency * length(1 / OutputSize)
    float afwidth = 2.0 * sqrt(2.0) * freq;
    float blend = smoothstep(0.0, 1.0, afwidth);
    vec3 rgb = mix(rgbscreen, texcolor, blend);

    // make blacks actually black (opaque, not transparent)
    float maxc = max(texcolor.r, max(texcolor.g, texcolor.b));
    rgb = maxc < 0.01 ? vec3(0.0) : rgb;

    fragColor = vec4(rgb * alpha, alpha);
}