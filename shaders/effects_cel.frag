#version 460 core
precision highp float;

// SPDX-FileCopyrightText: Andreas Kruschinski
// SPDX-License-Identifier: AGPL-3.0-or-later

// Cel shading: the original colors with adjustable saturation, and a sharp black line between cells of
// different hues. Inspired by "Advanced Cartoon" from the libretro slang shaders.

#include <flutter/runtime_effect.glsl>

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

uniform float uOutlineWidth;      // 0 .. 4, in output pixels, 0 = no outline
uniform float uOutlineStrength;   // 0 .. 1, opacity of the outline
uniform float uThreshold;         // 0 .. 0.5, neighbors closer than this in color belong to the same cell
uniform float uSaturation;        // 0 .. 2, 1 = the original colors

uniform sampler2D uSource;

out vec4 fragColor;

const vec3 luma = vec3(0.299, 0.587, 0.114);

// unpremultiplied color and alpha of a source pixel
vec4 sourcePixel(vec2 texel)
{
    vec2 uv = (texel + 0.5) / uSourceSize;
    uv.y = mix(uv.y, 1.0 - uv.y, uFlipY);
    vec4 s = texture(uSource, uv);
    return vec4(s.a > 0.0 ? s.rgb / s.a : vec3(0.0), s.a);
}

// hue (0 .. 1), saturation and value
vec3 hsv(vec3 c)
{
    float maxC = max(c.r, max(c.g, c.b));
    float delta = maxC - min(c.r, min(c.g, c.b));
    float h = 0.0;
    if (delta > 0.0)
    {
        if (maxC == c.r)
        {
            h = (c.g - c.b) / delta;
        }
        else if (maxC == c.g)
        {
            h = 2.0 + (c.b - c.r) / delta;
        }
        else
        {
            h = 4.0 + (c.r - c.g) / delta;
        }
        h = fract(h / 6.0);
    }
    return vec3(h, maxC > 0.0 ? delta / maxC : 0.0, maxC);
}

// mostly hue and saturation; brightness counts a quarter, so the shades of one color stay one cell,
// and hue and saturation fade out towards black, where they cannot be seen
float colorDistance(vec3 a, vec3 b)
{
    vec3 ha = hsv(a);
    vec3 hb = hsv(b);
    float hueDiff = abs(ha.x - hb.x);
    hueDiff = 2.0 * min(hueDiff, 1.0 - hueDiff);
    float visible = max(ha.z, hb.z);
    float hue = hueDiff * min(ha.y, hb.y) * visible;
    float sat = abs(ha.y - hb.y) * visible;
    float value = 0.25 * abs(ha.z - hb.z);
    return sqrt(hue * hue + sat * sat + value * value);
}

bool isTransparent(vec4 p)
{
    return p.a < 0.5;
}

bool sameCell(vec4 a, vec4 b)
{
    if (isTransparent(a) || isTransparent(b))
    {
        return isTransparent(a) && isTransparent(b);
    }
    return colorDistance(a.rgb, b.rgb) <= uThreshold;
}

// the line between two cells goes into the darker one, never onto transparency; ties go to the cell
// left of or above the boundary, which is the current one when the neighbor lies in direction [dir]
bool ownsLine(vec4 self, vec4 other, vec2 dir)
{
    if (isTransparent(self))
    {
        return false;
    }
    if (isTransparent(other))
    {
        return true;
    }
    float diff = dot(self.rgb, luma) - dot(other.rgb, luma);
    if (abs(diff) > 0.0001)
    {
        return diff < 0.0;
    }
    return dir.x + dir.y > 0.0;
}

void main()
{
    vec2 q = FlutterFragCoord().xy + uOffset;
    vec2 texel = floor(q / uScale);
    vec4 self = sourcePixel(texel);

    // a pixel is on the line when a different cell lies within the outline width, seen from its centre
    float width = min(max(floor(uOutlineWidth + 0.5), 0.0), uScale);
    float line = 0.0;
    if (width > 0.0)
    {
        for (int y = -1; y <= 1; y++)
        {
            for (int x = -1; x <= 1; x++)
            {
                vec2 dir = vec2(float(x), float(y));
                vec2 other = floor((q + dir * width) / uScale);
                if (other != texel)
                {
                    vec4 neighbor = sourcePixel(other);
                    if (!sameCell(self, neighbor) && ownsLine(self, neighbor, dir))
                    {
                        line = 1.0;
                    }
                }
            }
        }
    }

    vec3 color = clamp(mix(vec3(dot(self.rgb, luma)), self.rgb, max(uSaturation, 0.0)), 0.0, 1.0);
    vec3 rgb = mix(color, vec3(0.0), line * clamp(uOutlineStrength, 0.0, 1.0));
    fragColor = vec4(rgb * self.a, self.a);
}
