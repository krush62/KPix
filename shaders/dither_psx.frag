#version 460 core
precision highp float;

// PlayStation 1 style dithering with controls.
// PS1 defaults: uColorDepth = 5, uDitherStrength = 1, uRounding = 0, uFullRange = 1

#include <flutter/runtime_effect.glsl>

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

uniform float uColorDepth;      // 1 .. 8, PS1: 5
uniform float uDitherStrength;  // 0 .. 2, PS1: 1
uniform float uRounding;        // 0 = truncate (PS1), 1 = round
uniform float uFullRange;       // 1 = max level is full white (PS1 display), 0 = shift only

uniform sampler2D uSource;

out vec4 fragColor;

float bitAt(float n, float k)
{
    return mod(floor(n / k), 2.0);
}

// standard 4x4 Bayer value (0..15) for row r, column c
float bayer4(float r, float c)
{
    float r0 = bitAt(r, 1.0);
    float r1 = bitAt(r, 2.0);
    float c0 = bitAt(c, 1.0);
    float c1 = bitAt(c, 2.0);
    return 8.0 * abs(r0 - c0) + 4.0 * r0 + 2.0 * abs(r1 - c1) + r1;
}

// dither offset in 8-bit units for a quantization step of 'stepSize'
// stepSize = 8 (5 bits): exactly the PS1 matrix, -4 .. +3
float ditherOffset(vec2 p, float stepSize)
{
    vec2 st = mod(p, 4.0);
    float b = bayer4(st.y, st.x);
    return floor(b * stepSize / 16.0) - stepSize / 2.0;
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

    float depth = clamp(floor(uColorDepth + 0.5), 1.0, 8.0);
    float stepSize = pow(2.0, 8.0 - depth);      // size of one level in 8-bit units
    float levels = pow(2.0, depth) - 1.0;        // highest quantized value
    float strength = clamp(uDitherStrength, 0.0, 2.0);
    float roundBias = step(0.5, uRounding) * 0.5;

    // to 8-bit, add offset, clamp
    vec3 c8 = floor(clamp(rgb, 0.0, 1.0) * 255.0 + 0.5);
    c8 = clamp(c8 + ditherOffset(texel, stepSize) * strength, 0.0, 255.0);

    // quantize: truncate (PS1) or round
    vec3 q = clamp(floor(c8 / stepSize + roundBias), 0.0, levels);

    // back to 0..1: full range (PS1 display) or plain shift (q << shift)
    vec3 full = q / levels;
    vec3 shifted = q * stepSize / 255.0;
    rgb = mix(shifted, full, step(0.5, uFullRange));

    fragColor = vec4(rgb * alpha, alpha);
}