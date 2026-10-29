#version 460 core
precision highp float;

// SPDX-FileCopyrightText: Andreas Kruschinski
// SPDX-License-Identifier: AGPL-3.0-or-later

// Clustered-dot (halftone) dithering upscaler.
// Each source pixel becomes one halftone cell of uScale x uScale output pixels.

#include <flutter/runtime_effect.glsl>

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

uniform float uColorDepth;   // 1.0 .. 8.0 (bits per channel)

uniform sampler2D uSource;

out vec4 fragColor;

const int MAX_CELL = 16;     // largest supported cell size in output pixels
const float PI = 3.14159265;

// cosine spot function: highest in the cell centre, lowest in the corners
float spot(vec2 ip, float n)
{
    vec2 p = (ip + 0.5) / n * 2.0 - 1.0;
    return cos(PI * p.x) + cos(PI * p.y);
}

// threshold in (0, 1): rank of this pixel within the cell, centre first
float clusteredThreshold(vec2 ip, float n)
{
    float s = spot(ip, n);
    float idx = ip.y * n + ip.x;
    float rank = 0.0;

    for (int j = 0; j < MAX_CELL; j++)
    {
        for (int i = 0; i < MAX_CELL; i++)
        {
            if (float(i) < n && float(j) < n)
            {
                vec2 q = vec2(float(i), float(j));
                float sq = spot(q, n);
                float qi = q.y * n + q.x;
                // pixels with a higher spot value (or equal, but lower index) come first
                if (sq > s || (sq == s && qi < idx))
                {
                    rank += 1.0;
                }
            }
        }
    }

    return (rank + 0.5) / (n * n);
}

void main()
{
    vec2 pos = FlutterFragCoord().xy + uOffset;
    vec2 texel = floor(pos / uScale);
    vec2 local = pos - texel * uScale;

    vec2 uv = (texel + 0.5) / uSourceSize;
    uv.y = mix(uv.y, 1.0 - uv.y, uFlipY);

    vec4 src = texture(uSource, uv);

    float alpha = src.a;
    vec3 rgb = alpha > 0.0 ? src.rgb / alpha : vec3(0.0);

    float n = clamp(floor(uScale), 1.0, float(MAX_CELL));
    vec2 ip = clamp(floor(local), 0.0, n - 1.0);
    float t = clusteredThreshold(ip, n);

    // multi-level quantization: the fractional part between two levels
    // decides how much of the cell is covered by the dot
    float levels = pow(2.0, uColorDepth) - 1.0;
    vec3 v = clamp(rgb, 0.0, 1.0) * levels;
    vec3 base = floor(v);
    vec3 dotCover = step(vec3(t), v - base);
    rgb = clamp((base + dotCover) / levels, 0.0, 1.0);

    fragColor = vec4(rgb * alpha, alpha);
}