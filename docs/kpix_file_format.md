# kpix File Format Description v3

This document describes the structure of the kpix file format which is used to save/load project files for the KPix software.

## Syntax and Data Types
### Format
Data is displayed in the following format:

Single types: ``name data_type (length)`` (single types start with lower case)

Compound types ``Name (length)`` (compound types start with upper case)

An optional comment starting with ``//`` may be appended. 

### Data Types

| type       | bytes | min                        | max                        |
|------------|-------|----------------------------|----------------------------|
| ``byte``   | 1     | -128                       | 127                        |
| ``ubyte``  | 1     | 0                          | 255                        |
| ``short``  | 2     | -32,768                    | 32,767                     |
| ``ushort`` | 2     | 0                          | 65,535                     |
| ``int``    | 4     | -2,147,483,648             | 2,147,483,647              |
| ``uint``   | 4     | 0                          | 4,294,967,295              |
| ``int64``  | 8     | -9,223,372,036,854,775,808 | 9,223,372,036,854,775,807  |
| ``uint64`` | 8     | 0                          | 18,446,744,073,709,551,615 |
| ``float``  | 4     | 3.4E -38 (7 digits)        | 3.4E +38 (7 digits)        |
| ``double`` | 8     | 1.7E -308 (15 digits)      | 1.7E -308 (15 digits)      |

Strings (``string``) are represented by an ``ushort`` for the length of the string followed by UTF8 encoded characters (``ubyte``). 

## File Structure

The kpix file format consists of the following three consecutive sections:

### Header
* magic_number ``ubyte (4)`` //``4B 50 49 58``
* file_format_version ``ubyte (1)`` // currently: ``03``

### Palette
* ramp_count ``ubyte (1)`` // how many color ramps in the palette
* Ramps ``(ramp_count)``
  * color_count ``ubyte (1)`` // how many colors in the ramp
  * base_hue ``ushort (1)`` // 0...360
  * base_sat ``ubyte (1)`` // 0...100
  * hue_shift ``byte (1)`` // -90...90
  * hue_shift_exp ``ubyte (1)`` // 50...200
  * sat_shift ``byte (1)`` // -25...25
  * sat_shift_exp ``ubyte (1)`` // 50...200
  * sat_curve ``ubyte (1)`` // ``00`` = noFlat, ``01`` = darkFlat, ``02`` = brightFlat, ``03`` = linear 
  * val_min ``ubyte (1)``
  * val_max ``ubyte (1)``
  * Color_Shifts ``(color_count)`` // shifts for individual colors
    * hue_shift ``byte (1)`` // -25...25
    * sat_shift ``byte (1)`` // -15...15
    * val_shift ``byte (1)`` // -15...15

### Image 
* columns ``ushort (1)`` // width of image
* rows ``ushort (1)`` // height of image
* layer_count ``ushort (1)`` // how many layers
* Layers ``(layer_count)``
  * type ``ubyte (1)`` // ``01``= drawing layer, ``02``= reference layer, ``03``= grid layer, ``04``= shading layer, ``05``= dither layer
  * visibility ``ubyte (1)`` // ``00``= visible, ``01`` = hidden

  // data for type ``01`` (drawing layer)  
  * lock_type ``ubyte (1)`` // ``00``= unlocked, ``01`` = transparency locked, ``02`` = locked
  * outer_stroke_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = relative, ``03`` = glow, ``04`` = shade
  * outer_stroke_directions ``ubyte (1)`` // bitmask of directions: ``00`` = top left, ``01`` = center top, ``02`` = top right, ``03`` = center right, ``04`` = bottom right, ``05`` = center bottom, ``06`` = bottom left, ``07`` = center left
  * outer_stroke_solid_color_ramp_index ``ubyte (1)`` // color ramp index
  * outer_stroke_solid_color_index ``ubyte (1)`` // index in color ramp
  * outer_stroke_darken_brighten ``byte (1)`` // shading amount for relative/shade -5...5
  * outer_stroke_glow_depth ``byte (1)`` // amount of glow depth -6...+6
  * outer_glow_recursive ``ubyte (1)`` // ``00`` = false, ``01`` = true
  * inner_stroke_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = bevel, ``03`` = glow, ``04`` = shade
  * inner_stroke_directions ``ubyte (1)`` // bitmask of directions: ``00`` = top left, ``01`` = center top, ``02`` = top right, ``03`` = center right, ``04`` = bottom right, ``05`` = center bottom, ``06`` = bottom left, ``07`` = center left
  * inner_stroke_solid_color_ramp_index ``ubyte (1)`` // color ramp index
  * inner_stroke_solid_color_index ``ubyte (1)`` // index in color ramp
  * inner_stroke_darken_brighten ``byte (1)`` // shading amount for shade -5...5
  * inner_stroke_glow_depth ``byte (1)`` // amount of glow depth -6...+6
  * inner_stroke_glow_recursive ``ubyte (1)`` // ``00`` = false, ``01`` = true
  * inner_stroke_bevel_distance ``ubyte (1)`` // border distance of bevel 1...8
  * inner_stroke_bevel_strength ``ubyte (1)`` // shading strength of bevel 1...8
  * drop_shadow_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = shade
  * drop_shadow_solid_color_ramp_index ``ubyte (1)`` // color ramp index
  * drop_shadow_solid_color_index ``ubyte (1)`` // index in color ramp
  * drop_shadow_offset_x ``byte (1)`` // -16...16
  * drop_shadow_offset_y ``byte (1)`` // -16...16
  * drop_shadow_darken_brighten ``byte (1)`` // shading amount for shade -5...5
  * data_count ``uint (1)`` // how many non-transparent pixels on layer
  * Image_Data ``(data_count)``
    * x ``ushort (1)`` // x position
    * y ``ushort (1)`` // y position
    * color_ramp_index ``ubyte (1)`` // color ramp index
    * color_index ``ubyte (1)`` // index in color ramp\
    
  // data for type ``02`` (reference layer)
  * path (string)  
  * opacity ``ubyte (1)`` // 0...100
  * offset_x ``float (1)``
  * offset_y ``float (1)``
  * zoom ``ushort (1)`` // 1...2000 (representing zoom factor * 1000)
  * aspect_ratio ``float (1)``// -5...5 (vertical/horizontal stretch max. 6x)

  // data for type ``03`` (grid layer)  
  * opacity ``ubyte (1)`` // 0...100
  * brightness ``ubyte (1)`` // 0...100
  * grid_type ``ubyte (1)`` // ``00``= rectangular, ``01`` = diagonal, ``02`` = isometric, ``03`` = hexagonal, ``04`` = triangular, , ``05`` = brick
  * interval_x ``ubyte (1)`` // 2...64
  * interval_x ``ubyte (1)`` // 2...64
  * horizon_position ``float (1)``// 0...1 (vertical horizon position)
  * vanishing_point_1 ``float (1)``// 0...1 (horizontal position of first vanishing point)
  * vanishing_point_2 ``float (1)``// 0...1 (horizontal position of second vanishing point)
  * vanishing_point_3 ``float (1)``// 0...1 (vertical position of third vanishing point)

  // data for type ``04`` and ``05`` (shading layer/dither layer)
  * lock_type ``ubyte (1)`` // ``00``= unlocked, ``02`` = locked
  * shading_step_limit_low ``ubyte (1)`` // 1...16
  * shading_step_limit_high ``ubyte (1)`` // 1...16
  * data_count ``uint (1)`` //how many shading pixels exist on the layer
  * Image_Data ``(data_count)``
    * x ``ushort (1)`` // x position
    * y ``ushort (1)`` // y position
    * shading ``byte (1)`` // how many shading steps -5...5
    
  ### Timeline
* frames_count ``ubyte (1)`` // how many frames in the timeline
* start_frame ``ubyte (1)`` // first loop frame
* end_frame ``ubyte (1)`` // last loop frame
* frames ``(frames_count)``
  * fps ``ubyte (1)`` // frames per second
  * frame_layer_count ``ubyte (1)`` // how many layers in the frame
  * Frame Layers ``(frame_layer_count)``
    * layer_index ``ubyte (1)`` // index of the layer (see layer list in image section)
  
  