#version 460 core
precision highp float;

/*
   Bead shader
   Author: Themaister
   License: Public domain
   Ported to Flutter, with background color controls.
*/

#include <flutter/runtime_effect.glsl>

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

uniform float uBeadHigh;              // 0 .. 0.71, outer radius in cells (0.71 reaches the corners), default 0.45
uniform float uBeadLow;               // 0 .. 0.71, inner radius (hole), default 0.15
uniform float uBeadSharp;             // 1 .. 20, falloff sharpness, default 5 (the original's exp(-12 * len))
uniform float uBackgroundBrightness;  // 0 .. 1, 0 = black (original)
uniform float uBackgroundWarmth;      // -1 .. 1, cool .. neutral .. warm

uniform sampler2D uSource;

out vec4 fragColor;

// exponential slider: 1 -> 3 (soft glow) .. 5 -> 12 .. 20 -> ~2200 (hard edge)
float rolloff(float len)
{
    return exp(-3.0 * exp2((uBeadSharp - 1.0) * 0.5) * len);
}

// 1.0 on the bead ring, fading towards the hole and the outside
float beadMask(vec2 local)
{
    float delta = length(local - 0.5);
    float low = min(uBeadLow, uBeadHigh);
    if (delta >= uBeadHigh)
    {
        return rolloff(delta - uBeadHigh);
    }
    if (delta <= low)
    {
        return rolloff(low - delta);
    }
    return 1.0;
}

// beadMask averaged over 4x4 points of the output pixel, so sharp edges come out antialiased instead of jagged
float beadCoverage(vec2 local)
{
    float spacing = 1.0 / (4.0 * uScale);
    float sum = 0.0;
    for (int y = 0; y < 4; y++)
    {
        for (int x = 0; x < 4; x++)
        {
            sum += beadMask(local + (vec2(float(x), float(y)) - 1.5) * spacing);
        }
    }
    return sum / 16.0;
}

vec3 backgroundColor()
{
    float w = clamp(uBackgroundWarmth, -1.0, 1.0);
    vec3 warm = vec3(1.0, 0.94, 0.80);
    vec3 cool = vec3(0.85, 0.93, 1.0);
    vec3 tint = w >= 0.0 ? mix(vec3(1.0), warm, w) : mix(vec3(1.0), cool, -w);
    return tint * clamp(uBackgroundBrightness, 0.0, 1.0);
}

void main()
{
    vec2 pos = FlutterFragCoord().xy + uOffset;
    vec2 cellPos = pos / uScale;
    vec2 texel = floor(cellPos);
    vec2 local = cellPos - texel;   // 0..1 inside the bead cell

    vec2 uv = (texel + 0.5) / uSourceSize;
    uv.y = mix(uv.y, 1.0 - uv.y, uFlipY);

    vec4 src = texture(uSource, uv);

    float alpha = src.a;
    vec3 color = alpha > 0.0 ? src.rgb / alpha : vec3(0.0);

    vec3 rgb = mix(backgroundColor(), color, beadCoverage(local));

    fragColor = vec4(rgb * alpha, alpha);
}