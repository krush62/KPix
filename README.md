# KPix

### *A pixel art creation tool.*

<span style="color:yellow">*SCREENSHOT PLACEHOLDER*</span>

## Contents

[Overview](#overview)\
[Features](#features)\
[Controls](#controls)\
[Installation](#installation)\
[License](#license)

## Overview
KPix is a pixel art editor for still images with a focus on generative color ramps and shading. The key aspects are:
- exclusive use of indexed colors
- generative color ramps based on parameters
- hsv based color representation
- shading capabilities for all tools
- cross-platform support 
- stylus and touch support
- automatic light/dark theme

## Features
### Drawing Tools
- Pen
- Shape
- Text
- Fill
- Stamp
- Line / Bézier Curve
- Spray Can

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

Palettes can be saved using the kpal format which is also used by [KPal](https://github.com/krush62/KPal). The file format documentation can be found [here](docs/kpal_file_format.md).


### File Format Support
Kpix uses its own kpix format for storing project files. The file format documentation can be found [here](docs/kpix_file_format.md).
#### Export Formats
##### Image Formats
Projects can be exported to uncompressed images including transparency. Integer scaling is supported.
- png
##### Application Formats
Projects can be exported for usage in other applications. Palettes and layers will be included.
- aseprite (Aseprite)
- psd (Photoshop)
- xcf (Gimp)



#### Import Formats
Due to its unique way of having parameterized color ramps, an import of other formats would always need some kind of remapping of the used colors into individual color ramps. 

## Controls
This application supports input by mouse/keyboard, touch screen and stylus.
The complete control table can be found [here](docs/controls.md).

### Quick Start
| ACTION      | MOUSE               | TOUCH                | STYLUS                           |
|-------------|---------------------|----------------------|----------------------------------|
| use tool    | left click          | one finger           | down                             |
| move canvas | middle click + move | two finger move      | button press + move              |
| zoom canvas | mouse wheel         | two finger pinch     | button long press + move up/down |
| color pick  | right click         | one finger down long | quick button down and up         |


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

## License
TBD


