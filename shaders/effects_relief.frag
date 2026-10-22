#version 460 core
precision highp float;

// Relief: every source pixel is raised by its brightness and/or alpha, the steps between them become
// bevels, lit by a directional light. Flat areas keep their color, only the bevels get light and shadow.

#include <flutter/runtime_effect.glsl>

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

uniform float uLightAngle;            // 0 .. 360, direction the light comes from, 0 = right, 90 = top
uniform float uDepth;                 // 0 .. 16, height of a full black to white step in output pixels
uniform float uBevelWidth;            // 1 .. 8, width of the bevels in output pixels
uniform float uBrightnessInfluence;   // 0 .. 1, 0 = height from alpha only, 1 = height from brightness
uniform float uStrength;              // 0 .. 2, amount of light and shadow
uniform float uColorAmount;           // 0 .. 1, 0 = grey stone, 1 = original colors

uniform sampler2D uSource;

out vec4 fragColor;

const float lightElevation = 0.7854;  // 45 degrees

// premultiplied source pixel
vec4 tap(vec2 texel)
{
    vec2 uv = (texel + 0.5) / uSourceSize;
    uv.y = mix(uv.y, 1.0 - uv.y, uFlipY);
    return texture(uSource, uv);
}

vec3 unpremultiply(vec4 s)
{
    return s.a > 0.0 ? s.rgb / s.a : vec3(0.0);
}

float heightOf(vec2 texel)
{
    vec4 s = tap(texel);
    float luma = dot(unpremultiply(s), vec3(0.299, 0.587, 0.114));
    return s.a * mix(1.0, luma, uBrightnessInfluence);
}

// the blocky height map averaged over a box of size [bevel] around q (output pixels); bevel <= cell size,
// so the box touches at most 2x2 cells and the steps turn into straight ramps
float boxHeight(vec2 q, float bevel)
{
    vec2 low = q - 0.5 * bevel;
    vec2 cell = floor(low / uScale);
    vec2 share = clamp(((cell + 1.0) * uScale - low) / bevel, 0.0, 1.0);
    float h00 = heightOf(cell);
    float h10 = heightOf(cell + vec2(1.0, 0.0));
    float h01 = heightOf(cell + vec2(0.0, 1.0));
    float h11 = heightOf(cell + vec2(1.0, 1.0));
    return mix(mix(h00, h10, 1.0 - share.x), mix(h01, h11, 1.0 - share.x), 1.0 - share.y);
}

void main()
{
    vec2 q = FlutterFragCoord().xy + uOffset;
    float bevel = clamp(uBevelWidth, 1.0, uScale);

    // slopes in output pixels of height per output pixel
    float dx = boxHeight(q + vec2(0.5, 0.0), bevel) - boxHeight(q - vec2(0.5, 0.0), bevel);
    float dy = boxHeight(q + vec2(0.0, 0.5), bevel) - boxHeight(q - vec2(0.0, 0.5), bevel);
    vec3 normal = normalize(vec3(-dx * uDepth, -dy * uDepth, 1.0));

    // screen y points down, so a light from the top has a negative y
    float azimuth = radians(uLightAngle);
    vec3 light = vec3(cos(azimuth) * cos(lightElevation), -sin(azimuth) * cos(lightElevation), sin(lightElevation));
    // 1 on flat ground, above 1 on slopes facing the light, below 1 on slopes facing away
    float shade = 1.0 + uStrength * (max(dot(normal, light), 0.0) / sin(lightElevation) - 1.0);

    vec4 src = tap(floor(q / uScale));
    vec3 base = mix(vec3(0.5), unpremultiply(src), uColorAmount);
    // shadows darken, highlights lighten towards white, so dark colors get highlights as well
    vec3 rgb = base * min(shade, 1.0) + (1.0 - base) * max(shade - 1.0, 0.0);

    fragColor = vec4(clamp(rgb, 0.0, 1.0) * src.a, src.a);
}
