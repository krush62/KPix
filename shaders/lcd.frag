#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

uniform float uBrightness;
uniform float uGridWidth;
uniform float uGridGray;
uniform float uSoftness;
uniform float uSubpixels;
uniform float uGridOnTransparency;

uniform sampler2D uSource;

out vec4 fragColor;

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

void main()
{
  vec2 pos = FlutterFragCoord().xy + uOffset;
  vec2 texel = floor(pos / uScale);
  vec2 local = pos - texel * uScale;

  vec2 uv = (texel + 0.5) / uSourceSize;
  uv.y = mix(uv.y, 1.0 - uv.y, uFlipY);
  vec4 src = texture(uSource, uv);

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
  vec3 rgb = alpha > 0.0 ? src.rgb / alpha : vec3(0.0);
  rgb = clamp(rgb * mask * uBrightness, 0.0, 1.0);

  float k = coverage;
  vec3 gridColor = vec3(uGridGray);
  vec3 blended = hardLight(rgb, gridColor);
  vec4 tinted = vec4(mix(rgb, blended, k) * alpha, alpha);
  // over transparency the grid has nothing to blend with and shows its own gray
  vec4 over = vec4(gridColor * k * (1.0 - alpha) + blended * k * alpha + rgb * alpha * (1.0 - k), k + alpha * (1.0 - k));
  fragColor = mix(tinted, over, uGridOnTransparency);
}
