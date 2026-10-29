#version 460 core
precision highp float;

// SPDX-FileCopyrightText: Andreas Kruschinski
// SPDX-License-Identifier: AGPL-3.0-or-later

// LCD: every source pixel is a cell of a liquid crystal panel. The grid and the subpixels work in gamma space;
// the light of the panel (black level, backlight, glow, pixel shadow) works in linear light on top of them.

#include <flutter/runtime_effect.glsl>

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

// grid
uniform float uGridWidth;
uniform float uGridGray;
uniform float uSoftness;
uniform float uSubpixels;
uniform float uGridOnTransparency;
// panel
uniform float uBrightness;
uniform float uPanelColors;     // 0 .. 1, the muted colors of a handheld panel
uniform float uBlackLevel;      // 0 .. 1, backlight shining through black cells
uniform float uUnevenness;      // 0 .. 1, unevenly spread backlight
uniform float uGlow;            // 0 .. 1, backlight spreading in the diffuser, into the grid and around bright cells
uniform float uGlowRadius;      // 0.5 .. 2, in source pixels
uniform float uPixelShadow;     // 0 .. 1, reflective screens: the cells cast a shadow on the reflector behind them
uniform float uShadowDistance;  // 0 .. 1, in source pixels

uniform sampler2D uSource;

out vec4 fragColor;

const float GAMMA = 2.2;

float hash(vec2 p)
{
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

// smooth value noise
float noise(vec2 p)
{
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// straight color and alpha of a source pixel; nothing outside the picture
vec4 sourcePixel(vec2 texel)
{
  if (texel.x < 0.0 || texel.y < 0.0 || texel.x >= uSourceSize.x || texel.y >= uSourceSize.y)
  {
    return vec4(0.0);
  }
  vec2 uv = (texel + 0.5) / uSourceSize;
  uv.y = mix(uv.y, 1.0 - uv.y, uFlipY);
  vec4 src = texture(uSource, uv);
  return vec4(src.a > 0.0 ? src.rgb / src.a : vec3(0.0), src.a);
}

// the colors of a Game Boy Advance panel: muted and shifted primaries, white stays white
// (color profile of gba-color by Pokefan531 and hunterk, public domain)
vec3 panelColors(vec3 rgb)
{
  float amount = clamp(uPanelColors, 0.0, 1.0);
  if (amount <= 0.0)
  {
    return rgb;
  }
  vec3 lin = pow(clamp(rgb, 0.0, 1.0), vec3(GAMMA));
  vec3 panel = mat3(0.905, 0.10, 0.1575, 0.195, 0.65, 0.1425, -0.10, 0.25, 0.70) * lin * 0.91;
  return pow(clamp(mix(lin, panel, amount), 0.0, 1.0), vec3(1.0 / GAMMA));
}

// the light a cell lets through, linear and weighted by its coverage
vec3 cellLight(vec4 cell)
{
  return pow(clamp(panelColors(cell.rgb) * uBrightness, 0.0, 1.0), vec3(GAMMA)) * cell.a;
}

// grid coverage of the output pixel centred at [c] inside a cell of [size] pixels
float gridCoverage(float c, float size, float lead, float trail, float softPx)
{
  float dist = min(c - lead, (size - trail) - c);
  if (dist < 0.0)
  {
    return 1.0;
  }
  if (softPx < 0.001)
  {
    return 0.0;
  }
  return 1.0 - smoothstep(0.0, softPx, dist);
}

// multiply below 50% grid gray, screen above; 50% leaves the pixel unchanged
vec3 hardLight(vec3 base, vec3 blend)
{
  vec3 multiplied = 2.0 * base * blend;
  vec3 screened = 1.0 - 2.0 * (1.0 - base) * (1.0 - blend);
  return mix(multiplied, screened, step(0.5, blend));
}

// how much the cells block the light that the reflector shows at [pos] (output pixels): the light comes from
// the top left, so the shadow falls towards the bottom right
float pixelShadow(vec2 pos)
{
  float reach = clamp(uShadowDistance, 0.0, 1.0) * uScale;
  vec2 center = pos - vec2(reach);
  float spread = 0.15 * uScale + 0.3 * reach;
  float sum = 0.0;
  for (int y = -1; y <= 1; y++)
  {
    for (int x = -1; x <= 1; x++)
    {
      vec4 cell = sourcePixel(floor((center + vec2(float(x), float(y)) * spread) / uScale));
      sum += cell.a - dot(cellLight(cell), vec3(0.2126, 0.7152, 0.0722));
    }
  }
  return clamp(sum / 9.0, 0.0, 1.0);
}

// the backlight at [pos]: clouds of a diffuser that spreads the light unevenly, brighter at the bottom edge
// where the light enters
float backlight(vec2 pos)
{
  float amount = clamp(uUnevenness, 0.0, 1.0);
  if (amount <= 0.0)
  {
    return 1.0;
  }
  vec2 uv = pos / (uSourceSize * uScale);
  float clouds = 0.6 * noise(uv * 3.0 + 11.0) + 0.4 * noise(uv * 7.0 + 23.0) - 0.5;
  float edge = exp(-(1.0 - uv.y) * 10.0);
  return 1.0 + amount * (0.35 * clouds + 0.25 * edge - 0.12);
}

// the light of the cells around [pos] (output pixels), spread by the diffuser
vec3 glowLight(vec2 pos)
{
  vec2 p = pos / uScale;
  vec2 base = floor(p);
  float sigma = clamp(uGlowRadius, 0.25, 2.5);
  vec3 sum = vec3(0.0);
  float weight = 0.0;
  for (int y = -2; y <= 2; y++)
  {
    for (int x = -2; x <= 2; x++)
    {
      vec2 cell = base + vec2(float(x), float(y));
      vec2 d = cell + 0.5 - p;
      float w = exp(-0.5 * dot(d, d) / (sigma * sigma));
      sum += cellLight(sourcePixel(cell)) * w;
      weight += w;
    }
  }
  return sum / weight;
}

void main()
{
  vec2 pos = FlutterFragCoord().xy + uOffset;
  vec2 texel = floor(pos / uScale);
  vec2 local = pos - texel * uScale;
  vec4 src = sourcePixel(texel);

  float width = clamp(floor(uGridWidth), 0.0, uScale - 1.0);
  float lead = floor(width * 0.5);
  float trail = width - lead;
  float body = uScale - width;
  float softPx = uSoftness * body * 0.5;
  float coverage = max(gridCoverage(local.x, uScale, lead, trail, softPx), gridCoverage(local.y, uScale, lead, trail, softPx));

  // rgb stripes need at least one output pixel per channel
  float stripe = clamp(floor((local.x - lead) / body * 3.0), 0.0, 2.0);
  vec3 stripeMask = vec3(1.0 - step(1.0, stripe), step(1.0, stripe) * (1.0 - step(2.0, stripe)), step(2.0, stripe));
  vec3 mask = mix(vec3(1.0), stripeMask, uSubpixels * step(3.0, body));

  float alpha = src.a;
  vec3 rgb = clamp(panelColors(src.rgb) * mask * uBrightness, 0.0, 1.0);

  float k = coverage;
  vec3 gridColor = vec3(uGridGray);
  vec3 blended = hardLight(rgb, gridColor);
  vec4 tinted = vec4(mix(rgb, blended, k) * alpha, alpha);
  // over transparency the grid has nothing to blend with and shows its own gray
  vec4 over = vec4(gridColor * k * (1.0 - alpha) + blended * k * alpha + rgb * alpha * (1.0 - k), k + alpha * (1.0 - k));
  vec4 color = mix(tinted, over, uGridOnTransparency);

  bool lit = uPixelShadow > 0.0 || uBlackLevel > 0.0 || uUnevenness > 0.0 || uGlow > 0.0;
  if (lit && color.a > 0.0)
  {
    vec3 light = pow(clamp(color.rgb / color.a, 0.0, 1.0), vec3(GAMMA));
    if (uPixelShadow > 0.0)
    {
      light *= 1.0 - 0.7 * clamp(uPixelShadow, 0.0, 1.0) * pixelShadow(pos);
    }
    // even a black cell lets some of the backlight through, a little bluish
    vec3 black = clamp(uBlackLevel, 0.0, 1.0) * vec3(0.016, 0.018, 0.024);
    light = black + (1.0 - black) * light;
    float level = backlight(pos);
    light *= level;
    if (uGlow > 0.0)
    {
      // the diffused light shows where the surroundings are brighter than the spot itself; a closed cell still
      // blocks most of it, so it mainly fills the gaps of the grid
      float reach = mix(0.2, 1.0, k);
      light += clamp(uGlow, 0.0, 1.0) * reach * max(glowLight(pos) * level - light, 0.0);
    }
    color = vec4(pow(clamp(light, 0.0, 1.0), vec3(1.0 / GAMMA)) * color.a, color.a);
  }
  fragColor = color;
}
