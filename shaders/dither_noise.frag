#version 460 core
precision highp float;

// SPDX-FileCopyrightText: 2023 gizmo98
// SPDX-License-Identifier: GPL-2.0-or-later

/*
 * gizmo98 blue noise dithering shader
 * Copyright (C) 2023 gizmo98
 * GPL-2.0-or-later – https://github.com/gizmo98/gizmo-crt-shader
 * Ported to Flutter: EGA palette and monochrome mode removed, blue noise
 * texture replaced by procedural high-pass filtered white noise.
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

// white noise in [0, 1), hash without sine (Dave Hoskins)
float hash13(vec3 p)
{
    vec3 p3 = fract(p * 0.1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

// approximate blue noise in [0, 1]
float blueNoise(vec2 p, float seed)
{
    float center = hash13(vec3(p, seed));

    float sum = 0.0;
    sum += hash13(vec3(p + vec2(-1.0, -1.0), seed));
    sum += hash13(vec3(p + vec2( 0.0, -1.0), seed));
    sum += hash13(vec3(p + vec2( 1.0, -1.0), seed));
    sum += hash13(vec3(p + vec2(-1.0,  0.0), seed));
    sum += hash13(vec3(p + vec2( 1.0,  0.0), seed));
    sum += hash13(vec3(p + vec2(-1.0,  1.0), seed));
    sum += hash13(vec3(p + vec2( 0.0,  1.0), seed));
    sum += hash13(vec3(p + vec2( 1.0,  1.0), seed));

    // high-pass: remove low frequencies, zero mean, std dev ~0.306
    float v = center - sum / 8.0;

    // map approx. normal distribution to uniform (logistic CDF approximation)
    return 1.0 / (1.0 + exp(-5.5587 * v));
}

vec3 ditherPattern(vec3 rgb, vec2 texel)
{
    vec3 noise;
    noise.r = blueNoise(texel, 1.0);
    noise.g = blueNoise(texel, 2.0);
    noise.b = blueNoise(texel, 3.0);

    float multiplier = pow(2.0, 8.0 - uColorDepth) - 1.0;
    vec3 threshold = (noise - 0.5) * ((multiplier + uDitherTune) / 255.0);
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

    rgb = ditherPattern(rgb, texel);
    rgb = clamp(colorDepthReduction(rgb), 0.0, 1.0);

    fragColor = vec4(rgb * alpha, alpha);
}