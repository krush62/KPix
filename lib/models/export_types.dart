/*
 * KPix
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:kpix/models/file_constants.dart';

/// What an export asks for: which format, at which scale, to which file.
///
/// Produced by the export dialog and consumed by the file layer, so it belongs
/// to neither.
enum ImageExportType
{
  png,
  aseprite,
  photoshop,
  gimp,
  pixelorama,
  kpix,
  texturePack
}

/// Supported animation export types.
enum AnimationExportType
{
  gif,
  apng,
  zippedPng,
  //aseprite,
  //pixelorama,
  texturePack
}

/// Supported palette export types.
enum PaletteExportType
{
  kpal,
  png,
  aseprite,
  gimp,
  paintNet,
  adobe,
  jasc,
  corel,
  openOffice,
  json
}

/// Supported special export types.
enum KPixExportType
{
  kpix,
  texturePack,
  texturePackAnimated
}

// Available export sections.
enum ExportSectionType
{
  image,
  animation,
  palette,
  kpix
}

/// Data structure for holding information needed for exporting. Like the
/// [extension], [directory], ...
abstract class ExportData
{
  final String extension;
  final String name;
  final String fileName;
  final String directory;
  const ExportData({required this.name, required this.extension, this.fileName = "", this.directory = ""});
}

/// [ExportData] specialization for palettes.
class PaletteExportData extends ExportData
{
  const PaletteExportData({required super.name, required super.extension, super.fileName = "", super.directory = ""});
  factory PaletteExportData.fromWithConcreteData({required final PaletteExportData other, required final String fileName, required final String directory})
  {
    return PaletteExportData(name: other.name, extension: other.extension, directory: directory, fileName: fileName);
  }

  static const Map<PaletteExportType, PaletteExportData> exportTypeMap =
  <PaletteExportType, PaletteExportData>{
    PaletteExportType.png:PaletteExportData(name: "PNG", extension: "png"),
    PaletteExportType.aseprite:PaletteExportData(name: "ASEPRITE", extension: "aseprite"),
    PaletteExportType.gimp:PaletteExportData(name: "GIMP", extension: "gpl"),
    PaletteExportType.paintNet:PaletteExportData(name: "PAINT.NET", extension: "txt"),
    PaletteExportType.adobe:PaletteExportData(name: "ADOBE", extension: "ase"),
    PaletteExportType.jasc:PaletteExportData(name: "JASC", extension: "pal"),
    PaletteExportType.corel:PaletteExportData(name: "COREL", extension: "xml"),
    PaletteExportType.openOffice:PaletteExportData(name: "STAROFFICE", extension: "soc"),
    PaletteExportType.json:PaletteExportData(name: "PIXELORAMA", extension: "json"),
    PaletteExportType.kpal:PaletteExportData(name: "KPAL", extension: fileExtensionKpal),
  };
}

/// Available export scaling values.
const List<int> exportScalingValues = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

/// [ExportData] specialization for images.
class ImageExportData extends ExportData
{
  final int scaling;
  final bool scalable;
  const ImageExportData({required super.name, required super.extension, required this.scalable, this.scaling = 1, super.fileName = "", super.directory = ""});
  factory ImageExportData.fromWithConcreteData({required final ImageExportData other, required final int scaling, required final String fileName, required final String directory})
  {
    return ImageExportData(name: other.name, extension: other.extension, scalable: other.scalable, scaling: scaling, directory: directory, fileName: fileName);
  }

  static const Map<ImageExportType, ImageExportData> exportTypeMap = <ImageExportType, ImageExportData>{
    ImageExportType.png : ImageExportData(name: "PNG", extension: "png", scalable: true),
    ImageExportType.aseprite : ImageExportData(name: "ASEPRITE", extension: "aseprite", scalable: false),
    ImageExportType.photoshop : ImageExportData(name: "PHOTOSHOP", extension: "psd", scalable: false),
    ImageExportType.gimp : ImageExportData(name: "GIMP", extension: "xcf", scalable: false),
    ImageExportType.pixelorama : ImageExportData(name: "PIXELORAMA", extension: "pxo", scalable: false),
    ImageExportType.texturePack : ImageExportData(name: "TEXTURE PACK", extension: "zip", scalable: false),
    //NOT USED:
    ImageExportType.kpix : ImageExportData(name: "KPIX", extension: fileExtensionKpix, scalable: false),
  };
}

/// [ExportData] specialization for animations.
class AnimationExportData extends ImageExportData
{
  final bool loopOnly;
  const AnimationExportData({required super.name, required super.extension, required super.scalable, super.scaling = 1, super.fileName = "", super.directory = "", this.loopOnly = false});
  factory AnimationExportData.fromWithConcreteData({required final AnimationExportData other, required final int scaling, required final String fileName, required final String directory, required final bool loopOnly})
  {
    return AnimationExportData(name: other.name, extension: other.extension, scalable: other.scalable, loopOnly: loopOnly, scaling: scaling, directory: directory, fileName: fileName);
  }
  static const Map<AnimationExportType, AnimationExportData> exportTypeMap = <AnimationExportType, AnimationExportData>{
    AnimationExportType.gif : AnimationExportData(name: "GIF", extension: "gif", scalable: true, ),
    AnimationExportType.apng : AnimationExportData(name: "APNG", extension: "apng", scalable: true, ),
    AnimationExportType.zippedPng : AnimationExportData(name: "PNG SEQUENCE", extension: "zip", scalable: true, ),
    //AnimationExportType.aseprite : AnimationExportData(name: "ASEPRITE", extension: "aseprite", scalable: false),
    //AnimationExportType.pixelorama : AnimationExportData(name: "PIXELORAMA", extension: "pxo", scalable: false),
    AnimationExportType.texturePack : AnimationExportData(name: "TEXTURE PACK", extension: "zip", scalable: false, ),
  };
}

/// The screen for showing all the options for exporting a project.
