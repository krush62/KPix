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

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert' show utf8;

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/managers/history_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/util/color_names.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:kpix/widgets/main/layer_widget.dart';

class ExportFunctions
{
  static Future<Uint8List?> exportPNG({required ExportData exportData, required final AppState appState}) async
  {
    final ByteData byteData = await _getImageData(
        ramps: appState.colorRamps,
        layers: appState.layers,
        selectionState: appState.selectionState,
        imageSize: appState.canvasSize,
        scaling: exportData.scaling,
        selectedLayer: appState.currentLayer);

    final Completer<ui.Image> c = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        byteData.buffer.asUint8List(),
        appState.canvasSize.x * exportData.scaling,
        appState.canvasSize.y * exportData.scaling,
        ui.PixelFormat.rgba8888, (ui.Image convertedImage)
    {
      c.complete(convertedImage);
    }
    );
    final ui. Image img = await c.future;

    ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return pngBytes!.buffer.asUint8List();
  }

  static Future<ByteData> _getImageData({required final List<KPalRampData> ramps, required final List<LayerState> layers, required SelectionState selectionState, required final CoordinateSetI imageSize, required final int scaling, required final LayerState? selectedLayer}) async
  {
    final ByteData byteData = ByteData((imageSize.x * scaling) * (imageSize.y * scaling) * 4);
    for (int x = 0; x < imageSize.x; x++)
    {
      for (int y = 0; y < imageSize.y; y++)
      {
        final CoordinateSetI currentCoord = CoordinateSetI(x: x, y: y);
        for (int l = 0; l < layers.length; l++)
        {
          if (layers[l].visibilityState.value == LayerVisibilityState.visible)
          {
            ColorReference? col;
            if (selectedLayer == layers[l])
            {
              col = selectionState.selection.getColorReference(coord: currentCoord);
            }
            col ??= layers[l].getDataEntry(coord: currentCoord);

            if (col != null)
            {
              for (int i = 0; i < scaling; i++)
              {
                for (int j = 0; j < scaling; j++)
                {
                  byteData.setUint32((((y * scaling) + j) * (imageSize.x * scaling) + ((x * scaling) + i)) * 4,
                      Helper.argbToRgba(argb: col.getIdColor().color.value));
                }
              }
              break;
            }
          }
        }
      }
    }
    return byteData;
  }

  static Future<Uint8List?> getPalettePngData({required List<KPalRampData> ramps}) async
  {
    final List<ui.Color> colorList = _getColorList(ramps: ramps);
    final ByteData byteData = await _getPaletteImageData(colorList: colorList);

    final Completer<ui.Image> c = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        byteData.buffer.asUint8List(),
        colorList.length,
        1,
        ui.PixelFormat.rgba8888, (ui.Image convertedImage)
    {
      c.complete(convertedImage);
    }
    );
    final ui. Image img = await c.future;

    ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return pngBytes!.buffer.asUint8List();
  }

  static Future<ByteData> _getPaletteImageData({required final List<ui.Color> colorList}) async
  {
    final ByteData byteData = ByteData(colorList.length * 4);
    for (int i = 0; i < colorList.length; i++)
    {
      byteData.setUint32(i * 4, Helper.argbToRgba(argb: colorList[i].value));
    }
    return byteData;
  }

  static List<ui.Color> _getColorList({required final List<KPalRampData> ramps})
  {
    final List<ui.Color> colorList = [];
    for (final KPalRampData ramp in ramps)
    {
      for (final ColorReference colRef in ramp.references)
      {
        colorList.add(colRef.getIdColor().color);
      }
    }
    return colorList;
  }

  static Future<Uint8List?> getPaletteAsepriteData({required final List<KPalRampData> rampList}) async
  {
    final List<ui.Color> colorList = _getColorList(ramps: rampList);
    colorList.insert(0, Colors.black);
    assert(colorList.length < 256);
    final List<List<int>> layerEncBytes = [];
    final List<Uint8List> layerNames = [];
    final List<int> imgBytes = [];
    for (int i = 0; i < colorList.length; i++)
    {
      imgBytes.add(i);
    }
    final List<int> encData = const ZLibEncoder().encode(imgBytes);
    layerEncBytes.add(encData);
    layerNames.add(utf8.encode("KPixPalette"));

    return _createAsepriteData(colorList: colorList, layerNames: layerNames, layerEncBytes: layerEncBytes, canvasSize: CoordinateSetI(x: colorList.length, y: 1));
  }

  static Future<Uint8List> getPaletteGimpData({required final List<KPalRampData> rampList, required final ColorNames colorNames}) async
  {
    final List<ui.Color> colorList = _getColorList(ramps: rampList);
    final StringBuffer stringBuffer = StringBuffer();
    stringBuffer.writeln("GIMP Palette");
    stringBuffer.writeln('Name: KPix_${DateTime.now().toString().replaceAll(RegExp(r'[:\- ]'), '_')}');
    stringBuffer.writeln('Columns: 16');
    stringBuffer.writeln('#');
    for (final ui.Color color in colorList)
    {
      stringBuffer.writeln('${color.red} ${color.green} ${color.blue} ${colorNames.getColorName(r: color.red, g: color.green, b: color.blue)}');
    }
    final String str = stringBuffer.toString();
    return Uint8List.fromList(utf8.encode(str));

  }

  static Future<Uint8List> getPalettePaintNetData({required final List<KPalRampData> rampList, required final ColorNames colorNames}) async
  {
    final List<ui.Color> colorList = _getColorList(ramps: rampList);
    final StringBuffer stringBuffer = StringBuffer();
    stringBuffer.writeln('; KPix_${DateTime.now().toString().replaceAll(RegExp(r'[:\- ]'), '_')}');
    for (int i = 0; i < colorList.length; i++)
    {
       stringBuffer.writeln("${Helper.colorToHexString(c: colorList[i], withHashTag: false).toUpperCase()} ; $i-${colorNames.getColorName(r: colorList[i].red, g: colorList[i].green, b: colorList[i].blue)}");
    }
    final String str = stringBuffer.toString();
    return Uint8List.fromList(utf8.encode(str));
  }

  static Future<Uint8List> getPaletteAdobeData({required final List<KPalRampData> rampList, required final ColorNames colorNames}) async
  {
    final List<ui.Color> colorList = _getColorList(ramps: rampList);
    final BytesBuilder buffer = BytesBuilder();
    buffer.add(Helper.intToBytes(value: 0x46455341, length: 4));
    buffer.add(Helper.intToBytes(value: 0x00000100, length: 4));
    buffer.add(Helper.intToBytes(value: colorList.length, length: 4, reverse: true));
    for (final ui.Color color in colorList)
    {
      final String colorName = colorNames.getColorName(r: color.red, g: color.green, b: color.blue);
      buffer.add(Helper.intToBytes(value: 0x0100, length: 2));
      buffer.add(Helper.intToBytes(value: (22 + (colorName.length * 2)), length: 4, reverse: true));
      buffer.add(Helper.intToBytes(value: (colorName.length + 1), length: 2, reverse: true));
      for (final int codeUnit in colorName.codeUnits)
      {
        if (codeUnit != '-'.codeUnitAt(0))
        {
          buffer.add(Helper.intToBytes(value: codeUnit, length: 2, reverse: true));
        }
      }
      buffer.add(Helper.intToBytes(value: 0, length: 2, reverse: true));

      buffer.add(Helper.stringToBytes(value: "RGB ")); // Color model

      // Color values
      buffer.add(Helper.float32ToBytes(value: (color.red.toDouble() / 255.0), reverse: true));
      buffer.add(Helper.float32ToBytes(value: (color.green.toDouble() / 255.0), reverse: true));
      buffer.add(Helper.float32ToBytes(value: (color.blue.toDouble() / 255.0), reverse: true));

      // Color type
      buffer.add(Helper.intToBytes(value: 0, length: 2, reverse: true));
    }
    return buffer.toBytes();
  }

  static Future<Uint8List> getPaletteJascData({required final List<KPalRampData> rampList}) async
  {
    final List<ui.Color> colorList = _getColorList(ramps: rampList);
    final StringBuffer stringBuffer = StringBuffer();
    stringBuffer.writeln("JASC-PAL");
    stringBuffer.writeln("0100");
    stringBuffer.writeln(colorList.length.toString());
    for (final ui.Color color in colorList)
    {
      stringBuffer.writeln("${color.red} ${color.green} ${color.blue}");
    }
    final String str = stringBuffer.toString();
    return Uint8List.fromList(utf8.encode(str));
  }

  static Future<Uint8List> getPaletteCorelData({required final List<KPalRampData> rampList, required final ColorNames colorNames}) async
  {
    final List<ui.Color> colorList = _getColorList(ramps: rampList);
    final StringBuffer stringBuffer = StringBuffer();
    stringBuffer.writeln("<? version = \"1.0\" ?>");
    stringBuffer.writeln("<palette name=\"\" guid=\"\">");
    stringBuffer.writeln("\t<colors>");
    stringBuffer.writeln("\t\t<page>");

    for (final ui.Color color in colorList)
    {
      stringBuffer.writeln('''\t\t\t<color cs="RGB" tints="${(color.red / 255.0).toStringAsFixed(6)},${(color.green / 255.0).toStringAsFixed(6)},${(color.blue / 255.0).toStringAsFixed(6)}"name="${Helper.escapeXml(input: colorNames.getColorName(r: color.red, g: color.green, b: color.blue))}" />''');
    }

    stringBuffer.writeln("\t\t</page>");
    stringBuffer.writeln("\t</colors>");
    stringBuffer.writeln("</palette>");

    final String str = stringBuffer.toString();
    return Uint8List.fromList(utf8.encode(str));
  }

  static Future<Uint8List> getPaletteOpenOfficeData({required final List<KPalRampData> rampList, required final ColorNames colorNames}) async
  {
    final List<ui.Color> colorList = _getColorList(ramps: rampList);
    final stringBuffer = StringBuffer();
    stringBuffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    stringBuffer.writeln(
        '<office:color-table xmlns:office="http://openoffice.org/2000/office" '
            'xmlns:style="http://openoffice.org/2000/style" '
            'xmlns:text="http://openoffice.org/2000/text" '
            'xmlns:table="http://openoffice.org/2000/table" '
            'xmlns:draw="http://openoffice.org/2000/drawing" '
            'xmlns:fo="http://www.w3.org/1999/XSL/Format" '
            'xmlns:xlink="http://www.w3.org/1999/xlink" '
            'xmlns:dc="http://purl.org/dc/elements/1.1/" '
            'xmlns:meta="http://openoffice.org/2000/meta" '
            'xmlns:number="http://openoffice.org/2000/datastyle" '
            'xmlns:svg="http://www.w3.org/2000/svg" '
            'xmlns:chart="http://openoffice.org/2000/chart" '
            'xmlns:dr3d="http://openoffice.org/2000/dr3d" '
            'xmlns:math="http://www.w3.org/1998/Math/MathML" '
            'xmlns:form="http://openoffice.org/2000/form" '
            'xmlns:script="http://openoffice.org/2000/script" '
            'xmlns:config="http://openoffice.org/2001/config">');

    for (final ui.Color color in colorList)
    {
      final String colorHex = Helper.colorToHexString(c: color).toLowerCase();
      final String colorName = Helper.escapeXml(input: colorNames.getColorName(r: color.red, g: color.green, b: color.blue));
      stringBuffer.writeln('\t<draw:color draw:name="$colorName" draw:color="$colorHex"/>');
    }

    stringBuffer.writeln('</office:color-table>');
    final String str = stringBuffer.toString();
    return Uint8List.fromList(utf8.encode(str));
  }



  static Future<Uint8List> _createAsepriteData({required final List<ui.Color> colorList, required final List<Uint8List> layerNames, required final List<List<int>> layerEncBytes, required final CoordinateSetI canvasSize, final List<LayerState>? layerList}) async
  {
    const int headerSize = 128;
    const int frameHeaderSize = 16;
    const int colorProfileSize = 22;
    final int paletteNewSize = 26 + (colorList.length * 6);
    final int paletteOldSize = 10 + (colorList.length * 3);

    //CALCULATE SIZE
    int fileSize = 0;
    fileSize += headerSize;
    fileSize += frameHeaderSize;
    fileSize += colorProfileSize;
    fileSize += paletteNewSize;
    fileSize += paletteOldSize;

    for (int i = 0; i < layerNames.length; i++)
    {
      fileSize += (24 + layerNames[i].length);
    }

    for (int i = 0; i < layerEncBytes.length; i++)
    {
      fileSize += (26 + layerEncBytes[i].length);
    }

    final ByteData outBytes = ByteData(fileSize);
    int offset = 0;

    //WRITE HEADER
    outBytes.setUint32(offset, fileSize, Endian.little); //file size
    offset+=4;
    outBytes.setUint16(offset, 0xA5E0, Endian.little); //magic number
    offset+=2;
    outBytes.setUint16(offset, 1, Endian.little); //frames
    offset+=2;
    outBytes.setUint16(offset, canvasSize.x, Endian.little); //width
    offset+=2;
    outBytes.setUint16(offset, canvasSize.y, Endian.little); //height
    offset+=2;
    outBytes.setUint16(offset, 8, Endian.little); //color depth
    offset+=2;
    outBytes.setUint32(offset, 1, Endian.little); //flags
    offset+=4;
    outBytes.setUint16(offset, 100, Endian.little); //speed
    offset+=2;
    outBytes.setUint32(offset, 0, Endian.little); //empty
    offset+=4;
    outBytes.setUint32(offset, 0, Endian.little); //empty
    offset+=4;
    outBytes.setUint8(offset, 0); //transparent index
    offset++;
    for (int i = 0; i < 3; i++) //ignore bytes
    {
      outBytes.setUint8(offset, 0);
      offset++;
    }
    outBytes.setUint16(offset, colorList.length, Endian.little); //color count
    offset+=2;
    outBytes.setUint8(offset, 1); //pixel width
    offset++;
    outBytes.setUint8(offset, 1); //pixel height
    offset++;
    outBytes.setInt16(offset, 0, Endian.little); //x pos grid
    offset+=2;
    outBytes.setInt16(offset, 0, Endian.little); //y pos grid
    offset+=2;
    outBytes.setUint16(offset, 16, Endian.little); //grid width
    offset+=2;
    outBytes.setUint16(offset, 16, Endian.little); //grid height
    offset+=2;
    for (int i = 0; i < 84; i++) //future bytes
    {
      outBytes.setUint8(offset, 0);
      offset++;
    }

    //FRAMES HEADER
    outBytes.setUint32(offset, fileSize - headerSize, Endian.little); //frame size
    offset+=4;
    outBytes.setUint16(offset, 0xF1FA, Endian.little); //magic number
    offset+=2;
    outBytes.setUint16(offset, 3 + (layerEncBytes.length * 2), Endian.little); //chunk count
    offset+=2;
    outBytes.setUint16(offset, 100, Endian.little); //duration
    offset+=2;
    for (int i = 0; i < 2; i++) //empty bytes
    {
      outBytes.setUint8(offset, 0);
      offset++;
    }
    outBytes.setUint32(offset, 3 + (layerEncBytes.length * 2), Endian.little); //chunk count
    offset+=4;

    //COLOR PROFILE
    outBytes.setUint32(offset, colorProfileSize, Endian.little); //chunk size
    offset+=4;
    outBytes.setUint16(offset, 0x2007, Endian.little); //chunk type
    offset+=2;
    outBytes.setUint16(offset, 1, Endian.little); //profile type
    offset+=2;
    outBytes.setUint16(offset, 0, Endian.little); //flags
    offset+=2;
    outBytes.setUint32(offset, 0, Endian.little); //gamma
    offset+=4;
    for (int i = 0; i < 8; i++) //reserved
    {
      outBytes.setUint8(offset, 0);
      offset++;
    }

    //PALETTE
    outBytes.setUint32(offset, paletteNewSize, Endian.little); //chunk size
    offset+=4;
    outBytes.setUint16(offset, 0x2019, Endian.little); //chunk type
    offset+=2;
    outBytes.setUint32(offset, colorList.length, Endian.little); //color count
    offset+=4;
    outBytes.setUint32(offset, 0, Endian.little); //first color index
    offset+=4;
    outBytes.setUint32(offset, colorList.length - 1, Endian.little); //last color index
    offset+=4;
    for (int i = 0; i < 8; i++) //reserved
    {
      outBytes.setUint8(offset, 0);
      offset++;
    }
    for (int i = 0; i < colorList.length; i++)
    {
      outBytes.setUint16(offset, 0, Endian.little); //has name
      offset+=2;
      outBytes.setUint8(offset, colorList[i].red); //red
      offset++;
      outBytes.setUint8(offset, colorList[i].green); //green
      offset++;
      outBytes.setUint8(offset, colorList[i].blue); //blue
      offset++;
      outBytes.setUint8(offset, 255); //alpha
      offset++;
    }

    //PALETTE OLD
    outBytes.setUint32(offset, paletteOldSize, Endian.little); //chunk size
    offset+=4;
    outBytes.setUint16(offset, 0x0004, Endian.little); //chunk type
    offset+=2;
    outBytes.setUint16(offset, 1, Endian.little); //packet count
    offset+=2;
    outBytes.setUint8(offset, 0); //skip entries
    offset++;
    outBytes.setUint8(offset, colorList.length); //color count
    offset++;
    for (int i = 0; i < colorList.length; i++)
    {
      outBytes.setUint8(offset, colorList[i].red); //red
      offset++;
      outBytes.setUint8(offset, colorList[i].green); //green
      offset++;
      outBytes.setUint8(offset, colorList[i].blue); //blue
      offset++;
    }

    //LAYERS AND CELS
    for (int i = layerEncBytes.length - 1; i >= 0 ; i--)
    {
      //LAYER
      outBytes.setUint32(offset, 24 + layerNames[i].length, Endian.little); //chunk size
      offset+=4;
      outBytes.setUint16(offset, 0x2004, Endian.little); //chunk type
      offset+=2;
      int flagVal = 0;
      if (layerList != null)
      {
        if (layerList[i].visibilityState.value == LayerVisibilityState.visible)
        {
          flagVal += 1;
        }
        if (layerList[i].lockState.value != LayerLockState.locked)
        {
          flagVal += 2;
        }
      }
      else
      {
        flagVal += 1;
        flagVal += 2;
      }

      outBytes.setUint16(offset, flagVal, Endian.little); //flags
      offset+=2;
      outBytes.setUint16(offset, 0, Endian.little); //type
      offset+=2;
      outBytes.setUint16(offset, 0, Endian.little); //child level
      offset+=2;
      outBytes.setUint16(offset, 0, Endian.little); //ignored width
      offset+=2;
      outBytes.setUint16(offset, 0, Endian.little); //ignored height
      offset+=2;
      outBytes.setUint16(offset, 0, Endian.little); //blend mode
      offset+=2;
      outBytes.setUint8(offset, 255); //opacity
      offset++;
      for (int j = 0; j < 3; j++) //reserved
      {
        outBytes.setUint8(offset, 0);
        offset++;
      }
      outBytes.setUint16(offset, layerNames[i].length, Endian.little); //name length
      offset+=2;

      for (int j = 0; j < layerNames[i].length; j++) //name
      {
        outBytes.setUint8(offset, layerNames[(layerEncBytes.length - 1) - i][j]);
        offset++;
      }

      //CEL
      outBytes.setUint32(offset, 26 + layerEncBytes[i].length, Endian.little); //chunk size
      offset+=4;
      outBytes.setUint16(offset, 0x2005, Endian.little); //chunk type
      offset+=2;
      outBytes.setUint16(offset, (layerEncBytes.length - 1) - i, Endian.little); //layer index
      offset+=2;
      outBytes.setInt16(offset, 0, Endian.little); //x pos
      offset+=2;
      outBytes.setInt16(offset, 0, Endian.little); //y pos
      offset+=2;
      outBytes.setUint8(offset, 255); //opacity
      offset++;
      outBytes.setUint16(offset, 2, Endian.little); //cel type
      offset+=2;
      outBytes.setInt16(offset, 0, Endian.little); //z index
      offset+=2;
      for (int j = 0; j < 5; j++) //reserved
      {
        outBytes.setUint8(offset, 0);
        offset++;
      }
      if (layerList != null)
      {
        outBytes.setUint16(offset, layerList[i].size.x, Endian.little); //width
        offset+=2;
        outBytes.setUint16(offset, layerList[i].size.y, Endian.little); //height
        offset+=2;
      }
      else
      {
        outBytes.setUint16(offset, canvasSize.x, Endian.little); //width
        offset+=2;
        outBytes.setUint16(offset, canvasSize.y, Endian.little); //height
        offset+=2;
      }

      for (int j = 0; j < layerEncBytes[i].length; j++)
      {
        outBytes.setUint8(offset, layerEncBytes[i][j]);
        offset++;
      }
    }
    return outBytes.buffer.asUint8List();
  }

  static Future<ByteData> getKPixData({required final AppState appState}) async
  {
    //TODO perform sanity checks (max ramps, max layers, etc...)
    final HistoryState saveData = HistoryState.fromAppState(appState: appState, description: "saveData");
    final ByteData byteData = ByteData(_calculateKPixFileSize(saveData: saveData));

    int offset = 0;
    //header
    byteData.setUint32(offset, int.parse(FileHandler.magicNumber, radix: 16));
    offset+=4;
    //file version
    byteData.setUint8(offset++, FileHandler.fileVersion);

    //rampCount
    byteData.setUint8(offset++, saveData.rampList.length);
    //color ramps
    for (int i = 0; i < saveData.rampList.length; i++)
    {
      final KPalRampSettings rampSettings = saveData.rampList[i].settings;
      //color count
      byteData.setUint8(offset++, rampSettings.colorCount);
      //base hue
      byteData.setUint16(offset, rampSettings.baseHue);
      offset+=2;
      //base sat
      byteData.setUint8(offset++, rampSettings.baseSat);
      //hue shift
      byteData.setInt8(offset++, rampSettings.hueShift);
      //hue shift exp
      byteData.setUint8(offset++, (rampSettings.hueShiftExp * 100).round());
      //sat shift
      byteData.setInt8(offset++, rampSettings.satShift);
      //sat shift exp
      byteData.setUint8(offset++, (rampSettings.satShiftExp * 100).round());
      //sat curve
      int satCurveVal = 0;
      for (int j = 0; i < satCurveMap.length; j++)
      {
        if (satCurveMap[j] == rampSettings.satCurve)
        {
          satCurveVal = j;
          break;
        }
      }
      byteData.setUint8(offset++, satCurveVal);
      //val min
      byteData.setUint8(offset++, rampSettings.valueRangeMin);
      //val max
      byteData.setUint8(offset++, rampSettings.valueRangeMax);
      //color shifts
      for (int j = 0; j < rampSettings.colorCount; j++)
      {
        //hue shift
        byteData.setInt8(offset++, saveData.rampList[i].shiftSets[j].hueShift);
        //sat shift
        byteData.setInt8(offset++, saveData.rampList[i].shiftSets[j].satShift);
        //val shift
        byteData.setInt8(offset++, saveData.rampList[i].shiftSets[j].valShift);
      }
    }

    //columns
    byteData.setUint16(offset, saveData.canvasSize.x);
    offset+=2;
    //rows
    byteData.setUint16(offset, saveData.canvasSize.y);
    offset+=2;
    //layer count
    byteData.setUint8(offset++, saveData.layerList.length);
    //layers
    for (int i = 0; i < saveData.layerList.length; i++)
    {
      //layer type
      byteData.setUint8(offset++, 1);
      //visibility
      int visVal = 0;
      for (int j = 0; j < layerVisibilityStateValueMap.length; j++)
      {
        if (layerVisibilityStateValueMap[j] == saveData.layerList[i].visibilityState)
        {
          visVal = j;
          break;
        }
      }
      byteData.setUint8(offset++, visVal);
      //lock type
      int lockVal = 0;
      for (int j = 0; j < layerLockStateValueMap.length; j++)
      {
        if (layerLockStateValueMap[j] == saveData.layerList[i].lockState)
        {
          lockVal = j;
          break;
        }
      }
      byteData.setUint8(offset++, lockVal);
      //data count
      final int dataLength = saveData.layerList[i].data.length;
      byteData.setUint32(offset, dataLength);
      offset+=4;
      //image data
      for (final MapEntry<CoordinateSetI, HistoryColorReference> entry in saveData.layerList[i].data.entries)
      {
        //x
        byteData.setUint16(offset, entry.key.x);
        offset+=2;
        //y
        byteData.setUint16(offset, entry.key.y);
        offset+=2;
        //ramp index
        byteData.setUint8(offset++, entry.value.rampIndex);
        //color index
        byteData.setUint8(offset++, entry.value.colorIndex);
      }
    }

    return byteData;
  }

  static Future<Uint8List> getPaletteKPalData({required final List<KPalRampData> rampList}) async
  {
    //TODO perform sanity checks (ramp count, color count, ...)
    final ByteData byteData = ByteData(_calculateKPalFileSize(rampList: rampList));
    int offset = 0;

    //options
    byteData.setUint8(offset++, 0);

    //ramp count
    byteData.setUint8(offset++, rampList.length);
    for (final KPalRampData rampData in rampList)
    {
      //name length
      byteData.setUint8(offset++, 0);
      //color count
      byteData.setUint8(offset++, rampData.settings.colorCount);
      //base hue
      byteData.setUint16(offset, rampData.settings.baseHue, Endian.little);
      offset += 2;
      //base sat
      byteData.setUint16(offset, rampData.settings.baseSat, Endian.little);
      offset += 2;
      //hue shift
      byteData.setUint8(offset++, rampData.settings.hueShift);
      //hueShiftExp
      byteData.setFloat32(offset, rampData.settings.hueShiftExp, Endian.little);
      offset += 4;
      //sat shift
      byteData.setUint8(offset++, rampData.settings.satShift);
      //satShiftExp
      byteData.setFloat32(offset, rampData.settings.satShiftExp, Endian.little);
      offset += 4;
      //val min
      byteData.setUint8(offset++, rampData.settings.valueRangeMin);
      //val max
      byteData.setUint8(offset++, rampData.settings.valueRangeMax);
      for (int j = 0; j < rampData.settings.colorCount; j++)
      {
        //hue shift
        byteData.setUint8(offset++, rampData.shifts[j].hueShiftNotifier.value);
        //sat shift
        byteData.setUint8(offset++, rampData.shifts[j].satShiftNotifier.value);
        //val shift
        byteData.setUint8(offset++, rampData.shifts[j].valShiftNotifier.value);
      }
      //ramp option count
      byteData.setUint8(offset++, 1);
      //sat curve option
      byteData.setUint8(offset++, 1); //option type sat curve
      //sat curve value
      byteData.setUint8(offset++, kpixKpalSatCurveMap[rampData.settings.satCurve]?? 0);
    }

    //link count
    byteData.setUint8(offset++, 0);

    return byteData.buffer.asUint8List();
  }

  static Future<Uint8List?> getAsepriteData({required final ExportData exportData, required final AppState appState}) async
  {
    final List<ui.Color> colorList = [];
    final Map<ColorReference, int> colorMap = {};
    colorList.add(Colors.black);
    int index = 1;
    for (final KPalRampData kPalRampData in appState.colorRamps)
    {
      for (int i = 0; i < kPalRampData.shiftedColors.length; i++)
      {
        colorList.add(kPalRampData.shiftedColors[i].value.color);
        colorMap[kPalRampData.references[i]] = index;
        index++;
      }
    }
    assert(colorList.length < 256);

    final List<List<int>> layerEncBytes = [];
    final List<Uint8List> layerNames = [];
    for (int l = 0; l < appState.layers.length; l++)
    {
      final LayerState layerState = appState.layers[l];
      final List<int> imgBytes = [];
      for (int y = 0; y < layerState.size.y; y++)
      {
        for (int x = 0; x < layerState.size.x; x++)
        {
          final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);
          final ColorReference? colAtPos = layerState.getDataEntry(coord: curCoord);
          if (colAtPos == null)
          {
            imgBytes.add(0);
          }
          else
          {
            imgBytes.add(colorMap[colAtPos]!);
          }
        }
      }

      final List<int> encData = const ZLibEncoder().encode(imgBytes);
      layerEncBytes.add(encData);
      layerNames.add(utf8.encode("Layer$l"));
    }

    return _createAsepriteData(colorList: colorList, layerNames: layerNames, layerEncBytes: layerEncBytes, canvasSize: appState.canvasSize, layerList: appState.layers);
  }

  static Future<Uint8List?> getGimpData({required final ExportData exportData, required final AppState appState}) async
  {
    final List<Color> colorList = [];
    final Map<ColorReference, int> colorMap = {};
    int index = 0;
    for (final KPalRampData kPalRampData in appState.colorRamps)
    {
      for (int i = 0; i < kPalRampData.shiftedColors.length; i++)
      {
        colorList.add(kPalRampData.shiftedColors[i].value.color);
        colorMap[kPalRampData.references[i]] = index;
        index++;
      }
    }
    assert(colorList.length < 256);

    final int fullHeaderSize = 30 + //header
        12 + (3 * colorList.length) + //color map
        9 + //compression
        16 + //resolution
        12 + //tattoo
        12 + //unit
        8 + //prop end
        8 + (appState.layers.length * 8) + //layer addresses
        8; //channel addresses

    //LAYER (without name and active layer prop)
    const int singleLayerSize =
        8 + //width
            8 + //height
            8 + //type
            12 + //opacity
            12 + //float opacity
            12 + //visible
            12 + //linked
            12 + //color tag
            12 + //lock content
            12 + //lock alpha
            12 + //lock position
            12 + //apply mask
            12 + //edit mask
            12 + //show mask
            16 + //offsets
            12 + //mode
            12 + //blend space
            12 + //composite space
            12 + //composite mode
            12 + //tattoo
            8 + //prop end
            8 + //hierarchy ptr
            8; //layer mask ptr

    //HIERARCHY
    const int hierarchySize = 4 + //width
        4 + //height
        4 + //bpp
        (4 * 8); //level pointers and end

    //LEVEL
    const int basicLevelSize = 4 + //width
        4 + //height
        8; //pointer end

    final List<List<List<int>>> layerEncBytes = [];
    final List<Uint8List> layerNames = [];
    const int tileSize = 64;
    for (int l = 0; l < appState.layers.length; l++)
    {
      final LayerState layerState = appState.layers[l];
      int x = 0;
      int y = 0;
      final List<List<int>> tileList = [];
      do //TILING
          {
        final List<int> imgBytes = [];
        int endX = min(x + tileSize, layerState.size.x);
        int endY = min(y + tileSize, layerState.size.y);
        for (int b = y; b < endY; b++)
        {
          for (int a = x; a < endX; a++)
          {
            final CoordinateSetI curCoord = CoordinateSetI(x: a, y: b);
            final ColorReference? colAtPos = layerState.getDataEntry(coord: curCoord);
            if (colAtPos == null)
            {
              imgBytes.add(0);
              imgBytes.add(0);
            }
            else
            {
              imgBytes.add(colorMap[colAtPos]!);
              imgBytes.add(255);
            }

          }

        }
        final List<int> encData = const ZLibEncoder().encode(imgBytes);
        tileList.add(encData);

        x = (endX >= layerState.size.x) ? 0 : endX;
        y = (endX >= layerState.size.x) ? endY : y;
      }
      while (y < layerState.size.y);

      layerNames.add(utf8.encode("Layer$l"));
      layerEncBytes.add(tileList);
    }

    //CALCULATING SIZE
    bool activeLayerSet = false;
    int fileSize = fullHeaderSize;
    for (int i = 0; i < appState.layers.length; i++)
    {
      final List<List<int>> tiles = layerEncBytes[i];
      fileSize += singleLayerSize;
      if (!activeLayerSet)
      {
        fileSize += 8; //ACTIVE LAYER
        activeLayerSet = true;
      }
      //name
      fileSize += 4 + layerNames[i].length + 1;
      //hierarchy
      fileSize += hierarchySize;
      //level 1
      fileSize += basicLevelSize;
      //tile data
      for (final List<int> tileData in tiles)
      {
        fileSize += tileData.length;
      }
      fileSize += tiles.length * 8;
      //level 2
      fileSize += (basicLevelSize - 4);
      //level3
      fileSize += (basicLevelSize - 4);
    }


    //WRITING

    final List<int> layerOffsetsInsertPositions = [];

    int tattooIndex = 2;
    final ByteData outBytes = ByteData(fileSize);
    int offset = 0;

    //header
    final Uint8List fileType = utf8.encode("gimp xcf ");
    final Uint8List version = utf8.encode("v011");
    for (int i = 0; i < fileType.length; i++)
    {
      outBytes.setUint8(offset, fileType[i]);
      offset++;
    }

    for (int i = 0; i < version.length; i++)
    {
      outBytes.setUint8(offset, version[i]);
      offset++;
    }

    outBytes.setUint8(offset, 0);
    offset++;
    outBytes.setUint32(offset, appState.canvasSize.x); //width;
    offset+=4;
    outBytes.setUint32(offset, appState.canvasSize.y); //height
    offset+=4;
    outBytes.setUint32(offset, 2); //base type (2=indexed)
    offset+=4;
    outBytes.setUint32(offset, 150); //precision (8-bit gamma)
    offset+=4;

    //prop list

    //PROP_COLORMAP
    outBytes.setUint32(offset, 1);
    offset+=4;
    outBytes.setUint32(offset, (3 * colorList.length) + 4);
    offset+=4;
    outBytes.setUint32(offset, colorList.length);
    offset+=4;
    for (final Color c in colorList)
    {
      outBytes.setUint8(offset, c.red);
      offset++;
      outBytes.setUint8(offset, c.green);
      offset++;
      outBytes.setUint8(offset, c.blue);
      offset++;
    }

    //PROP_COMPRESSION
    outBytes.setUint32(offset, 17);
    offset+=4;
    outBytes.setUint32(offset, 1);

    offset+=4;
    outBytes.setUint8(offset, 2);
    offset++;

    //PROP_RESOLUTION
    outBytes.setUint32(offset, 19);
    offset+=4;
    outBytes.setUint32(offset, 8);
    offset+=4;
    outBytes.setFloat32(offset, 300);
    offset+=4;
    outBytes.setFloat32(offset, 300);
    offset+=4;

    //PROP_TATTOO
    outBytes.setUint32(offset, 20);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setUint32(offset, tattooIndex++);
    offset+=4;

    //PROP_UNIT
    outBytes.setUint32(offset, 22);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setUint32(offset, 1);
    offset+=4;

    //PROP_END
    outBytes.setUint32(offset, 0);
    offset+=4;
    outBytes.setUint32(offset, 0);
    offset+=4;

    //LAYER POINTERS
    for (int i = 0; i < appState.layers.length; i++)
    {
      layerOffsetsInsertPositions.add(offset);
      FileHandler.setUint64(bytes: outBytes, offset: offset, value: 0);
      offset+=8;
    }

    FileHandler.setUint64(bytes: outBytes, offset: offset, value: 0); //end layer pointers
    offset+=8;
    FileHandler.setUint64(bytes: outBytes, offset: offset, value: 0); //start/end channel pointers
    offset+=8;


    //LAYERS
    for (int i = 0; i < appState.layers.length; i++)
    {
      FileHandler.setUint64(bytes: outBytes, offset: layerOffsetsInsertPositions[i], value: offset);

      final LayerState currentLayer = appState.layers[i];
      outBytes.setUint32(offset, currentLayer.size.x);
      offset+=4;
      outBytes.setUint32(offset, currentLayer.size.y);
      offset+=4;
      outBytes.setUint32(offset, 5);
      offset+=4;
      outBytes.setUint32(offset, layerNames[i].length + 1);
      offset+=4;
      for (int j = 0; j < layerNames[i].length; j++)
      {
        outBytes.setUint8(offset, layerNames[i][j]);
        offset++;
      }
      outBytes.setUint8(offset, 0);
      offset++;

      //PROP_ACTIVE_LAYER
      if (i == 0)
      {
        outBytes.setUint32(offset, 2);
        offset+=4;
        outBytes.setUint32(offset, 0);
        offset+=4;
      }

      //PROP_OPACITY
      outBytes.setUint32(offset, 6);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 255);
      offset+=4;

      //PROP_FLOAT_OPACITY
      outBytes.setUint32(offset, 33);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setFloat32(offset, 1.0);
      offset+=4;

      //PROP_VISIBLE
      outBytes.setUint32(offset, 8);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, currentLayer.visibilityState.value == LayerVisibilityState.visible ? 1 : 0);
      offset+=4;

      //PROP_LINKED
      outBytes.setUint32(offset, 9);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //PROP_COLOR_TAG
      outBytes.setUint32(offset, 34);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //PROP_LOCK_CONTENT
      outBytes.setUint32(offset, 28);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, currentLayer.lockState.value == LayerLockState.locked ? 1 : 0);
      offset+=4;

      //PROP_LOCK_ALPHA
      outBytes.setUint32(offset, 10);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, currentLayer.lockState.value == LayerLockState.transparency ? 1 : 0);
      offset+=4;

      //PROP_LOCK_POSITION
      outBytes.setUint32(offset, 32);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //PROP_APPLY_MASK
      outBytes.setUint32(offset, 11);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //PROP_EDIT_MASK
      outBytes.setUint32(offset, 12);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //PROP_SHOW_MASK
      outBytes.setUint32(offset, 13);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //PROP_OFFSETS
      outBytes.setUint32(offset, 15);
      offset+=4;
      outBytes.setUint32(offset, 8);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //PROP_MODE
      outBytes.setUint32(offset, 7);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 28);
      offset+=4;

      //PROP_BLEND_SPACE
      outBytes.setUint32(offset, 37);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //PROP_COMPOSITE_SPACE
      outBytes.setUint32(offset, 36);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setInt32(offset, -1);
      offset+=4;

      //PROP_COMPOSITE_MODE
      outBytes.setUint32(offset, 35);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setInt32(offset, -1);
      offset+=4;

      //PROP_TATTOO
      outBytes.setUint32(offset, 20);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, tattooIndex++);
      offset+=4;

      //PROP_END
      outBytes.setUint32(offset, 0);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //HIERARCHY OFFSET
      final int hierarchyOffsetInsertPosition = offset;
      FileHandler.setUint64(bytes: outBytes, offset: offset, value: 0);
      offset+=8;

      //LAYER MASK
      FileHandler.setUint64(bytes: outBytes, offset: offset, value: 0);
      offset+=8;

      //HIERARCHY
      FileHandler.setUint64(bytes: outBytes, offset: hierarchyOffsetInsertPosition, value: offset);
      outBytes.setUint32(offset, currentLayer.size.x);
      offset+=4;
      outBytes.setUint32(offset, currentLayer.size.y);
      offset+=4;
      outBytes.setUint32(offset, 2);
      offset+=4;
      final int pointerInsertToLevel1 = offset;
      FileHandler.setUint64(bytes: outBytes, offset: offset, value: 0);
      offset+=8;
      final int pointerInsertToLevel2 = offset;
      FileHandler.setUint64(bytes: outBytes, offset: offset, value: 0);
      offset+=8;
      final int pointerInsertToLevel3 = offset;
      FileHandler.setUint64(bytes: outBytes, offset: offset, value: 0);
      offset+=8;
      FileHandler.setUint64(bytes: outBytes, offset: offset, value: 0);
      offset+=8;

      //LEVEL1
      FileHandler.setUint64(bytes: outBytes, offset: pointerInsertToLevel1, value: offset);
      outBytes.setUint32(offset, currentLayer.size.x);
      offset+=4;
      outBytes.setUint32(offset, currentLayer.size.y);
      offset+=4;
      final List<int> tileOffsetsLv1 = [];
      final List<List<int>> currentTiles = layerEncBytes[i];
      for (int j = 0; j < currentTiles.length; j++)
      {
        tileOffsetsLv1.add(offset);
        FileHandler.setUint64(bytes: outBytes, offset: offset, value: 0);
        offset+=8;
      }
      FileHandler.setUint64(bytes: outBytes, offset: offset, value: 0);
      offset+=8;

      //TILE DATA FOR LEVEL1
      for (int j = 0; j < currentTiles.length; j++)
      {
        FileHandler.setUint64(bytes: outBytes, offset: tileOffsetsLv1[j], value: offset);
        final List<int> currentTile = currentTiles[j];
        for (int k = 0; k < currentTile.length; k++)
        {
          outBytes.setUint8(offset, currentTile[k]);
          offset++;
        }
      }

      //LEVEL2
      FileHandler.setUint64(bytes: outBytes, offset: pointerInsertToLevel2, value: offset);
      outBytes.setUint32(offset, currentLayer.size.x ~/ 2);
      offset+=4;
      outBytes.setUint32(offset, currentLayer.size.y ~/ 2);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;
      //LEVEL3
      FileHandler.setUint64(bytes: outBytes, offset: pointerInsertToLevel3, value: offset);
      outBytes.setUint32(offset, currentLayer.size.x ~/ 4);
      offset+=4;
      outBytes.setUint32(offset, currentLayer.size.y ~/ 4);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;
    }

    return outBytes.buffer.asUint8List();
  }

  static int _calculateKPixFileSize({required final HistoryState saveData})
  {
    int size = 0;

    //header
    size += 4;
    //file version
    size += 1;

    //ramp count
    size += 1;
    for (int i = 0; i < saveData.rampList.length; i++)
    {
      //color count
      size += 1;
      //base hue
      size += 2;
      //base sat
      size += 1;
      //hue shift
      size += 1;
      //hue shift exp
      size += 1;
      //sat shift
      size += 1;
      //sat shift exp
      size += 1;
      //sat curve
      size += 1;
      //val min
      size += 1;
      //val max
      size += 1;
      for (int j = 0; j < saveData.rampList[i].settings.colorCount; j++)
      {
        //hue shift
        size += 1;
        //sat shift
        size += 1;
        //val shift
        size += 1;
      }
    }

    //columns
    size += 2;
    //rows
    size += 2;
    //layer count
    size += 1;
    for (int i = 0; i < saveData.layerList.length; i++)
    {
      //type
      size += 1;
      //visibility
      size += 1;
      //lock type
      size += 1;
      //data count
      size += 4;
      for (int j = 0; j < saveData.layerList[i].data.length; j++)
      {
        //x
        size += 2;
        //y
        size += 2;
        //color ramp index
        size += 1;
        //color index
        size += 1;
      }
    }


    return size;
  }

  static int _calculateKPalFileSize({required final List<KPalRampData> rampList})
  {
    int size = 0;

    //option count
    size += 1;

    //ramp count
    size += 1;
    for (int i = 0; i < rampList.length; i++)
    {
      //name
      size += 1;
      //color count
      size += 1;
      //base hue
      size += 2;
      //base sat
      size += 2;
      //hue shift
      size += 1;
      //hue shift exp
      size += 4;
      //sat shift
      size += 1;
      //sat shift exp
      size += 4;
      //val min
      size += 1;
      //val max
      size += 1;
      for (int j = 0; j < rampList[i].settings.colorCount; j++)
      {
        //hue shift
        size += 1;
        //sat shift
        size += 1;
        //val shift
        size += 1;
      }
      //ramp option count
      size += 1;
      //sat curve option type
      size += 1;
      //sat curve option value
      size += 1;
    }

    //link count
    size += 1;

    return size;
  }

}