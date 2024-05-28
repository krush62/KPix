# kstamp File Format Description

This document describes the structure of the kstamp file format which is used to load brushes for the KPix software.

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
* width ``ubyte (1)``
* height ``ubyte (1)``
* shading_count ``ushort (1)``
* Shadings ``(shading_count)``
  * shading_offset ``byte (1)`` // -5...5
  * coord_count ``ushort (1)``
  * Coords ``(coord_count)``
    * x ``ubyte (1)``
    * y ``ubyte (1)``