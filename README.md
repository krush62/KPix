# kpix

A pixel art creation tool.

## Overview
KPix is a pixel art editor for still images with a focus on generative color ramps and shading. The key aspects are:
- exclusive use of indexed colors
- generative color ramps
- hsv based color representation
- shading capabilities for all tools
- cross-platform support 
- pen support

## Features
### Drawing Tools
- Pen
- Shape
- Text
- Fill
- Stamp

### Shading
The drawing tools work directly (using the selected color) or in shading mode. In shading mode, the affected colors on the canvas are brightened/darkened based on the current color ramp.

### Generative Palette
A palette consists of multiple independent color ramps. Each ramp can have an arbitrary amount of shades (colors). These shades are controlled by parameters:
- base hue (hue of the center shade)
- base saturation (saturation of the center shade)
- hue shift between shades
- saturation shift between shades
- saturation curve (keep darker/brighter shades constant)
- minimum and maximum brightness

### File Format Support
Kpix uses its own file format (documentation can be found here: TBD)
#### Export Formats
TBD
#### Import Formats
TBD

 
## Installation
### Windows
TBD
### Linux
TBD
### Android
TBD
### MacOS
possible, but not planned
### iOS
possible, but not planned

