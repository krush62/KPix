#version 460 core
precision highp float;

/*
 * gizmo98 bayer 4x4 dithering shader
 * Copyright (C) 2023 gizmo98
 * GPL-2.0-or-later – https://github.com/gizmo98/gizmo-crt-shader
 * Ported to Flutter (EGA palette removed).
 */

#include <flutter/runtime_effect.glsl>

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

uniform float uColorDepth;   // 1.0 .. 8.0 (bits per channel)
uniform float uDitherTune;   // -64.0 .. 64.0

uniform sampler2D uSource;

out vec4 fragColor;

float bitAt(float n, float k)
{
    return mod(floor(n / k), 2.0);
}

// bayerMatrix[x][y] of the original 4x4 matrix, value 0..15
float bayer4(float x, float y)
{
    float x0 = bitAt(x, 1.0);
    float x1 = bitAt(x, 2.0);
    float y0 = bitAt(y, 1.0);
    float y1 = bitAt(y, 2.0);
    return 8.0 * abs(x0 - y0) + 4.0 * x0 + 2.0 * abs(x1 - y1) + x1;
}

vec3 ditherPattern(vec3 rgb, vec2 coord)
{
    vec2 st = floor(mod(coord, 4.0));
    float threshold = bayer4(st.x, st.y);
    float multiplier = pow(2.0, 8.0 - uColorDepth) - 1.0;
    threshold = (threshold / 15.0) - 0.5;
    threshold *= (multiplier + uDitherTune) / 255.0;
    return rgb + threshold;
}

vec3 colorDepthReduction(vec3 rgb)
{
    float divider = pow(2.0, uColorDepth) - 1.0;
    rgb *= divider;
    rgb = floor(rgb) + step(0.5, fract(rgb));
    return rgb / divider;
}

void main()
{
    vec2 pos = FlutterFragCoord().xy + uOffset;
    vec2 texel = floor(pos / uScale);
    vec2 uv = (texel + 0.5) / uSourceSize;
    uv.y = mix(uv.y, 1.0 - uv.y, uFlipY);

    vec4 src = texture(uSource, uv);

    float alpha = src.a;
    vec3 rgb = alpha > 0.0 ? src.rgb / alpha : vec3(0.0);

    // original: coord = iuv - 0.5
    rgb = ditherPattern(rgb, texel - 0.5);
    rgb = clamp(colorDepthReduction(rgb), 0.0, 1.0);

    fragColor = vec4(rgb * alpha, alpha);
}