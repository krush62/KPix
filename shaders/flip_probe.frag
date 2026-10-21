#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform sampler2D uSource;

out vec4 fragColor;

// samples without any correction, so the renderer can tell whether the backend flips images
void main()
{
  fragColor = texture(uSource, FlutterFragCoord().xy / uSize);
}
