#version 460 core
precision highp float;

// Checkerboard dithering: each channel is either a solid quantized level
// or a 50% checkerboard of the two nearest levels.

#include <flutter/runtime_effect.glsl>

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

uniform float uColorDepth;    // 1.0 .. 8.0 (bits per channel)
uniform float uCheckerWidth;  // 0.0 .. 1.0, share of each step that is dithered

uniform sampler2D uSource;

out vec4 fragColor;

void main()
{
    vec2 pos = FlutterFragCoord().xy + uOffset;
    vec2 texel = floor(pos / uScale);

    vec2 uv = (texel + 0.5) / uSourceSize;
    uv.y = mix(uv.y, 1.0 - uv.y, uFlipY);

    vec4 src = texture(uSource, uv);

    float alpha = src.a;
    vec3 rgb = alpha > 0.0 ? src.rgb / alpha : vec3(0.0);

    float levels = pow(2.0, clamp(uColorDepth, 1.0, 8.0)) - 1.0;
    vec3 v = clamp(rgb, 0.0, 1.0) * levels;
    vec3 base = floor(v);
    vec3 f = v - base;

    // checkerboard parity of the source pixel: 0.0 or 1.0
    float parity = mod(texel.x + texel.y, 2.0);

    float halfWidth = clamp(uCheckerWidth, 0.0, 1.0) * 0.5;
    float lo = 0.5 - halfWidth;
    float hi = 0.5 + halfWidth;

    // f <  lo           -> base level
    // f >= hi           -> next level
    // inside the zone   -> checkerboard of both
    vec3 above = step(vec3(hi), f);
    vec3 inZone = step(vec3(lo), f) * (1.0 - above);
    vec3 up = above + inZone * parity;

    rgb = clamp((base + up) / levels, 0.0, 1.0);

    fragColor = vec4(rgb * alpha, alpha);
}