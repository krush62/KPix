#version 460 core
precision highp float;

/*
   Cel shading, after "Advanced Cartoon shader I and II" from the libretro slang shaders
   by guest(r) (guest.r@gmail.com)
   License: GNU-GPL
   Ported to Flutter: outline width in output pixels, the number of color levels as a parameter
   (4 = the original), transparency counts for the outlines, black no longer normalizes a zero vector.
*/

#include <flutter/runtime_effect.glsl>

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

uniform float uOutlineWidth;      // 0 .. 4, in output pixels (the original's border 1.0 at 8x = 1)
uniform float uOutlineStrength;   // 0 .. 2, 1 = the original's sensitivity of 0.5
uniform float uLevels;            // 2 .. 8, brightness and hue levels, 4 = the original
uniform float uMuteColors;        // 0 / 1, the original's "mute colors" mode

uniform sampler2D uSource;

out vec4 fragColor;

// premultiplied source pixel under t (source pixels)
vec4 tap(vec2 t)
{
    vec2 uv = (floor(t) + 0.5) / uSourceSize;
    uv.y = mix(uv.y, 1.0 - uv.y, uFlipY);
    return texture(uSource, uv);
}

float diff(vec4 a, vec4 b)
{
    return dot(abs(a - b), vec4(1.0));
}

void main()
{
    vec2 t = (FlutterFragCoord().xy + uOffset) / uScale;
    float w = max(uOutlineWidth, 0.0) / uScale;
    vec2 dx = vec2(w, 0.0);
    vec2 dy = vec2(0.0, w);
    vec2 dg1 = vec2(w, w);
    vec2 dg2 = vec2(-w, w);

    vec4 c00 = tap(t - dg1);
    vec4 c10 = tap(t - dy);
    vec4 c20 = tap(t + dg2);
    vec4 c01 = tap(t - dx);
    vec4 center = tap(t);
    vec4 c21 = tap(t + dx);
    vec4 c02 = tap(t - dg2);
    vec4 c12 = tap(t + dy);
    vec4 c22 = tap(t + dg1);
    vec3 dt = vec3(1.0, 1.0, 1.0);

    float alpha = center.a;
    vec3 c11 = alpha > 0.0 ? center.rgb / alpha : vec3(0.0);

    // edges: color changes across the pixel, stronger on dark colors
    float d1 = diff(c00, c22);
    float d2 = diff(c20, c02);
    float hl = diff(c01, c21);
    float vl = diff(c10, c12);
    float d = 0.5 * max(uOutlineStrength, 0.0) * (d1 + d2 + hl + vl) / (dot(c11, dt) + 0.15);
    float outline = 1.1 - d * sqrt(d);

    float levels = max(floor(uLevels + 0.5), 1.0);
    float brightness = length(c11);
    // hue direction; black has none and stays black through the brightness below
    vec3 direction = brightness > 0.0 ? c11 / brightness : vec3(0.0);

    vec3 rgb;
    if (uMuteColors < 0.5)
    {
        float lc = levels * brightness;
        float f = fract(lc); f *= f;
        lc = (floor(lc) + f * f) / levels + 0.05;
        vec3 hue = levels * direction;
        vec3 frct = fract(hue); frct *= frct;
        hue = floor(hue) + 0.05 * dt + frct * frct;
        rgb = lc * outline * hue / levels;
    }
    else
    {
        float lc = (levels + 1.0) * brightness;
        lc = (floor(lc) + pow(fract(lc), 4.0)) / (levels + 1.0);
        vec3 hue = levels * direction;
        vec3 frct = fract(hue); frct *= frct;
        hue = floor(hue) + frct * frct;
        hue = hue * lc / levels;
        lc *= 0.577;
        hue = mix(hue, lc * dt, lc);
        rgb = outline * hue;
    }

    fragColor = vec4(clamp(rgb, 0.0, 1.0) * alpha, alpha);
}
