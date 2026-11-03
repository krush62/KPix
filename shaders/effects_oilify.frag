#version 460 core
precision highp float;

// SPDX-FileCopyrightText: Andreas Kruschinski
// SPDX-License-Identifier: AGPL-3.0-or-later

// Oilify, after the filter in GIMP: every output pixel sorts the pixels within the radius into intensity
// bins and averages the bins, weighted by (bin size / largest bin)^exponent, so the most common intensity
// wins and details smaller than the radius melt into their surroundings.

#include <flutter/runtime_effect.glsl>

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

uniform float uRadius;          // 1 .. 25, in output pixels, at most 3 source pixels
uniform float uExponent;        // 1 .. 20, 1 = plain average, higher = the most common intensity takes over
uniform float uIntensities;     // 8 .. 256, number of bins
uniform float uIntensityMode;   // 1 = bins by brightness, colors stay whole; 0 = every channel on its own

uniform sampler2D uSource;

out vec4 fragColor;

// a radius of at most 3 source pixels touches at most 7 x 7 of them; no arrays, GLSL ES 1.00 cannot initialize them
const int MAX_CELLS = 49;
const int MAX_ROWS = 51;

const vec3 luma = vec3(0.299, 0.587, 0.114);

// premultiplied source pixel
vec4 tap(vec2 texel)
{
    vec2 uv = (texel + 0.5) / uSourceSize;
    uv.y = mix(uv.y, 1.0 - uv.y, uFlipY);
    return texture(uSource, uv);
}

// source pixel [index] of the box that starts at [first] and is [side] source pixels wide
vec2 cellAt(int index, vec2 first, vec2 side)
{
    float row = floor((float(index) + 0.5) / side.x);
    return first + vec2(float(index) - row * side.x, row);
}

// 1 when an output pixel of [cell] lies within [radius] of [pixel]
float inMask(vec2 cell, vec2 pixel, float radius)
{
    if (any(lessThan(cell, vec2(0.0))) || any(greaterThanEqual(cell, uSourceSize)))
    {
        return 0.0;
    }
    vec2 d = clamp(pixel, cell * uScale, cell * uScale + uScale - 1.0) - pixel;
    return dot(d, d) <= radius * radius ? 1.0 : 0.0;
}

// number of output pixels of [cell] within [radius] of [pixel], like the round mask in GIMP
float coverage(vec2 cell, vec2 pixel, float radius)
{
    vec2 low = max(cell * uScale, pixel - radius);
    vec2 high = min(cell * uScale + uScale - 1.0, pixel + radius);
    float count = 0.0;
    for (int r = 0; r < MAX_ROWS; r++)
    {
        float y = low.y + float(r);
        if (y > high.y)
        {
            break;
        }
        float dy = y - pixel.y;
        float halfWidth = floor(sqrt(radius * radius - dy * dy) + 0.001);
        count += max(min(high.x, pixel.x + halfWidth) - max(low.x, pixel.x - halfWidth) + 1.0, 0.0);
    }
    return count;
}

vec4 straightOf(vec4 s)
{
    return vec4(s.a > 0.0 ? s.rgb / s.a : vec3(0.0), s.a);
}

// per channel; in intensity mode all four are the brightness bin, and transparency gets a bin of its own
vec4 binOf(vec4 s)
{
    float levels = max(floor(uIntensities + 0.5), 2.0) - 1.0;
    vec4 straight = straightOf(s);
    if (uIntensityMode > 0.5)
    {
        return vec4(s.a > 0.0 ? floor(dot(straight.rgb, luma) * levels + 0.5) : -1.0);
    }
    return floor(straight * levels + 0.5);
}

vec4 sameBin(vec4 a, vec4 b)
{
    return step(abs(a - b), vec4(0.5));
}

void main()
{
    vec2 pixel = floor(FlutterFragCoord().xy + uOffset);
    float radius = clamp(floor(uRadius + 0.5), 1.0, min(25.0, 3.0 * uScale));
    float power = max(uExponent, 1.0);
    bool intensityMode = uIntensityMode > 0.5;
    // intensity mode averages premultiplied colors; per channel the colors are straight and count by alpha, so
    // transparency does not vote for black
    vec4 colorVotes = intensityMode ? vec4(1.0) : vec4(0.0, 0.0, 0.0, 1.0);

    // +0.5 keeps exact multiples of the scale away from the floor
    vec2 first = floor((pixel - radius + 0.5) / uScale);
    vec2 side = floor((pixel + radius + 0.5) / uScale) - first + 1.0;
    int cells = int(side.x * side.y + 0.5);

    // every bin is counted at the first source pixel under the mask that falls into it; the weights are kept
    // relative to the largest bin so far, so they cannot overflow
    vec4 largest = vec4(0.0);
    vec4 sum = vec4(0.0);
    vec4 weightSum = vec4(0.0);
    for (int i = 0; i < MAX_CELLS; i++)
    {
        if (i >= cells)
        {
            break;
        }
        vec2 cell = cellAt(i, first, side);
        if (inMask(cell, pixel, radius) <= 0.0)
        {
            continue;
        }
        vec4 bin = binOf(tap(cell));

        // channels whose bin an earlier pixel has counted already
        vec4 seen = vec4(0.0);
        for (int j = 0; j < MAX_CELLS; j++)
        {
            if (max(step(float(i), float(j)), min(min(seen.r, seen.g), min(seen.b, seen.a))) > 0.5)
            {
                break;
            }
            vec2 other = cellAt(j, first, side);
            seen = max(seen, inMask(other, pixel, radius) * sameBin(binOf(tap(other)), bin));
        }
        vec4 fresh = 1.0 - seen;
        if (max(max(fresh.r, fresh.g), max(fresh.b, fresh.a)) <= 0.0)
        {
            continue;
        }

        vec4 count = vec4(0.0);
        vec4 valueSum = vec4(0.0);
        for (int j = 0; j < MAX_CELLS; j++)
        {
            if (j >= cells)
            {
                break;
            }
            vec2 other = cellAt(j, first, side);
            if (j < i || inMask(other, pixel, radius) <= 0.0)
            {
                continue;
            }
            vec4 s = tap(other);
            vec4 member = fresh * sameBin(binOf(s), bin);
            if (max(max(member.r, member.g), max(member.b, member.a)) > 0.0)
            {
                vec4 vote = member * coverage(other, pixel, radius) * max(colorVotes, vec4(s.a));
                count += vote;
                valueSum += vote * (intensityMode ? s : straightOf(s));
            }
        }

        vec4 top = max(largest, count);
        vec4 shrink = pow(max(largest, 1e-6) / max(top, 1e-6), vec4(power));
        vec4 weight = sign(count) * pow(max(count, 1e-6) / max(top, 1e-6), vec4(power));
        sum = sum * shrink + weight * valueSum / max(count, 1e-6);
        weightSum = weightSum * shrink + weight;
        largest = top;
    }

    vec4 result = sum / max(weightSum, vec4(1e-6));
    fragColor = intensityMode ? result : vec4(result.rgb * result.a, result.a);
}
