#version 460 core
precision highp float;

// SPDX-FileCopyrightText: 2015-2016 Lior Halphon
// SPDX-License-Identifier: MIT

#include <flutter/runtime_effect.glsl>

// OmniScale by Lior Halphon, ported from the libretro slang version (ported to slang by hunterk).
// KPix changes: texel taps instead of texture offsets, the bit pattern as 0/1 vectors
// (the Skia backend has no bitwise operations), alpha counts as a difference, and the color
// thresholds blend from SameBoy's original ones (uTolerance 0) to the looser ones of the libretro port (1).

/*
MIT License

Copyright (c) 2015-2016 Lior Halphon

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

uniform float uTolerance;

uniform sampler2D uSource;

out vec4 fragColor;

vec4 tap(vec2 texel)
{
    vec2 uv = (texel + 0.5) / uSourceSize;
    uv.y = mix(uv.y, 1.0 - uv.y, uFlipY);
    return texture(uSource, uv);
}

/* We use the same colorspace as the HQ algorithms. */
vec3 rgb_to_hq_colospace(vec4 rgb)
{
    return vec3( 0.250 * rgb.r + 0.250 * rgb.g + 0.250 * rgb.b,
                 0.250 * rgb.r - 0.000 * rgb.g - 0.250 * rgb.b,
                -0.125 * rgb.r + 0.250 * rgb.g - 0.125 * rgb.b);
}

bool is_different(vec4 a, vec4 b)
{
    vec3 threshold = mix(vec3(0.018, 0.002, 0.005), vec3(0.125, 0.027, 0.031), uTolerance);
    vec3 diff = abs(rgb_to_hq_colospace(a) - rgb_to_hq_colospace(b));
    return diff.x > threshold.x || diff.y > threshold.y || diff.z > threshold.z || abs(a.a - b.a) > threshold.x;
}

// (pattern & m) == r, with the bits of m and r decoded by float arithmetic
bool matches(vec4 pa, vec4 pb, float m, float r)
{
    vec4 low = vec4(1.0, 2.0, 4.0, 8.0);
    vec4 high = vec4(16.0, 32.0, 64.0, 128.0);
    vec4 maskA = mod(floor(vec4(m) / low), 2.0);
    vec4 maskB = mod(floor(vec4(m) / high), 2.0);
    vec4 resultA = mod(floor(vec4(r) / low), 2.0);
    vec4 resultB = mod(floor(vec4(r) / high), 2.0);
    return all(equal(pa * maskA, resultA)) && all(equal(pb * maskB, resultB));
}

#define P(m, r) matches(pa, pb, float(m), float(r))

/* We always calculate the top left quarter. [dir] flips the neighbours for the other quarters, [p] is the mirrored position in the pixel. */
vec4 scale(vec2 texel, vec2 dir, vec2 p)
{
    vec4 w0 = tap(texel + vec2(-1.0, -1.0) * dir);
    vec4 w1 = tap(texel + vec2(0.0, -1.0) * dir);
    vec4 w2 = tap(texel + vec2(1.0, -1.0) * dir);
    vec4 w3 = tap(texel + vec2(-1.0, 0.0) * dir);
    vec4 w4 = tap(texel + vec2(0.0, 0.0) * dir);
    vec4 w5 = tap(texel + vec2(1.0, 0.0) * dir);
    vec4 w6 = tap(texel + vec2(-1.0, 1.0) * dir);
    vec4 w7 = tap(texel + vec2(0.0, 1.0) * dir);
    vec4 w8 = tap(texel + vec2(1.0, 1.0) * dir);

    // bit i of the HQx pattern is component i % 4 of pa (i < 4) or pb
    vec4 pa = vec4(is_different(w0, w4), is_different(w1, w4), is_different(w2, w4), is_different(w3, w4));
    vec4 pb = vec4(is_different(w5, w4), is_different(w6, w4), is_different(w7, w4), is_different(w8, w4));

    if ((P(0xbf,0x37) || P(0xdb,0x13)) && is_different(w1, w5))
        return mix(w4, w3, 0.5 - p.x);
    if ((P(0xdb,0x49) || P(0xef,0x6d)) && is_different(w7, w3))
        return mix(w4, w1, 0.5 - p.y);
    if ((P(0x0b,0x0b) || P(0xfe,0x4a) || P(0xfe,0x1a)) && is_different(w3, w1))
        return w4;
    if ((P(0x6f,0x2a) || P(0x5b,0x0a) || P(0xbf,0x3a) || P(0xdf,0x5a) ||
         P(0x9f,0x8a) || P(0xcf,0x8a) || P(0xef,0x4e) || P(0x3f,0x0e) ||
         P(0xfb,0x5a) || P(0xbb,0x8a) || P(0x7f,0x5a) || P(0xaf,0x8a) ||
         P(0xeb,0x8a)) && is_different(w3, w1))
        return mix(w4, mix(w4, w0, 0.5 - p.x), 0.5 - p.y);
    if (P(0x0b,0x08))
        return mix(mix(w0 * 0.375 + w1 * 0.25 + w4 * 0.375, w4 * 0.5 + w1 * 0.5, p.x * 2.0), w4, p.y * 2.0);
    if (P(0x0b,0x02))
        return mix(mix(w0 * 0.375 + w3 * 0.25 + w4 * 0.375, w4 * 0.5 + w3 * 0.5, p.y * 2.0), w4, p.x * 2.0);
    if (P(0x2f,0x2f)) {
        float dist = length(p - vec2(0.5));
        float pixel_size = length(vec2(1.0 / uScale));
        if (dist < 0.5 - pixel_size / 2.0) {
            return w4;
        }
        vec4 r;
        if (is_different(w0, w1) || is_different(w0, w3)) {
            r = mix(w1, w3, p.y - p.x + 0.5);
        }
        else {
            r = mix(mix(w1 * 0.375 + w0 * 0.25 + w3 * 0.375, w3, p.y * 2.0), w1, p.x * 2.0);
        }

        if (dist > 0.5 + pixel_size / 2.0) {
            return r;
        }
        return mix(w4, r, (dist - 0.5 + pixel_size / 2.0) / pixel_size);
    }
    if (P(0xbf,0x37) || P(0xdb,0x13)) {
        float dist = p.x - 2.0 * p.y;
        float pixel_size = length(vec2(1.0 / uScale)) * sqrt(5.0);
        if (dist > pixel_size / 2.0) {
            return w1;
        }
        vec4 r = mix(w3, w4, p.x + 0.5);
        if (dist < -pixel_size / 2.0) {
            return r;
        }
        return mix(r, w1, (dist + pixel_size / 2.0) / pixel_size);
    }
    if (P(0xdb,0x49) || P(0xef,0x6d)) {
        float dist = p.y - 2.0 * p.x;
        float pixel_size = length(vec2(1.0 / uScale)) * sqrt(5.0);
        if (p.y - 2.0 * p.x > pixel_size / 2.0) {
            return w3;
        }
        vec4 r = mix(w1, w4, p.x + 0.5);
        if (dist < -pixel_size / 2.0) {
            return r;
        }
        return mix(r, w3, (dist + pixel_size / 2.0) / pixel_size);
    }
    if (P(0xbf,0x8f) || P(0x7e,0x0e)) {
        float dist = p.x + 2.0 * p.y;
        float pixel_size = length(vec2(1.0 / uScale)) * sqrt(5.0);

        if (dist > 1.0 + pixel_size / 2.0) {
            return w4;
        }

        vec4 r;
        if (is_different(w0, w1) || is_different(w0, w3)) {
            r = mix(w1, w3, p.y - p.x + 0.5);
        }
        else {
            r = mix(mix(w1 * 0.375 + w0 * 0.25 + w3 * 0.375, w3, p.y * 2.0), w1, p.x * 2.0);
        }

        if (dist < 1.0 - pixel_size / 2.0) {
            return r;
        }

        return mix(r, w4, (dist + pixel_size / 2.0 - 1.0) / pixel_size);

    }

    if (P(0x7e,0x2a) || P(0xef,0xab)) {
        float dist = p.y + 2.0 * p.x;
        float pixel_size = length(vec2(1.0 / uScale)) * sqrt(5.0);

        if (p.y + 2.0 * p.x > 1.0 + pixel_size / 2.0) {
            return w4;
        }

        vec4 r;

        if (is_different(w0, w1) || is_different(w0, w3)) {
            r = mix(w1, w3, p.y - p.x + 0.5);
        }
        else {
            r = mix(mix(w1 * 0.375 + w0 * 0.25 + w3 * 0.375, w3, p.y * 2.0), w1, p.x * 2.0);
        }

        if (dist < 1.0 - pixel_size / 2.0) {
            return r;
        }

        return mix(r, w4, (dist + pixel_size / 2.0 - 1.0) / pixel_size);
    }

    if (P(0x1b,0x03) || P(0x4f,0x43) || P(0x8b,0x83) || P(0x6b,0x43))
        return mix(w4, w3, 0.5 - p.x);

    if (P(0x4b,0x09) || P(0x8b,0x89) || P(0x1f,0x19) || P(0x3b,0x19))
        return mix(w4, w1, 0.5 - p.y);

    if (P(0xfb,0x6a) || P(0x6f,0x6e) || P(0x3f,0x3e) || P(0xfb,0xfa) ||
        P(0xdf,0xde) || P(0xdf,0x1e))
        return mix(w4, w0, (1.0 - p.x - p.y) / 2.0);

    if (P(0x4f,0x4b) || P(0x9f,0x1b) || P(0x2f,0x0b) ||
        P(0xbe,0x0a) || P(0xee,0x0a) || P(0x7e,0x0a) || P(0xeb,0x4b) ||
        P(0x3b,0x1b)) {
        float dist = p.x + p.y;
        float pixel_size = length(vec2(1.0 / uScale));

        if (dist > 0.5 + pixel_size / 2.0) {
            return w4;
        }

        vec4 r;
        if (is_different(w0, w1) || is_different(w0, w3)) {
            r = mix(w1, w3, p.y - p.x + 0.5);
        }
        else {
            r = mix(mix(w1 * 0.375 + w0 * 0.25 + w3 * 0.375, w3, p.y * 2.0), w1, p.x * 2.0);
        }

        if (dist < 0.5 - pixel_size / 2.0) {
            return r;
        }

        return mix(r, w4, (dist + pixel_size / 2.0 - 0.5) / pixel_size);
    }

    if (P(0x0b,0x01))
        return mix(mix(w4, w3, 0.5 - p.x), mix(w1, (w1 + w3) / 2.0, 0.5 - p.x), 0.5 - p.y);

    if (P(0x0b,0x00))
        return mix(mix(w4, w3, 0.5 - p.x), mix(w1, w0, 0.5 - p.x), 0.5 - p.y);

    float dist = p.x + p.y;
    float pixel_size = length(vec2(1.0 / uScale));

    if (dist > 0.5 + pixel_size / 2.0)
        return w4;

    /* We need more samples to "solve" this diagonal */
    vec4 x0 = tap(texel + vec2(-2.0, -2.0) * dir);
    vec4 x1 = tap(texel + vec2(-1.0, -2.0) * dir);
    vec4 x2 = tap(texel + vec2(0.0, -2.0) * dir);
    vec4 x3 = tap(texel + vec2(1.0, -2.0) * dir);
    vec4 x4 = tap(texel + vec2(-2.0, -1.0) * dir);
    vec4 x5 = tap(texel + vec2(-2.0, 0.0) * dir);
    vec4 x6 = tap(texel + vec2(-2.0, 1.0) * dir);

    float extra = float(is_different(x0, w4)) + float(is_different(x1, w4)) + float(is_different(x2, w4)) + float(is_different(x3, w4))
                + float(is_different(x4, w4)) + float(is_different(x5, w4)) + float(is_different(x6, w4));
    float diagonal_bias = dot(pa, vec4(1.0)) + dot(pb, vec4(1.0)) + extra - 7.0;

    if (diagonal_bias <= 0.0) {
        vec4 r = mix(w1, w3, p.y - p.x + 0.5);
        if (dist < 0.5 - pixel_size / 2.0) {
            return r;
        }
        return mix(r, w4, (dist + pixel_size / 2.0 - 0.5) / pixel_size);
    }
    
    return w4;
}

void main()
{
    vec2 position = (FlutterFragCoord().xy + uOffset) / uScale;
    vec2 texel = floor(position);
    vec2 p = fract(position);
    vec2 dir = vec2(1.0);
    // upstream nudges coordinates by *1.0001, so a pixel centre counts as the bottom right quarter
    if (p.x >= 0.5) {
        dir.x = -1.0;
        p.x = 1.0 - p.x;
    }
    if (p.y >= 0.5) {
        dir.y = -1.0;
        p.y = 1.0 - p.y;
    }
    fragColor = scale(texel, dir, p);
}
