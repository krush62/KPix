#version 460 core
precision highp float;

// Color manipulation: adjustments -> color reduction -> palette mapping.

#include <flutter/runtime_effect.glsl>

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

uniform float uPalette;       // 0 = off, 1 = CGA, 2 = EGA, 3 = PICO-8, 4 = Game Boy, 5 = C64, 6 = ZX Spectrum
uniform float uColorDepth;    // 1 .. 8 bits per channel, 8 = off
uniform float uBrightness;    // -1 .. 1, default 0
uniform float uContrast;      // 0 .. 2, default 1
uniform float uSaturation;    // 0 .. 2, default 1 (0 = grayscale)
uniform float uTemperature;   // -1 .. 1, default 0 (negative = cooler, positive = warmer)
uniform float uTint;          // -1 .. 1, default 0 (negative = green, positive = magenta)

uniform sampler2D uSource;

out vec4 fragColor;

const int MAX_PALETTE = 16;

// palette entry [i] of palette [p] (1-based), 8-bit values
vec3 paletteColor(int p, int i)
{
    if (p == 1)   // CGA
    {
        if (i == 0) return vec3(0.0, 0.0, 0.0) / 255.0;   // #000000
        if (i == 1) return vec3(85.0, 255.0, 255.0) / 255.0;   // #55FFFF
        if (i == 2) return vec3(255.0, 85.0, 255.0) / 255.0;   // #FF55FF
        if (i == 3) return vec3(255.0, 255.0, 255.0) / 255.0;   // #FFFFFF
    }
    if (p == 2)   // EGA
    {
        if (i == 0) return vec3(0.0, 0.0, 0.0) / 255.0;   // #000000
        if (i == 1) return vec3(0.0, 0.0, 170.0) / 255.0;   // #0000AA
        if (i == 2) return vec3(0.0, 170.0, 0.0) / 255.0;   // #00AA00
        if (i == 3) return vec3(0.0, 170.0, 170.0) / 255.0;   // #00AAAA
        if (i == 4) return vec3(170.0, 0.0, 0.0) / 255.0;   // #AA0000
        if (i == 5) return vec3(170.0, 0.0, 170.0) / 255.0;   // #AA00AA
        if (i == 6) return vec3(170.0, 85.0, 0.0) / 255.0;   // #AA5500
        if (i == 7) return vec3(170.0, 170.0, 170.0) / 255.0;   // #AAAAAA
        if (i == 8) return vec3(85.0, 85.0, 85.0) / 255.0;   // #555555
        if (i == 9) return vec3(85.0, 85.0, 255.0) / 255.0;   // #5555FF
        if (i == 10) return vec3(85.0, 255.0, 85.0) / 255.0;   // #55FF55
        if (i == 11) return vec3(85.0, 255.0, 255.0) / 255.0;   // #55FFFF
        if (i == 12) return vec3(255.0, 85.0, 85.0) / 255.0;   // #FF5555
        if (i == 13) return vec3(255.0, 85.0, 255.0) / 255.0;   // #FF55FF
        if (i == 14) return vec3(255.0, 255.0, 85.0) / 255.0;   // #FFFF55
        if (i == 15) return vec3(255.0, 255.0, 255.0) / 255.0;   // #FFFFFF
    }
    if (p == 3)   // PICO-8
    {
        if (i == 0) return vec3(0.0, 0.0, 0.0) / 255.0;   // #000000
        if (i == 1) return vec3(29.0, 43.0, 83.0) / 255.0;   // #1D2B53
        if (i == 2) return vec3(126.0, 37.0, 83.0) / 255.0;   // #7E2553
        if (i == 3) return vec3(0.0, 135.0, 81.0) / 255.0;   // #008751
        if (i == 4) return vec3(171.0, 82.0, 54.0) / 255.0;   // #AB5236
        if (i == 5) return vec3(95.0, 87.0, 79.0) / 255.0;   // #5F574F
        if (i == 6) return vec3(194.0, 195.0, 199.0) / 255.0;   // #C2C3C7
        if (i == 7) return vec3(255.0, 241.0, 232.0) / 255.0;   // #FFF1E8
        if (i == 8) return vec3(255.0, 0.0, 77.0) / 255.0;   // #FF004D
        if (i == 9) return vec3(255.0, 163.0, 0.0) / 255.0;   // #FFA300
        if (i == 10) return vec3(255.0, 236.0, 39.0) / 255.0;   // #FFEC27
        if (i == 11) return vec3(0.0, 228.0, 54.0) / 255.0;   // #00E436
        if (i == 12) return vec3(41.0, 173.0, 255.0) / 255.0;   // #29ADFF
        if (i == 13) return vec3(131.0, 118.0, 156.0) / 255.0;   // #83769C
        if (i == 14) return vec3(255.0, 119.0, 168.0) / 255.0;   // #FF77A8
        if (i == 15) return vec3(255.0, 204.0, 170.0) / 255.0;   // #FFCCAA
    }
    if (p == 4)   // Game Boy
    {
        if (i == 0) return vec3(15.0, 56.0, 15.0) / 255.0;   // #0F380F
        if (i == 1) return vec3(48.0, 98.0, 48.0) / 255.0;   // #306230
        if (i == 2) return vec3(139.0, 172.0, 15.0) / 255.0;   // #8BAC0F
        if (i == 3) return vec3(155.0, 188.0, 15.0) / 255.0;   // #9BBC0F
    }
    if (p == 5)   // C64
    {
        if (i == 0) return vec3(0.0, 0.0, 0.0) / 255.0;   // #000000
        if (i == 1) return vec3(255.0, 255.0, 255.0) / 255.0;   // #FFFFFF
        if (i == 2) return vec3(104.0, 55.0, 43.0) / 255.0;   // #68372B
        if (i == 3) return vec3(112.0, 164.0, 178.0) / 255.0;   // #70A4B2
        if (i == 4) return vec3(111.0, 61.0, 134.0) / 255.0;   // #6F3D86
        if (i == 5) return vec3(88.0, 141.0, 67.0) / 255.0;   // #588D43
        if (i == 6) return vec3(53.0, 40.0, 121.0) / 255.0;   // #352879
        if (i == 7) return vec3(184.0, 199.0, 111.0) / 255.0;   // #B8C76F
        if (i == 8) return vec3(111.0, 79.0, 37.0) / 255.0;   // #6F4F25
        if (i == 9) return vec3(67.0, 57.0, 0.0) / 255.0;   // #433900
        if (i == 10) return vec3(154.0, 103.0, 89.0) / 255.0;   // #9A6759
        if (i == 11) return vec3(68.0, 68.0, 68.0) / 255.0;   // #444444
        if (i == 12) return vec3(108.0, 108.0, 108.0) / 255.0;   // #6C6C6C
        if (i == 13) return vec3(154.0, 210.0, 132.0) / 255.0;   // #9AD284
        if (i == 14) return vec3(108.0, 94.0, 181.0) / 255.0;   // #6C5EB5
        if (i == 15) return vec3(149.0, 149.0, 149.0) / 255.0;   // #959595
    }
    if (p == 6)   // ZX Spectrum
    {
        if (i == 0) return vec3(0.0, 0.0, 0.0) / 255.0;   // #000000
        if (i == 1) return vec3(0.0, 0.0, 215.0) / 255.0;   // #0000D7
        if (i == 2) return vec3(215.0, 0.0, 0.0) / 255.0;   // #D70000
        if (i == 3) return vec3(215.0, 0.0, 215.0) / 255.0;   // #D700D7
        if (i == 4) return vec3(0.0, 215.0, 0.0) / 255.0;   // #00D700
        if (i == 5) return vec3(0.0, 215.0, 215.0) / 255.0;   // #00D7D7
        if (i == 6) return vec3(215.0, 215.0, 0.0) / 255.0;   // #D7D700
        if (i == 7) return vec3(215.0, 215.0, 215.0) / 255.0;   // #D7D7D7
        if (i == 8) return vec3(0.0, 0.0, 255.0) / 255.0;   // #0000FF
        if (i == 9) return vec3(255.0, 0.0, 0.0) / 255.0;   // #FF0000
        if (i == 10) return vec3(255.0, 0.0, 255.0) / 255.0;   // #FF00FF
        if (i == 11) return vec3(0.0, 255.0, 0.0) / 255.0;   // #00FF00
        if (i == 12) return vec3(0.0, 255.0, 255.0) / 255.0;   // #00FFFF
        if (i == 13) return vec3(255.0, 255.0, 0.0) / 255.0;   // #FFFF00
        if (i == 14) return vec3(255.0, 255.0, 255.0) / 255.0;   // #FFFFFF
    }
    return vec3(0.0);
}

int paletteSize(int p)
{
    if (p == 1) return 4;
    if (p == 2) return 16;
    if (p == 3) return 16;
    if (p == 4) return 4;
    if (p == 5) return 16;
    if (p == 6) return 15;
    return 0;
}

vec3 srgbToLinear(vec3 c)
{
    vec3 lo = c / 12.92;
    vec3 hi = pow((c + 0.055) / 1.055, vec3(2.4));
    return mix(hi, lo, step(c, vec3(0.04045)));
}

// sRGB (gamma encoded) to OKLab, a perceptually uniform space for the nearest-color search
vec3 toOklab(vec3 srgb)
{
    vec3 c = srgbToLinear(clamp(srgb, 0.0, 1.0));
    vec3 lms = vec3(
            0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b,
            0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b,
            0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b);
    lms = pow(max(lms, vec3(0.0)), vec3(1.0 / 3.0));
    return vec3(
            0.2104542553 * lms.x + 0.7936177850 * lms.y - 0.0040720468 * lms.z,
            1.9779984951 * lms.x - 2.4285922050 * lms.y + 0.4505937099 * lms.z,
            0.0259040371 * lms.x + 0.7827717662 * lms.y - 0.8086757660 * lms.z);
}

vec3 adjust(vec3 c)
{
    // white balance: temperature shifts between blue and red/yellow, tint between green and magenta
    float temperature = clamp(uTemperature, -1.0, 1.0);
    float tint = clamp(uTint, -1.0, 1.0);
    c *= vec3(1.0 + 0.2 * temperature, 1.0 + 0.05 * temperature, 1.0 - 0.2 * temperature);
    c *= vec3(1.0 + 0.1 * tint, 1.0 - 0.2 * tint, 1.0 + 0.1 * tint);

    // brightness
    c += clamp(uBrightness, -1.0, 1.0);

    // contrast around mid gray
    c = (c - 0.5) * max(uContrast, 0.0) + 0.5;

    // saturation around the luma (Rec. 709)
    float luma = dot(c, vec3(0.2126, 0.7152, 0.0722));
    c = mix(vec3(luma), c, max(uSaturation, 0.0));

    return clamp(c, 0.0, 1.0);
}

vec3 reduceColors(vec3 c)
{
    float depth = clamp(floor(uColorDepth + 0.5), 1.0, 8.0);
    if (depth >= 8.0)
    {
        return c;
    }
    float levels = pow(2.0, depth) - 1.0;
    return floor(c * levels + 0.5) / levels;
}

vec3 mapToPalette(vec3 c)
{
    int p = int(floor(uPalette + 0.5));
    int size = paletteSize(p);
    if (size == 0)
    {
        return c;
    }
    vec3 lab = toOklab(c);
    vec3 best = c;
    float bestDistance = 1e10;
    for (int i = 0; i < MAX_PALETTE; i++)
    {
        if (i < size)
        {
            vec3 candidate = paletteColor(p, i);
            vec3 d = toOklab(candidate) - lab;
            float distance = dot(d, d);
            if (distance < bestDistance)
            {
                bestDistance = distance;
                best = candidate;
            }
        }
    }
    return best;
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

    rgb = adjust(rgb);
    rgb = reduceColors(rgb);
    rgb = mapToPalette(rgb);

    fragColor = vec4(rgb * alpha, alpha);
}
