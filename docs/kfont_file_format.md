# kfont File Format Description

This document describes the structure of the kfont file format which is used to load pixel fonts into KPix.

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

The kfont file format consists of the following two consecutive sections:

### Header
* height ``ubyte (1)``  // height of the characters
* char_count ``ushort (1)`` // number of glyphs

### Glyphs
* Glyphs ``(char_count)``
  * unicode_index ``ushort (1)``
  * width ``ubyte (1)``
  * Glyph_Data ``(height * ((width + 1) / 8 ) + 1)``
    * bitmask ``byte (1)``