#version 460 core
precision highp float;

// SPDX-FileCopyrightText: Andreas Kruschinski
// SPDX-License-Identifier: AGPL-3.0-or-later

// Dither blend: neighboring pixels bleed into each other through a dither pattern.
// Every output pixel shifts its sample position by a dither offset, so the pattern is
// continuous across pixel edges. Only original source pixels are output, no new colors.

#include <flutter/runtime_effect.glsl>

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

uniform float uBleed;       // 0 .. 1, how far a pixel bleeds into its neighbor, in source pixels
uniform float uDitherType;  // 0 = Bayer 8x8, 1 = Bayer 4x4, 2 = Bayer 2x2, 3 = checkerboard, 4 = blue noise

uniform sampler2D uSource;

out vec4 fragColor;

const int MAX_BITS = 3;     // 2^3 = 8x8 maximum

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

// white noise in [0, 1), hash without sine (Dave Hoskins)
float hash13(vec3 p)
{
    vec3 p3 = fract(p * 0.1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

// approximate blue noise in (0, 1): high-pass filtered white noise, mapped to a uniform distribution
float blueNoise(vec2 p)
{
    float center = hash13(vec3(p, 1.0));

    float sum = 0.0;
    sum += hash13(vec3(p + vec2(-1.0, -1.0), 1.0));
    sum += hash13(vec3(p + vec2( 0.0, -1.0), 1.0));
    sum += hash13(vec3(p + vec2( 1.0, -1.0), 1.0));
    sum += hash13(vec3(p + vec2(-1.0,  0.0), 1.0));
    sum += hash13(vec3(p + vec2( 1.0,  0.0), 1.0));
    sum += hash13(vec3(p + vec2(-1.0,  1.0), 1.0));
    sum += hash13(vec3(p + vec2( 0.0,  1.0), 1.0));
    sum += hash13(vec3(p + vec2( 1.0,  1.0), 1.0));

    float v = center - sum / 8.0;
    return 1.0 / (1.0 + exp(-5.5587 * v));
}

// dither threshold in (0, 1) for output pixel p
float threshold(vec2 p)
{
    float type = floor(clamp(uDitherType, 0.0, 4.0) + 0.5);

    if (type < 2.5)
    {
        // Bayer 8x8, 4x4, 2x2
        float bits = 3.0 - type;
        float n = pow(2.0, bits);
        vec2 st = mod(p, n);
        return (bayer(st.x, st.y, bits) + 0.5) / (n * n);
    }
    if (type < 3.5)
    {
        // checkerboard: two thresholds in a strict 1-pixel alternation
        return mod(p.x + p.y, 2.0) < 0.5 ? 0.25 : 0.75;
    }
    return blueNoise(p);
}

// premultiplied source pixel, untouched
vec4 sourcePixel(vec2 texel)
{
    vec2 uv = (texel + 0.5) / uSourceSize;
    uv.y = mix(uv.y, 1.0 - uv.y, uFlipY);
    return texture(uSource, uv);
}

void main()
{
    vec2 pos = FlutterFragCoord().xy + uOffset;
    vec2 cellPos = pos / uScale;

    float bleed = clamp(uBleed, 0.0, 1.0);

    // shift the sample position by the dither offset: the neighbor's share is 50% at the edge
    // and falls linearly to 0% at a distance of uBleed source pixels
    float t = threshold(floor(pos));
    vec2 shifted = cellPos + (t - 0.5) * 2.0 * bleed;

    // outside the image nothing bleeds in: the border stays sharp
    vec2 chosen = clamp(floor(shifted), vec2(0.0), uSourceSize - 1.0);

    fragColor = sourcePixel(chosen);
}