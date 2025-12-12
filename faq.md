# Frequently Asked Questions


- [What makes KPix different from other pixel art editors?](#what-makes-kpix-different-from-other-pixel-art-editors)
- [Does KPix collect any data?](#does-kpix-collect-any-data)
- [Why is there no version for iOS or MacOS?](#why-is-there-no-version-for-ios-or-macos)
- [Does KPix support different languages?](#does-kpix-support-different-languages)
- [Why are there limits to the canvas size, color count, layer count and frame count?](#why-are-there-limits-to-the-canvas-size-color-count-layer-count-and-frame-count)
- [Where are my project files stored?](#where-are-my-project-files-stored)
- [How can I support this project?](#how-can-i-support-this-project)
 
---

## What makes KPix different from other pixel art editors?
KPix uses indexed colors and works in the HSV color space. Even if other editors also support this, the color generation is completely different: Color levels are mapped in ramps that are defined by parameters. These parameters control the individual gradations between the color tones. This enables harmonious and consistent color tones. Each individual color can still be adjusted separately.

Another focus is working with shading. Thanks to the defined color ramps, shades always deliver the right color without introducing new colors. All drawing tools support shading and there are layers that enable non-destructive shading.

KPix also provides various algorithms not found in any other editor, such as segment sorting for lines, advanced and non-destructive layer effects, image import with palette creation and many more.

KPix is open source and is natively supported on various platforms like Android (Tablets), Windows, Linux and even Web.

## Does KPix collect any data?
No, KPix does not collect any data. Even more: The only time the application accesses the internet is when it checks for an update (Desktop versions only).

## Why is there no version for iOS or MacOS?
I am a Linux user that occasionally uses Windows and Android. I don't have any Apple device to create releases. Even though the application framework (Flutter) supports iOS and MacOS, I have no device/account to build and test the application. 

## Does KPix support different languages?
Not yet. I would love to support this, but don't have the time. The interface is designed to use symbols and not text where possible, though.

## Why are there limits to the canvas size, color count, layer count and frame count?
These limits might seem arbitrary but are based on the file format and performance considerations, but nothing is carved in stone.

## How to move the contents of a drawing layer?
KPix does not have a dedicated move tool. Instead, use the selection/marquee tool to select the area you want to move and move the selection by dragging from inside the selection. 

## Where are my project files stored?
KPix uses the user directories of the system to store project files. Usually, **the user should not change these contents** directly. You can export your project as KPix file using the regular export dialog.
These internal user directories are:
- Windows: %APPDATA%\de.krush62\kpix
- Linux: \$HOME/.local/share/de.krush62.kpix or \$XDG_DATA_HOME/de.krush62.kpix or $HOME/.local/share/de.krush62.kpix
- Android: /data/data/de.krush62.kpix/files
The project files (and other files like palettes, stamps, ...) are inside these directories.


## How can I support this project?
You can support KPix by:
- providing feedback (of any kind, really) via the [discussions page](https://github.com/krush62/KPix/discussions) (bugs, ideas, questions)
- being a developer in the Apple ecosystem willing to create versions for iOS/MacOS 


---

*Thanks for your interest in KPix,*

### *krush62*