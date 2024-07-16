# kpal File Format Description

This document describes the structure of the kpal file format which is used to save/load project files for the KPal 
software and to load palettes into KPix.

## Syntax and Data Types
### Format
Data is displayed in the following format:

Single types: ``name data_type (length)`` (single types start with lower case)

Compound types ``Name (length)`` (compound types start with upper case)

An optional comment starting with ``//`` may be appended.

### Data Types

| type   | bytes | min                        | max                        |
|--------|-------|----------------------------|----------------------------|
| byte   | 1     | -128                       | 127                        |
| ubyte  | 1     | 0                          | 255                        |
| short  | 2     | -32,768                    | 32,767                     |
| ushort | 2     | 0                          | 65,535                     |
| int    | 4     | -2,147,483,648             | 2,147,483,647              |
| uint   | 4     | 0                          | 4,294,967,295              |
| int64  | 8     | -9,223,372,036,854,775,808 | 9,223,372,036,854,775,807  |
| uint64 | 8     | 0                          | 18,446,744,073,709,551,615 |
| float  | 4     | 3.4E -38 (7 digits)        | 3.4E +38 (7 digits)        |
| double | 8     | 1.7E -308 (15 digits)      | 1.7E -308 (15 digits)      |

## File Structure

The kpal file format consists of the following three consecutive sections:

### Options (ignored in KPix)
* option_count ``ubyte (1)`` 
* Options ``(option_count)``
  * option_key ``ubyte (1)``
  * option_value ``ubyte (1)``

### Ramps
* ramp_count ``ubyte (1)``
* Ramps  ``(ramp_count)``
  * name_length ``uint (1)`` // ignored in KPix
  * name_data ``ubyte (name_length)`` //ignored in KPix
  * color_count ``ubyte (1)``
  * base_hue ``ushort (1)`` // 0...360
  * base_sat ``ushort (1)`` // 0...100
  * hue_shift ``byte (1)`` // -90...90
  * hue_shift_exp ``float (1)`` // 0.5...2.0
  * sat_shift ``byte (1)`` // -25...25
  * sat_shift_exp ``float (1)`` // 0.5...2.0
  * val_min ``ubyte (1)``
  * val_max ``ubyte (1)``
  * Color_Shifts ``(color_count)``
    * hue_shift ``byte (1)`` // -25...25
    * sat_shift ``byte (1)`` // -15...15
    * val_shift ``byte (1)`` // -15...15
  * ramp_option_count ``ubyte (1)``
  * Ramp_options ``(ramp_option_count)``
    * option_type ``ubyte (1)``
    * option_value ``ubyte (1)``

### Links (ignored in KPix)
* link_count ``ubyte (1)``
* Link ``(link_count)``
  * source_ramp_index ``ubyte (1)``
  * source_color_index ``ubyte (1)``
  * target_ramp_index ``ubyte (1)``
  * target_color_index ``ubyte (1)``