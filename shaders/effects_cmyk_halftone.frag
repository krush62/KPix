#version 460 core
precision highp float;

// CMYK halftone dot shader, ported to Flutter, with artistic controls.

#include <flutter/runtime_effect.glsl>

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

uniform float uDotSize;          // 4 .. 32, cell size in output pixels
uniform float uOriginalMix;      // 0 .. 1, share of the original image
uniform float uDotGain;          // 0.5 .. 2, dot radius multiplier
uniform float uSoftness;         // 0 .. 2, edge softness in output pixels
uniform float uDotShape;         // 0 = round, 1 = diamond, 2 = square
uniform float uAngle;            // 0 .. 90, global screen rotation in degrees
uniform float uMisregistration;  // 0 .. 3, C/M/Y layer shift in output pixels
uniform float uBackgroundBrightness;  // 0 .. 1, 1 = white background
uniform float uBackgroundWarmth;      // -1 .. 1, cool .. neutral .. warm

uniform sampler2D uSource;

out vec4 fragColor;

// unpremultiplied color (rgb) and alpha (a) of the source pixel under p
vec4 sampleSource(vec2 p)
{
    vec2 texel = floor(p / uScale);
    vec2 uv = (texel + 0.5) / uSourceSize;
    uv.y = mix(uv.y, 1.0 - uv.y, uFlipY);
    vec4 s = texture(uSource, uv);
    vec3 rgb = s.a > 0.0 ? s.rgb / s.a : vec3(0.0);
    return vec4(rgb, s.a);
}

// ink amount (1 - rgb), transparent pixels carry no ink
vec3 inkOf(vec4 s)
{
    return s.a > 0.0 ? clamp(1.0 - s.rgb, 0.0, 1.0) : vec3(0.0);
}

// distance from the cell center; 1.0 touches the cell edge midpoints
float shapeDistance(vec2 c)
{
    float shape = floor(clamp(uDotShape, 0.0, 2.0) + 0.5);
    vec2 a = abs(c);
    if (shape < 0.5)
    {
        return length(c);          // round
    }
    if (shape < 1.5)
    {
        return a.x + a.y;          // diamond
    }
    return max(a.x, a.y);        // square
}

// coverage (0..1) of the dot of one screen at position p
// original: mul(m, v) = v * m
float screenDot(vec2 p, mat2 m, float cellSize, float ink)
{
    vec2 st = (p * m) / cellSize;
    vec2 cell = 2.0 * fract(st) - 1.0;

    float radius = sqrt(clamp(ink, 0.0, 1.0)) * max(uDotGain, 0.0);
    float d = shapeDistance(cell) - radius;

    // one output pixel = 2 / cellSize in cell units
    float w = max(uSoftness, 0.0) * 2.0 / cellSize;
    float e = 0.5 * w + 0.0001;
    float coverage = 1.0 - smoothstep(-e, e, d);

    return coverage * step(0.0001, ink);
}

// background color from brightness and warmth
vec3 backgroundColor()
{
    float w = clamp(uBackgroundWarmth, -1.0, 1.0);
    vec3 warm = vec3(1.0, 0.94, 0.80);   // newsprint beige
    vec3 cool = vec3(0.85, 0.93, 1.0);   // bluish white
    vec3 tint = w >= 0.0 ? mix(vec3(1.0), warm, w) : mix(vec3(1.0), cool, -w);
    return tint * clamp(uBackgroundBrightness, 0.0, 1.0);
}

void main()
{
    vec2 pos = FlutterFragCoord().xy + uOffset;

    float cellSize = max(uDotSize, 1.0);

    // screen matrices (original angles), global rotation
    mat2 mK = mat2(0.707, 0.707, -0.707, 0.707);   // 45°
    mat2 mC = mat2(0.966, 0.259, -0.259, 0.966);   // 15°
    mat2 mM = mat2(0.966, -0.259, 0.259, 0.966);   // -15°
    mat2 mY = mat2(1.0);                           // 0°
    float a = radians(uAngle);
    mat2 rot = mat2(cos(a), sin(a), -sin(a), cos(a));

    // misregistration: C, M, Y shifted in three directions 120° apart
    float mis = max(uMisregistration, 0.0);
    vec2 offC = mis * vec2(-1.0, 0.0);
    vec2 offM = mis * vec2(0.5, 0.866);
    vec2 offY = mis * vec2(0.5, -0.866);

    vec4 center = sampleSource(pos);
    vec3 inkCenter = inkOf(center);
    float inkK = min(inkCenter.x, min(inkCenter.y, inkCenter.z));
    float inkC = inkOf(sampleSource(pos - offC)).x;
    float inkM = inkOf(sampleSource(pos - offM)).y;
    float inkY = inkOf(sampleSource(pos - offY)).z;

    float k = screenDot(rot * pos, mK, cellSize, inkK);
    float c = screenDot(rot * (pos - offC), mC, cellSize, inkC);
    float m = screenDot(rot * (pos - offM), mM, cellSize, inkM);
    float y = screenDot(rot * (pos - offY), mY, cellSize, inkY);

    vec3 texcolor = center.rgb;

    // inks printed on (tinted) background
    vec3 rgbscreen = backgroundColor() * (1.0 - vec3(c, m, y));
    rgbscreen = mix(rgbscreen, texcolor, k);   // K dots show the original color

    vec3 rgb = mix(rgbscreen, texcolor, clamp(uOriginalMix, 0.0, 1.0));

    // make blacks actually black
    float maxc = max(texcolor.r, max(texcolor.g, texcolor.b));
    rgb = maxc < 0.01 ? vec3(0.0) : rgb;

    float alpha = center.a;
    fragColor = vec4(rgb * alpha, alpha);
}