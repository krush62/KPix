#version 460 core
precision highp float;

// SPDX-FileCopyrightText: 2023 gizmo98
// SPDX-License-Identifier: GPL-2.0-or-later

/*
 * gizmo98 bayer dithering shader
 * Copyright (C) 2023 gizmo98
 * GPL-2.0-or-later – https://github.com/gizmo98/gizmo-crt-shader
 * Ported to Flutter: EGA palette removed, variable Bayer matrix size.
 */

#include <flutter/runtime_effect.glsl>

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

uniform float uColorDepth;   // 1.0 .. 8.0 (bits per channel)
uniform float uDitherTune;   // -64.0 .. 64.0
uniform float uBayerLevel;   // 1 = 2x2, 2 = 4x4, 3 = 8x8, 4 = 16x16

uniform sampler2D uSource;

out vec4 fragColor;

const int MAX_BITS = 4;      // 2^4 = 16x16 maximum

float bitAt(float n, float k)
{
    return mod(floor(n / k), 2.0);
}

// Bayer matrix value for a (2^bits) x (2^bits) matrix, range 0 .. n*n-1
float bayer(float x, float y, float bits)
{
    float value = 0.0;
    float bitWeight = 1.0;                        // 2^i
    float outWeight = pow(4.0, bits - 1.0);       // 4^(bits-1-i)

    for (int i = 0; i < MAX_BITS; i++)
    {
        if (float(i) < bits)
        {
            float xi = bitAt(x, bitWeight);
            float yi = bitAt(y, bitWeight);
            value += (2.0 * abs(xi - yi) + xi) * outWeight;
            bitWeight *= 2.0;
            outWeight /= 4.0;
        }
    }
    return value;
}

vec3 ditherPattern(vec3 rgb, vec2 coord)
{
    float bits = clamp(floor(uBayerLevel + 0.5), 1.0, float(MAX_BITS));
    float n = pow(2.0, bits);

    vec2 st = floor(mod(coord, n));
    float threshold = bayer(st.x, st.y, bits);

    float multiplier = pow(2.0, 8.0 - uColorDepth) - 1.0;
    threshold = (threshold / (n * n - 1.0)) - 0.5;
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