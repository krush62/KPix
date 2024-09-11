![KPIX](imgs/kpix_icon_small_transparent.png)


### *KPix: A pixel art creation tool.*

![release](https://img.shields.io/github/v/release/krush62/KPix)
![release-date](https://img.shields.io/github/release-date/krush62/KPix)
![last-commit](https://img.shields.io/github/last-commit/krush62/KPix)
![downloads](https://img.shields.io/github/downloads/krush62/KPix/total)

![issues](https://img.shields.io/github/issues-raw/krush62/KPix)
![pull-requests](https://img.shields.io/github/issues-pr-raw/krush62/KPix)
![license](https://img.shields.io/github/license/krush62/KPix)
## Contents

[Overview](#overview)\
[Features](#features)\
[Controls](#controls)\
[Installation](#installation)\
[Web Version](#web-version)\
[Roadmap](#roadmap)\
[License](#license)

## Overview
KPix is a pixel art editor for still images with a focus on generative color ramps and shading. The key aspects are:
- exclusive use of indexed colors
- generative color ramps based on parameters
- hsv based color representation
- shading capabilities for all tools
- multi-platform support 
- stylus and touch support
- automatic light/dark theme

<span style="color:yellow">*SCREENSHOT PLACEHOLDER*</span>

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
KPix uses its own kpix format for storing project files. The file format documentation can be found [here](docs/kpix_file_format.md).
#### Export Formats
##### Image Formats
Projects can be exported to uncompressed images including transparency. Integer scaling is supported.
- png
##### Application Formats
Projects can be exported for usage in other applications. Palettes and layers will be included.
- aseprite (Aseprite)
- xcf (Gimp)

Palettes can be exported for usage in other applications.
- png
- aseprite (Aseprite)
- gpl (Gimp)
- txt (Paint.NET)
- ase (Adobe)
- pal (JASC)
- xml (Corel)
- soc (Star/Open/Libre Office)

#### Import Formats
Due to its unique way of having parameterized color ramps, an import of other formats would always need some kind of remapping of the used colors into individual color ramps. This is a planned feature. 

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
All release versions can be found at [latest releases](https://github.com/krush62/KPix/releases/latest).

### Windows
There are two ways to run KPix on Windows:
#### Installer
Download and run the provided Windows installer. The application can be easily uninstalled and a file association is created.
#### Package (zip)
This is a portable version. Extract the contents of the Windows Zip Package and run kpix.exe to start the application.\

### Linux
Extract the contents of the Linux tar.gz Package and run kpix to start the application. This version needs to have `libgtk-3-0`, `libblkid1` and `liblzma5` installed.

### Android
Download the Android apk file and install it manually.

[//]: # (### macOS)
[//]: # (### iOS/iPadOS)
[//]: # (## Web Version)

## Roadmap
A list of ideas and features for future versions can be found here: [#53](https://github.com/krush62/KPix/issues/53). Prioritizing of items will happen when alpha tests were performed.

## License
This project is licensed under [AGPLv3](LICENSE).


