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
import 'dart:collection';
import 'dart:convert' show utf8;
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/managers/history/history_dither_layer.dart';
import 'package:kpix/managers/history/history_drawing_layer.dart';
import 'package:kpix/managers/history/history_grid_layer.dart';
import 'package:kpix/managers/history/history_reference_layer.dart';
import 'package:kpix/managers/history/history_shading_layer.dart';
import 'package:kpix/managers/history/history_state.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/color_names.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/controls/kpix_direction_widget.dart';
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/tools/grid_layer_options_widget.dart';


  Map<Type, int> historyLayerValueMap =
  <Type, int>{
    HistoryDrawingLayer: 1,
    HistoryReferenceLayer: 2,
    HistoryGridLayer: 3,
    HistoryShadingLayer: 4,
    HistoryDitherLayer: 5,
  };

  Map<GridType, int> gridTypeValueMap =
  <GridType, int>{
    GridType.rectangular: 0,
    GridType.diagonal: 1,
    GridType.isometric: 2,
    GridType.hexagonal: 3,
    GridType.triangular: 4,
    GridType.brick: 5,
    GridType.onePointPerspective: 6,
    GridType.twoPointPerspective: 7,
    GridType.threePointPerspective: 8,
  };


  Future<Uint8List?> exportPNG({required final ExportData exportData, required final AppState appState}) async
  {
    final ByteData byteData = await _getImageData(
      scaling: exportData.scaling,
      appState: appState,
      );


    final Completer<ui.Image> c = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        byteData.buffer.asUint8List(),
        appState.canvasSize.x * exportData.scaling,
        appState.canvasSize.y * exportData.scaling,
        ui.PixelFormat.rgba8888, (final ui.Image convertedImage)
    {
      c.complete(convertedImage);
    }
    );
    final ui. Image img = await c.future;

    final ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return pngBytes!.buffer.asUint8List();
  }

Future<ByteData> _getImageData({required final AppState appState, required final int scaling}) async
{
  final ui.Image i = await getImageFromLayers(appState: appState, scalingFactor: scaling);
  return (await i.toByteData())!;
}

  Future<Uint8List?> getPalettePngData({required final List<KPalRampData> ramps}) async
  {
    final List<ui.Color> colorList = _getColorList(ramps: ramps);
    final ByteData byteData = await _getPaletteImageData(colorList: colorList);

    final Completer<ui.Image> c = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        byteData.buffer.asUint8List(),
        colorList.length,
        1,
        ui.PixelFormat.rgba8888, (final ui.Image convertedImage)
    {
      c.complete(convertedImage);
    }
    );
    final ui. Image img = await c.future;

    final ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return pngBytes!.buffer.asUint8List();
  }

  Future<ByteData> _getPaletteImageData({required final List<ui.Color> colorList}) async
  {
    final ByteData byteData = ByteData(colorList.length * 4);
    for (int i = 0; i < colorList.length; i++)
    {
      byteData.setUint32(i * 4, argbToRgba(argb: colorList[i].toARGB32()));
    }
    return byteData;
  }

  List<ui.Color> _getColorList({required final List<KPalRampData> ramps})
  {
    final List<ui.Color> colorList = <ui.Color>[];
    for (final KPalRampData ramp in ramps)
    {
      for (final ColorReference colRef in ramp.references)
      {
        colorList.add(colRef.getIdColor().color);
      }
    }
    return colorList;
  }

  Future<Uint8List?> getPaletteAsepriteData({required final List<KPalRampData> rampList}) async
  {
    final List<ui.Color> colorList = _getColorList(ramps: rampList);
    colorList.insert(0, Colors.black);
    assert(colorList.length < 256);
    final List<List<int>> layerEncBytes = <List<int>>[];
    final List<Uint8List> layerNames = <Uint8List>[];
    final List<int> imgBytes = <int>[];
    for (int i = 0; i < colorList.length; i++)
    {
      imgBytes.add(i);
    }
    final List<int> encData = const ZLibEncoder().encode(imgBytes);
    layerEncBytes.add(encData);
    layerNames.add(utf8.encode("KPixPalette"));

    return _createAsepriteData(colorList: colorList, layerNames: layerNames, layerEncBytes: layerEncBytes, canvasSize: CoordinateSetI(x: colorList.length, y: 1));
  }

  Future<Uint8List> getPaletteGimpData({required final List<KPalRampData> rampList, required final ColorNames colorNames}) async
  {
    final List<ui.Color> colorList = _getColorList(ramps: rampList);
    final StringBuffer stringBuffer = StringBuffer();
    stringBuffer.writeln("GIMP Palette");
    stringBuffer.writeln('Name: KPix_${DateTime.now().toString().replaceAll(RegExp(r'[:\- ]'), '_')}');
    stringBuffer.writeln('Columns: 16');
    stringBuffer.writeln('#');
    for (final ui.Color color in colorList)
    {
      stringBuffer.writeln('${(color.r * 255).toInt()} ${(color.g * 255).toInt()} ${(color.b * 255).toInt()} ${colorNames.getColorName(r: color.r, g: color.g, b: color.b)}');
    }
    final String str = stringBuffer.toString();
    return Uint8List.fromList(utf8.encode(str));

  }

  Future<Uint8List> getPalettePaintNetData({required final List<KPalRampData> rampList, required final ColorNames colorNames}) async
  {
    final List<ui.Color> colorList = _getColorList(ramps: rampList);
    final StringBuffer stringBuffer = StringBuffer();
    stringBuffer.writeln('; KPix_${DateTime.now().toString().replaceAll(RegExp(r'[:\- ]'), '_')}');
    for (int i = 0; i < colorList.length; i++)
    {
       stringBuffer.writeln("${colorToHexString(c: colorList[i], withHashTag: false).toUpperCase()} ; $i-${colorNames.getColorName(r: colorList[i].r, g: colorList[i].g, b: colorList[i].b)}");
    }
    final String str = stringBuffer.toString();
    return Uint8List.fromList(utf8.encode(str));
  }

  Future<Uint8List> getPaletteAdobeData({required final List<KPalRampData> rampList, required final ColorNames colorNames}) async
  {
    final List<ui.Color> colorList = _getColorList(ramps: rampList);
    final BytesBuilder buffer = BytesBuilder();
    buffer.add(intToBytes(value: 0x46455341, length: 4));
    buffer.add(intToBytes(value: 0x00000100, length: 4));
    buffer.add(intToBytes(value: colorList.length, length: 4, reverse: true));
    for (final ui.Color color in colorList)
    {
      final String colorName = colorNames.getColorName(r: color.r, g: color.g, b: color.b);
      buffer.add(intToBytes(value: 0x0100, length: 2));
      buffer.add(intToBytes(value: 22 + (colorName.length * 2), length: 4, reverse: true));
      buffer.add(intToBytes(value: colorName.length + 1, length: 2, reverse: true));
      for (final int codeUnit in colorName.codeUnits)
      {
        if (codeUnit != '-'.codeUnitAt(0))
        {
          buffer.add(intToBytes(value: codeUnit, length: 2, reverse: true));
        }
      }
      buffer.add(intToBytes(value: 0, length: 2, reverse: true));

      buffer.add(stringToBytes(value: "RGB ")); // Color model

      // Color values
      buffer.add(float32ToBytes(value: color.r, reverse: true));
      buffer.add(float32ToBytes(value: color.g, reverse: true));
      buffer.add(float32ToBytes(value: color.b, reverse: true));

      // Color type
      buffer.add(intToBytes(value: 0, length: 2, reverse: true));
    }
    return buffer.toBytes();
  }

  Future<Uint8List> getPaletteJascData({required final List<KPalRampData> rampList}) async
  {
    final List<ui.Color> colorList = _getColorList(ramps: rampList);
    final StringBuffer stringBuffer = StringBuffer();
    stringBuffer.writeln("JASC-PAL");
    stringBuffer.writeln("0100");
    stringBuffer.writeln(colorList.length.toString());
    for (final ui.Color color in colorList)
    {
      stringBuffer.writeln("${(color.r * 255).toInt()} ${(color.g * 255).toInt()} ${(color.b * 255).toInt()}");
    }
    final String str = stringBuffer.toString();
    return Uint8List.fromList(utf8.encode(str));
  }

  Future<Uint8List> getPaletteCorelData({required final List<KPalRampData> rampList, required final ColorNames colorNames}) async
  {
    final List<ui.Color> colorList = _getColorList(ramps: rampList);
    final StringBuffer stringBuffer = StringBuffer();
    stringBuffer.writeln('<? version = "1.0" ?>');
    stringBuffer.writeln('<palette name="" guid="">');
    stringBuffer.writeln("\t<colors>");
    stringBuffer.writeln("\t\t<page>");

    for (final ui.Color color in colorList)
    {
      stringBuffer.writeln('''\t\t\t<color cs="RGB" tints="${color.r.toStringAsFixed(6)},${color.g.toStringAsFixed(6)},${color.b.toStringAsFixed(6)}"name="${escapeXml(input: colorNames.getColorName(r: color.r, g: color.g, b: color.b))}" />''');
    }

    stringBuffer.writeln("\t\t</page>");
    stringBuffer.writeln("\t</colors>");
    stringBuffer.writeln("</palette>");

    final String str = stringBuffer.toString();
    return Uint8List.fromList(utf8.encode(str));
  }

  Future<Uint8List> getPaletteOpenOfficeData({required final List<KPalRampData> rampList, required final ColorNames colorNames}) async
  {
    final List<ui.Color> colorList = _getColorList(ramps: rampList);
    final StringBuffer stringBuffer = StringBuffer();
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
      final String colorHex = colorToHexString(c: color).toLowerCase();
      final String colorName = escapeXml(input: colorNames.getColorName(r: color.r, g: color.g, b: color.b));
      stringBuffer.writeln('\t<draw:color draw:name="$colorName" draw:color="$colorHex"/>');
    }

    stringBuffer.writeln('</office:color-table>');
    final String str = stringBuffer.toString();
    return Uint8List.fromList(utf8.encode(str));
  }



  Future<Uint8List> _createAsepriteData({required final List<ui.Color> colorList, required final List<Uint8List> layerNames, required final List<List<int>> layerEncBytes, required final CoordinateSetI canvasSize, final List<DrawingLayerState>? layerList}) async
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
      fileSize += 24 + layerNames[i].length;
    }

    for (int i = 0; i < layerEncBytes.length; i++)
    {
      fileSize += 26 + layerEncBytes[i].length;
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
      outBytes.setUint8(offset, (colorList[i].r * 255).toInt()); //red
      offset++;
      outBytes.setUint8(offset, (colorList[i].g * 255).toInt()); //green
      offset++;
      outBytes.setUint8(offset, (colorList[i].b * 255).toInt()); //blue
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
      outBytes.setUint8(offset, (colorList[i].r * 255).toInt()); //red
      offset++;
      outBytes.setUint8(offset, (colorList[i].g * 255).toInt()); //green
      offset++;
      outBytes.setUint8(offset, (colorList[i].b * 255).toInt()); //blue
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
        outBytes.setUint16(offset, canvasSize.x, Endian.little); //width
        offset+=2;
        outBytes.setUint16(offset, canvasSize.y, Endian.little); //height
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

  Future<ByteData> createKPixData({required final AppState appState}) async
  {
    final HistoryState saveData = HistoryState.fromAppState(appState: appState, identifier: HistoryStateTypeIdentifier.saveData);
    final ByteData byteData = ByteData(_calculateKPixFileSize(saveData: saveData));

    int offset = 0;
    //header
    byteData.setUint32(offset, int.parse(magicNumber, radix: 16));
    offset+=4;
    //file version
    byteData.setUint8(offset++, fileVersion);

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
      for (int j = 0; j < satCurveMap.length; j++)
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
      byteData.setUint8(offset++, historyLayerValueMap[saveData.layerList[i].runtimeType]!);

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


      if (saveData.layerList[i].runtimeType == HistoryDrawingLayer)
      {
        final HistoryDrawingLayer drawingLayer = saveData.layerList[i] as HistoryDrawingLayer;
        //lock type
        int lockVal = 0;
        for (int j = 0; j < layerLockStateValueMap.length; j++)
        {
          if (layerLockStateValueMap[j] == drawingLayer.lockState)
          {
            lockVal = j;
            break;
          }
        }
        byteData.setUint8(offset++, lockVal);

        if (fileVersion >= 2)
        {
          //* outer_stroke_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = relative, ``03`` = glow, ``04`` = shade
          int outerStrokeStyleVal = 0;
          for (int j = 0; j < outerStrokeStyleValueMap.length; j++)
          {
            if (outerStrokeStyleValueMap[j] == drawingLayer.settings.outerStrokeStyle)
            {
              outerStrokeStyleVal = j;
              break;
            }
          }
          byteData.setUint8(offset++, outerStrokeStyleVal);
          //* outer_stroke_directions ``ubyte (1)`` // bitmask of directions: ``00`` = top left, ``01`` = center top, ``02`` = top right, ``03`` = center right, ``04`` = bottom right, ``05`` = center bottom, ``06`` = bottom left, ``07`` = center left
          byteData.setUint8(offset++, _packAlignments(alignments: drawingLayer.settings.outerSelectionMap));
          //* outer_stroke_solid_color_ramp_index ``ubyte (1)`` // color ramp index
          byteData.setUint8(offset++, drawingLayer.settings.outerColorReference.rampIndex);
          //* outer_stroke_solid_color_index ``ubyte (1)`` // index in color ramp
          byteData.setUint8(offset++, drawingLayer.settings.outerColorReference.colorIndex);
          //* outer_stroke_darken_brighten ``byte (1)`` // shading amount for relative/shade -5...5
          byteData.setInt8(offset++, drawingLayer.settings.outerDarkenBrighten);
          //* outer_stroke_glow_depth ``byte (1)`` // amount of glow depth -6...+6
          byteData.setInt8(offset++, drawingLayer.settings.outerGlowDepth);
          //* outer_glow_recursive ``ubyte (1)`` // ``00`` = false, ``01`` = true
          byteData.setInt8(offset++, drawingLayer.settings.outerGlowRecursive ? 1 : 0);
          //* inner_stroke_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = bevel, ``03`` = glow, ``04`` = shade
          int innerStrokeStyleVal = 0;
          for (int j = 0; j < innerStrokeStyleValueMap.length; j++)
          {
            if (innerStrokeStyleValueMap[j] == drawingLayer.settings.innerStrokeStyle)
            {
              innerStrokeStyleVal = j;
              break;
            }
          }
          byteData.setUint8(offset++, innerStrokeStyleVal);
          //* inner_stroke_directions ``ubyte (1)`` // bitmask of directions: ``00`` = top left, ``01`` = center top, ``02`` = top right, ``03`` = center right, ``04`` = bottom right, ``05`` = center bottom, ``06`` = bottom left, ``07`` = center left
          byteData.setUint8(offset++, _packAlignments(alignments: drawingLayer.settings.innerSelectionMap));
          //* inner_stroke_solid_color_ramp_index ``ubyte (1)`` // color ramp index
          byteData.setUint8(offset++, drawingLayer.settings.innerColorReference.rampIndex);
          //* inner_stroke_solid_color_index ``ubyte (1)`` // index in color ramp
          byteData.setUint8(offset++, drawingLayer.settings.innerColorReference.colorIndex);
          //* inner_stroke_darken_brighten ``byte (1)`` // shading amount for shade -5...5
          byteData.setInt8(offset++, drawingLayer.settings.innerDarkenBrighten);
          //* inner_stroke_glow_depth ``byte (1)`` // amount of glow depth -6...6
          byteData.setInt8(offset++, drawingLayer.settings.innerGlowDepth);
          //* inner_stroke_glow_recursive ``ubyte (1)`` // ``00`` = false, ``01`` = true
          byteData.setUint8(offset++, drawingLayer.settings.innerGlowRecursive ? 1 : 0);
          //* inner_stroke_bevel_distance ``ubyte (1)`` // border distance of bevel 1...8
          byteData.setUint8(offset++, drawingLayer.settings.bevelDistance);
          //* inner_stroke_bevel_strength ``ubyte (1)`` // shading strength of bevel 1...8
          byteData.setUint8(offset++, drawingLayer.settings.bevelStrength);
          //* drop_shadow_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = shade
          int dropShadowStyleVal = 0;
          for (int j = 0; j < dropShadowStyleValueMap.length; j++)
          {
            if (dropShadowStyleValueMap[j] == drawingLayer.settings.dropShadowStyle)
            {
              dropShadowStyleVal = j;
              break;
            }
          }
          byteData.setUint8(offset++, dropShadowStyleVal);
          //* drop_shadow_solid_color_ramp_index ``ubyte (1)`` // color ramp index
          byteData.setUint8(offset++, drawingLayer.settings.dropShadowColorReference.rampIndex);
          //* drop_shadow_solid_color_index ``ubyte (1)`` // index in color ramp
          byteData.setUint8(offset++, drawingLayer.settings.dropShadowColorReference.colorIndex);
          //* drop_shadow_offset_x ``byte (1)`` // -16...16
          byteData.setInt8(offset++, drawingLayer.settings.dropShadowOffset.x);
          //* drop_shadow_offset_y ``byte (1)`` // -16...16
          byteData.setInt8(offset++, drawingLayer.settings.dropShadowOffset.y);
          //* drop_shadow_darken_brighten ``byte (1)`` // shading amount for shade -5...5
          byteData.setInt8(offset++, drawingLayer.settings.dropShadowDarkenBrighten);
        }
        //data count
        int dataLength = drawingLayer.data.length;
        if (i == saveData.selectedLayerIndex)
        {
          dataLength += saveData.selectionState.content.values.whereType<HistoryColorReference>().length;
        }
        byteData.setUint32(offset, dataLength);
        offset+=4;
        //image data
        for (final MapEntry<CoordinateSetI, HistoryColorReference> entry in drawingLayer.data.entries)
        {
          final HistoryColorReference? selectionReference = (i == saveData.selectedLayerIndex) ? saveData.selectionState.content[entry.key] : null;
          if (selectionReference == null)
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
        if (i == saveData.selectedLayerIndex) //draw selected pixels
        {
          for (final MapEntry<CoordinateSetI, HistoryColorReference?> entry in saveData.selectionState.content.entries)
          {
            if (entry.value != null)
            {
              //x
              byteData.setUint16(offset, entry.key.x);
              offset+=2;
              //y
              byteData.setUint16(offset, entry.key.y);
              offset+=2;

              //ramp index
              byteData.setUint8(offset++, entry.value!.rampIndex);

              //color index
              byteData.setUint8(offset++, entry.value!.colorIndex);
            }
          }
        }
      }
      else if (saveData.layerList[i].runtimeType == HistoryReferenceLayer)
      {
        final HistoryReferenceLayer referenceLayer = saveData.layerList[i] as HistoryReferenceLayer;

        //path (string)
        final Uint8List encodedPath = utf8.encode(referenceLayer.path);
        byteData.setUint16(offset, encodedPath.length);
        offset += 2;
        for (int i = 0; i < encodedPath.length; i++)
        {
          byteData.setUint8(offset++, encodedPath[i]);
        }

        //opacity ``ubyte (1)`` // 0...100
        byteData.setUint8(offset++, referenceLayer.opacity);
        //offset_x ``float (1)``
        byteData.setFloat32(offset, referenceLayer.offsetX);
        offset += 4;
        //offset_y ``float (1)``
        byteData.setFloat32(offset, referenceLayer.offsetY);
        offset += 4;
        //zoom ``ushort (1)``
        byteData.setUint16(offset, referenceLayer.zoom);
        offset+=2;
        //aspect_ratio ``float (1)``
        byteData.setFloat32(offset, referenceLayer.aspectRatio);
        offset += 4;
      }
      else if (saveData.layerList[i].runtimeType == HistoryGridLayer)
      {
        final HistoryGridLayer gridLayer = saveData.layerList[i] as HistoryGridLayer;
        //opacity ``ubyte (1)`` // 0...100
        byteData.setUint8(offset++, gridLayer.opacity);
        //brightness ``ubyte (1)`` // 0...100
        byteData.setUint8(offset++, gridLayer.brightness);
        //grid_type ``ubyte (1)`` // ``00``= rectangular, ``01`` = diagonal, ``02`` = isometric
        byteData.setUint8(offset++, gridTypeValueMap[gridLayer.gridType]!);
        //interval_x ``ubyte (1)`` // 2...64
        byteData.setUint8(offset++, gridLayer.intervalX);
        //interval_x ``ubyte (1)`` // 2...64
        byteData.setUint8(offset++, gridLayer.intervalY);
        //horizon_position ``float (1)``// 0...1 (vertical horizon position)
        byteData.setFloat32(offset, gridLayer.horizonPosition);
        offset += 4;
        //vanishing_point_1 ``float (1)``// 0...1 (horizontal position of first vanishing point)
        byteData.setFloat32(offset, gridLayer.vanishingPoint1);
        offset += 4;
        //vanishing_point_2 ``float (1)``// 0...1 (horizontal position of second vanishing point)
        byteData.setFloat32(offset, gridLayer.vanishingPoint2);
        offset += 4;
        //vanishing_point_3 ``float (1)``// 0...1 (vertical position of third vanishing point)
        byteData.setFloat32(offset, gridLayer.vanishingPoint3);
        offset += 4;
      }
      else if (saveData.layerList[i] is HistoryShadingLayer)
      {
        final HistoryShadingLayer shadingLayer = saveData.layerList[i] as HistoryShadingLayer;

        //lock type
        int lockVal = 0;
        for (int j = 0; j < layerLockStateValueMap.length; j++)
        {
          if (layerLockStateValueMap[j] == shadingLayer.lockState)
          {
            lockVal = j;
            break;
          }
        }
        byteData.setUint8(offset++, lockVal);

        if (fileVersion >= 2)
        {
          //* shading_step_limit_low ``ubyte (1)`` // 1...6
          byteData.setUint8(offset++, shadingLayer.settings.shadingLow);
          //* shading_step_limit_high ``ubyte (1)`` // 1...6
          byteData.setUint8(offset++, shadingLayer.settings.shadingHigh);
        }

        //data count
        final int dataLength = shadingLayer.data.length;
        byteData.setUint32(offset, dataLength);
        offset+=4;

        for (final MapEntry<CoordinateSetI, int> entry in shadingLayer.data.entries)
        {
          //x
          byteData.setUint16(offset, entry.key.x);
          offset+=2;
          //y
          byteData.setUint16(offset, entry.key.y);
          offset+=2;
          //shading
          byteData.setInt8(offset++, entry.value);
        }
      }
    }

    return byteData;
  }

int _packAlignments({required final HashMap<Alignment, bool> alignments})
{
  assert(allAlignments.length == 8);
  assert(alignments.length == 8);

  int byte = 0;
  int i = 0;
  for (final Alignment alignment in allAlignments)
  {
    if (alignments[alignment] == true)
    {
      byte |= 1 << i;
    }
    i++;
  }
  return byte;
}

  Future<Uint8List> createPaletteKPalData({required final List<KPalRampData> rampList}) async
  {
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

  Future<Uint8List?> getAsepriteData({required final ExportData exportData, required final AppState appState}) async
  {
    final List<ui.Color> colorList = <ui.Color>[];
    final Map<ColorReference, int> colorMap = <ColorReference, int>{};
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

    final List<List<int>> layerEncBytes = <List<int>>[];
    final List<Uint8List> layerNames = <Uint8List>[];
    final List<DrawingLayerState> drawingLayers = <DrawingLayerState>[];

    for (int l = 0; l < appState.layerCount; l++)
    {
      if (appState.getLayerAt(index: l).runtimeType == DrawingLayerState)
      {
        final DrawingLayerState layerState = appState.getLayerAt(index: l) as DrawingLayerState;
        final List<int> imgBytes = <int>[];
        for (int y = 0; y < appState.canvasSize.y; y++)
        {
          for (int x = 0; x < appState.canvasSize.x; x++)
          {
            final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);
            ColorReference? colAtPos;
            if (appState.getSelectedLayer() == appState.getLayerAt(index: l))
            {
              colAtPos = appState.selectionState.selection.getColorReference(coord: curCoord);
            }
            colAtPos ??= layerState.getDataEntry(coord: curCoord, withSettingsPixels: true);

            if (colAtPos == null)
            {
              imgBytes.add(0);
            }
            else
            {
              final int shade = _getShadeForCoord(appState: appState, currentLayerIndex: l, coord: curCoord);
              if (shade != 0)
              {
                final int targetIndex = (colAtPos.colorIndex + shade).clamp(0, colAtPos.ramp.shiftedColors.length - 1);
                colAtPos = colAtPos.ramp.references[targetIndex];
              }
              imgBytes.add(colorMap[colAtPos]!);
            }
          }
        }
        final List<int> encData = const ZLibEncoder().encode(imgBytes);
        layerEncBytes.add(encData);
        layerNames.add(utf8.encode("Layer$l"));
        drawingLayers.add(layerState);
      }
    }

    return _createAsepriteData(colorList: colorList, layerNames: layerNames, layerEncBytes: layerEncBytes, canvasSize: appState.canvasSize, layerList: drawingLayers);
  }

  int _getShadeForCoord({required final AppState appState, required final int currentLayerIndex, required final CoordinateSetI coord})
  {
    assert(currentLayerIndex < appState.layerCount);
    int shade = 0;
    for (int i = currentLayerIndex - 1; i >= 0; i--)
    {
      if (appState.getLayerAt(index: i).visibilityState.value == LayerVisibilityState.visible)
      {
        if (appState.getLayerAt(index: i).runtimeType == DrawingLayerState)
        {
          final DrawingLayerState drawingLayerState = appState.getLayerAt(index: i) as DrawingLayerState;
          if (drawingLayerState.getDataEntry(coord: coord) != null)
          {
            return 0;
          }
        }
        else if (appState.getLayerAt(index: i) is ShadingLayerState)
        {
          final ShadingLayerState shadingLayerState = appState.getLayerAt(index: i) as ShadingLayerState;
          final int? shadingAt = shadingLayerState.getDisplayValueAt(coord: coord);
          if (shadingAt != null)
          {
            shade += shadingAt;
          }
        }
      }
    }

    return shade;
  }

  Future<Uint8List?> getGimpData({required final ExportData exportData, required final AppState appState}) async
  {
    final List<Color> colorList = <ui.Color>[];
    final Map<ColorReference, int> colorMap = <ColorReference, int>{};
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
        8 + (appState.layerCount * 8) + //layer addresses
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

    final List<List<List<int>>> layerEncBytes = <List<List<int>>>[];
    final List<Uint8List> layerNames = <Uint8List>[];
    const int tileSize = 64;
    final List<DrawingLayerState> drawingLayers = <DrawingLayerState>[];
    for (int l = 0; l < appState.layerCount; l++)
    {
      if (appState.getLayerAt(index: l).runtimeType == DrawingLayerState)
      {
        final DrawingLayerState layerState = appState.getLayerAt(index: l) as DrawingLayerState;
        int x = 0;
        int y = 0;
        final List<List<int>> tileList = <List<int>>[];
        do //TILING
        {
          final List<int> imgBytes = <int>[];
          final int endX = min(x + tileSize, appState.canvasSize.x);
          final int endY = min(y + tileSize, appState.canvasSize.y);
          for (int b = y; b < endY; b++)
          {
            for (int a = x; a < endX; a++)
            {
              final CoordinateSetI curCoord = CoordinateSetI(x: a, y: b);
              ColorReference? colAtPos;
              if (appState.getSelectedLayer() == appState.getLayerAt(index: l))
              {
                colAtPos = appState.selectionState.selection.getColorReference(coord: curCoord);
              }
              colAtPos ??= layerState.getDataEntry(coord: curCoord, withSettingsPixels: true);

              if (colAtPos == null)
              {
                imgBytes.add(0);
                imgBytes.add(0);
              }
              else
              {
                final int shade = _getShadeForCoord(appState: appState, currentLayerIndex: l, coord: curCoord);
                if (shade != 0)
                {
                  final int targetIndex = (colAtPos.colorIndex + shade).clamp(0, colAtPos.ramp.shiftedColors.length - 1);
                  colAtPos = colAtPos.ramp.references[targetIndex];
                }
                imgBytes.add(colorMap[colAtPos]!);
                imgBytes.add(255);
              }

            }

          }
          final List<int> encData = const ZLibEncoder().encode(imgBytes);
          tileList.add(encData);

          x = (endX >= appState.canvasSize.x) ? 0 : endX;
          y = (endX >= appState.canvasSize.x) ? endY : y;
        }
        while (y < appState.canvasSize.y);

        layerNames.add(utf8.encode("Layer$l"));
        layerEncBytes.add(tileList);
        drawingLayers.add(layerState);
      }
    }

    //CALCULATING SIZE
    bool activeLayerSet = false;
    int fileSize = fullHeaderSize;
    for (int i = 0; i < drawingLayers.length; i++)
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
      fileSize += basicLevelSize - 4;
      //level3
      fileSize += basicLevelSize - 4;
    }


    //WRITING

    final List<int> layerOffsetsInsertPositions = <int>[];

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
      outBytes.setUint8(offset, (c.r * 255).toInt());
      offset++;
      outBytes.setUint8(offset, (c.g * 255).toInt());
      offset++;
      outBytes.setUint8(offset, (c.b * 255).toInt());
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
    for (int i = 0; i < drawingLayers.length; i++)
    {
      layerOffsetsInsertPositions.add(offset);
      setUint64(bytes: outBytes, offset: offset, value: 0);
      offset+=8;
    }

    setUint64(bytes: outBytes, offset: offset, value: 0); //end layer pointers
    offset+=8;
    setUint64(bytes: outBytes, offset: offset, value: 0); //start/end channel pointers
    offset+=8;


    //LAYERS
    for (int i = 0; i < drawingLayers.length; i++)
    {
      setUint64(bytes: outBytes, offset: layerOffsetsInsertPositions[i], value: offset);

      final DrawingLayerState currentLayer = drawingLayers[i];
      outBytes.setUint32(offset, appState.canvasSize.x);
      offset+=4;
      outBytes.setUint32(offset, appState.canvasSize.y);
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
      setUint64(bytes: outBytes, offset: offset, value: 0);
      offset+=8;

      //LAYER MASK
      setUint64(bytes: outBytes, offset: offset, value: 0);
      offset+=8;

      //HIERARCHY
      setUint64(bytes: outBytes, offset: hierarchyOffsetInsertPosition, value: offset);
      outBytes.setUint32(offset, appState.canvasSize.x);
      offset+=4;
      outBytes.setUint32(offset, appState.canvasSize.y);
      offset+=4;
      outBytes.setUint32(offset, 2);
      offset+=4;
      final int pointerInsertToLevel1 = offset;
      setUint64(bytes: outBytes, offset: offset, value: 0);
      offset+=8;
      final int pointerInsertToLevel2 = offset;
      setUint64(bytes: outBytes, offset: offset, value: 0);
      offset+=8;
      final int pointerInsertToLevel3 = offset;
      setUint64(bytes: outBytes, offset: offset, value: 0);
      offset+=8;
      setUint64(bytes: outBytes, offset: offset, value: 0);
      offset+=8;

      //LEVEL1
      setUint64(bytes: outBytes, offset: pointerInsertToLevel1, value: offset);
      outBytes.setUint32(offset, appState.canvasSize.x);
      offset+=4;
      outBytes.setUint32(offset, appState.canvasSize.y);
      offset+=4;
      final List<int> tileOffsetsLv1 = <int>[];
      final List<List<int>> currentTiles = layerEncBytes[i];
      for (int j = 0; j < currentTiles.length; j++)
      {
        tileOffsetsLv1.add(offset);
        setUint64(bytes: outBytes, offset: offset, value: 0);
        offset+=8;
      }
      setUint64(bytes: outBytes, offset: offset, value: 0);
      offset+=8;

      //TILE DATA FOR LEVEL1
      for (int j = 0; j < currentTiles.length; j++)
      {
        setUint64(bytes: outBytes, offset: tileOffsetsLv1[j], value: offset);
        final List<int> currentTile = currentTiles[j];
        for (int k = 0; k < currentTile.length; k++)
        {
          outBytes.setUint8(offset, currentTile[k]);
          offset++;
        }
      }

      //LEVEL2
      setUint64(bytes: outBytes, offset: pointerInsertToLevel2, value: offset);
      outBytes.setUint32(offset, appState.canvasSize.x ~/ 2);
      offset+=4;
      outBytes.setUint32(offset, appState.canvasSize.y ~/ 2);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;
      //LEVEL3
      setUint64(bytes: outBytes, offset: pointerInsertToLevel3, value: offset);
      outBytes.setUint32(offset, appState.canvasSize.x ~/ 4);
      offset+=4;
      outBytes.setUint32(offset, appState.canvasSize.y ~/ 4);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;
    }

    return outBytes.buffer.asUint8List();
  }

  int _calculateKPixFileSize({required final HistoryState saveData})
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
      if (saveData.layerList[i].runtimeType == HistoryDrawingLayer)
      {
        final HistoryDrawingLayer drawingLayer = saveData.layerList[i] as HistoryDrawingLayer;
        //lock type
        size += 1;

        if (fileVersion >= 2)
        {
          //* outer_stroke_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = relative, ``03`` = glow, ``04`` = shade
          size += 1;
          //* outer_stroke_directions ``ubyte (1)`` // bitmask of directions: ``00`` = top left, ``01`` = center top, ``02`` = top right, ``03`` = center right, ``04`` = bottom right, ``05`` = center bottom, ``06`` = bottom left, ``07`` = center left
          size += 1;
          //* outer_stroke_solid_color_ramp_index ``ubyte (1)`` // color ramp index
          size += 1;
          //* outer_stroke_solid_color_index ``ubyte (1)`` // index in color ramp
          size += 1;
          //* outer_stroke_darken_brighten ``byte (1)`` // shading amount for relative/shade -5...5
          size += 1;
          //* outer_stroke_glow_depth ``byte (1)`` // amount of glow depth -6...+6
          size += 1;
          //* outer_glow_direction ``ubyte (1)`` // ``00`` = darken, ``01`` = brighten
          size += 1;
          //* inner_stroke_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = bevel, ``03`` = glow, ``04`` = shade
          size += 1;
          //* inner_stroke_directions ``ubyte (1)`` // bitmask of directions: ``00`` = top left, ``01`` = center top, ``02`` = top right, ``03`` = center right, ``04`` = bottom right, ``05`` = center bottom, ``06`` = bottom left, ``07`` = center left
          size += 1;
          //* inner_stroke_solid_color_ramp_index ``ubyte (1)`` // color ramp index
          size += 1;
          //* inner_stroke_solid_color_index ``ubyte (1)`` // index in color ramp
          size += 1;
          //* inner_stroke_darken_brighten ``byte (1)`` // shading amount for shade -5...5
          size += 1;
          //* inner_stroke_glow_depth ``byte (1)`` // amount of glow depth -6...+6
          size += 1;
          //* inner_stroke_glow_direction ``ubyte (1)`` // ``00`` = darken, ``01`` = brighten
          size += 1;
          //* inner_stroke_bevel_distance ``ubyte (1)`` // border distance of bevel 1...8
          size += 1;
          //* inner_stroke_bevel_strength ``ubyte (1)`` // shading strength of bevel 1...8
          size += 1;
          //* drop_shadow_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = shade
          size += 1;
          //* drop_shadow_solid_color_ramp_index ``ubyte (1)`` // color ramp index
          size += 1;
          //* drop_shadow_solid_color_index ``ubyte (1)`` // index in color ramp
          size += 1;
          //* drop_shadow_offset_x ``byte (1)`` // -16...16
          size += 1;
          //* drop_shadow_offset_y ``byte (1)`` // -16...16
          size += 1;
          //* drop_shadow_darken_brighten ``byte (1)`` // shading amount for shade -5...5
          size += 1;
        }
        //data count
        size += 4;
        for (final MapEntry<CoordinateSetI, HistoryColorReference> entry in drawingLayer.data.entries)
        {
          final HistoryColorReference? selectionReference = (i == saveData.selectedLayerIndex) ? saveData.selectionState.content[entry.key] : null;
          if (selectionReference == null)
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
        if (i == saveData.selectedLayerIndex) //draw selected pixels
        {
          for (final MapEntry<CoordinateSetI, HistoryColorReference?> entry in saveData.selectionState.content.entries)
          {
            if (entry.value != null)
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
        }
      }
      else if (saveData.layerList[i].runtimeType == HistoryReferenceLayer)
      {
        final HistoryReferenceLayer referenceLayer = saveData.layerList[i] as HistoryReferenceLayer;
        //path (string)
        size += 2;
        size += utf8.encode(referenceLayer.path).length;
        //opacity ``ubyte (1)`` // 0...100
        size += 1;
        //offset_x ``float (1)``
        size += 4;
        //offset_y ``float (1)``
        size += 4;
        //zoom ``ushort (1)``
        size += 2;
        //aspect_ratio ``float (1)``
        size += 4;
      }
      else if (saveData.layerList[i].runtimeType == HistoryGridLayer)
      {
        //opacity ``ubyte (1)`` // 0...100
        size += 1;
        //brightness ``ubyte (1)`` // 0...100
        size += 1;
        //grid_type ``ubyte (1)`` // ``00``= rectangular, ``01`` = diagonal, ``02`` = isometric
        size += 1;
        //interval_x ``ubyte (1)`` // 2...64
        size += 1;
        //interval_x ``ubyte (1)`` // 2...64
        size += 1;
        //horizon_position ``float (1)``// 0...1 (vertical horizon position)
        size += 4;
        //vanishing_point_1 ``float (1)``// 0...1 (horizontal position of first vanishing point)
        size += 4;
        //vanishing_point_2 ``float (1)``// 0...1 (horizontal position of second vanishing point)
        size += 4;
        //vanishing_point_3 ``float (1)``// 0...1 (vertical position of third vanishing point)
        size += 4;
      }
      else if (saveData.layerList[i] is HistoryShadingLayer)
      {
        final HistoryShadingLayer shadingLayer = saveData.layerList[i] as HistoryShadingLayer;
        //lock type
        size += 1;
        if (fileVersion >= 2)
        {
          //* shading_step_limit_low ``ubyte (1)`` // 1...6
          size += 1;
          //* shading_step_limit_high ``ubyte (1)`` // 1...6
          size += 1;
        }

        //data count
        size += 4;
        for (final MapEntry<CoordinateSetI, int> entry in shadingLayer.data.entries)
        {
          final HistoryColorReference? selectionReference = (i == saveData.selectedLayerIndex) ? saveData.selectionState.content[entry.key] : null;
          if (selectionReference == null)
          {
            //x
            size += 2;
            //y
            size += 2;
            //shading
            size += 1;
          }
        }
        if (i == saveData.selectedLayerIndex) //draw selected pixels
            {
          for (final MapEntry<CoordinateSetI, HistoryColorReference?> entry in saveData.selectionState.content.entries)
          {
            if (entry.value != null)
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
        }
      }
    }


    return size;
  }

  int _calculateKPalFileSize({required final List<KPalRampData> rampList})
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
    return size += 1;
  }
