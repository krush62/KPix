/*
 *
 *  * KPix
 *  * This program is free software: you can redistribute it and/or modify
 *  * it under the terms of the GNU Affero General Public License as published by
 *  * the Free Software Foundation, either version 3 of the License, or
 *  * (at your option) any later version.
 *  *
 *  * This program is distributed in the hope that it will be useful,
 *  * but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  * GNU Affero General Public License for more details.
 *  *
 *  * You should have received a copy of the GNU Affero General Public License
 *  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' show ZLibDecoder;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/drawing_layer_settings_constraints.dart';
import 'package:kpix/models/constraints/frame_constraints.dart';
import 'package:kpix/models/constraints/grid_layer_constraints.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/constraints/reference_layer_constraints.dart';
import 'package:kpix/models/constraints/shading_layer_settings_constraints.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/history/history_color_reference.dart';
import 'package:kpix/models/history/history_drawing_layer.dart';
import 'package:kpix/models/history/history_drawing_layer_settings.dart';
import 'package:kpix/models/history/history_frame.dart';
import 'package:kpix/models/history/history_grid_layer.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history/history_layer_type.dart';
import 'package:kpix/models/history/history_ramp_data.dart';
import 'package:kpix/models/history/history_reference_layer.dart';
import 'package:kpix/models/history/history_selection_state.dart';
import 'package:kpix/models/history/history_shading_layer.dart';
import 'package:kpix/models/history/history_shading_layer_settings.dart';
import 'package:kpix/models/history/history_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history/history_timeline.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/palette_codec.dart';
import 'package:kpix/util/file_byte_reader.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/isolate_helper.dart';
import 'package:kpix/util/helpers/pixel_grid.dart';
import 'package:uuid/uuid.dart';

HashMap<Alignment, bool> _unPackAlignments({required final int byte})
{
  assert(allAlignments.length == 8);
  final HashMap<Alignment, bool> alignments = HashMap<Alignment, bool>();
  for (int i = 0; i < 8; i++)
  {
    alignments[allAlignments.elementAt(i)] = (byte & (1 << i)) != 0;
  }
  return alignments;
}

class _ImportRejected implements Exception
{
  const _ImportRejected(this.message);
  final String message;
}

class _ImportGuard
{
  _ImportGuard({required this.strict, required this.warnings});

  final bool strict;
  final StringBuffer warnings;

  T ranged<T extends num>({
    required final T value,
    required final T min,
    required final T max,
    required final String label,
    required final T fallback,
  })
  {
    if (value < min || value > max)
    {
      return _reject(label: label, raw: value, fallback: fallback);
    }
    return value;
  }

  double approx({
    required final double value,
    required final double min,
    required final double max,
    required final String label,
    required final double fallback,
    final double delta = fileFloatDelta,
  })
  {
    final double checked = ranged(
      value: value,
      min: min - delta,
      max: max + delta,
      label: label,
      fallback: fallback,
    );
    return checked.clamp(min, max);
  }

  T mapped<T extends Object>({
    required final T? value,
    required final T? fallback,
    required final Object raw,
    required final String label,
  })
  {
    if (value == null)
    {
      if (fallback == null)
      {
        throw _ImportRejected("$label: $raw");
      }
      return _reject(label: label, raw: raw, fallback: fallback);
    }
    return value;
  }

  bool flag({
    required final int value,
    required final String label,
    final bool fallback = false,
  })
  {
    if (value != 0 && value != 1)
    {
      return _reject(label: label, raw: value, fallback: fallback);
    }
    return value == 1;
  }

  T _reject<T>({
    required final String label,
    required final Object raw,
    required final T fallback,
  })
  {
    final String message = "$label: $raw";
    if (strict)
    {
      throw _ImportRejected(message);
    }
    warnings.write("\n$message");
    return fallback;
  }
}

typedef _PixelBounds = ({int left, int top, int width, int height});

_PixelBounds _readBounds({required final FileByteReader reader})
{
  return (left: reader.getUint16(), top: reader.getUint16(), width: reader.getUint16(), height: reader.getUint16());
}

void _readDrawingPixels({required final FileByteReader reader, required final PixelGrid data, required final List<HistoryRampData> rampList, required final int layerIndex})
{
  final _PixelBounds bounds = _readBounds(reader: reader);
  if (bounds.width == 0 || bounds.height == 0)
  {
    return;
  }
  final int colorCount = reader.getUint16();
  //index 0 is transparent
  final Uint16List codes = Uint16List(colorCount + 1);
  for (int i = 1; i <= colorCount; i++)
  {
    final int rampIndex = reader.getUint8();
    if (rampIndex >= rampList.length) throw _ImportRejected("Color Ramp index out of range for layer $layerIndex : $rampIndex");
    final int colorIndex = reader.getUint8();
    if (colorIndex >= rampList[rampIndex].settings.colorCount) throw _ImportRejected("Color index out of range for layer $layerIndex: $colorIndex");
    codes[i] = PaletteCodec.codeOf(rampIndex: rampIndex, colorIndex: colorIndex);
  }
  final bool wideIndices = colorCount > 255;
  for (int y = bounds.top; y < bounds.top + bounds.height; y++)
  {
    for (int x = bounds.left; x < bounds.left + bounds.width; x++)
    {
      final int index = wideIndices ? reader.getUint16() : reader.getUint8();
      if (index > colorCount) throw _ImportRejected("Color table index out of range for layer $layerIndex: $index");
      if (index != 0)
      {
        data.set(x: x, y: y, value: codes[index]);
      }
    }
  }
}

/// The pixel list files before version 6 stored instead of a box.
void _readDrawingPixelList({required final FileByteReader reader, required final PixelGrid data, required final List<HistoryRampData> rampList, required final int layerIndex})
{
  final int dataCount = reader.getUint32();
  for (int j = 0; j < dataCount; j++)
  {
    final int x = reader.getUint16();
    final int y = reader.getUint16();
    final int colorRampIndex = reader.getUint8();
    if (colorRampIndex >= rampList.length) throw _ImportRejected("Color Ramp index out of range for layer $layerIndex : $colorRampIndex");
    final int colorIndex = reader.getUint8();
    if (colorIndex >= rampList[colorRampIndex].settings.colorCount) throw _ImportRejected("Color index out of range for layer $layerIndex: $colorIndex");
    data.set(x: x, y: y, value: PaletteCodec.codeOf(rampIndex: colorRampIndex, colorIndex: colorIndex));
  }
}

void _readShadingPixels({required final FileByteReader reader, required final PixelGrid data})
{
  final _PixelBounds bounds = _readBounds(reader: reader);
  for (int y = bounds.top; y < bounds.top + bounds.height; y++)
  {
    for (int x = bounds.left; x < bounds.left + bounds.width; x++)
    {
      final int stored = reader.getUint8();
      if (stored != 0)
      {
        data.setSigned(x: x, y: y, value: stored - shadingValueOffset);
      }
    }
  }
}

/// The pixel list files before version 6 stored instead of a box.
void _readShadingPixelList({required final FileByteReader reader, required final PixelGrid data})
{
  final int dataCount = reader.getUint32();
  for (int j = 0; j < dataCount; j++)
  {
    final int x = reader.getUint16();
    final int y = reader.getUint16();
    //-128, which one byte can hold, is beyond any shading limit and beyond what a signed pixel can store
    final int shading = reader.getInt8().clamp(-SignedPixels.maxMagnitude, SignedPixels.maxMagnitude);
    data.setSigned(x: x, y: y, value: shading);
  }
}

/// Reads the sections of a kpix file body in file order.
class _KPixParser
{
  _KPixParser({
    required this.reader,
    required this.guard,
    required this.version,
    required this.drawingConstraints,
    required this.shadingConstraints,
    required this.frameConstraints,
  });

  final FileByteReader reader;
  final _ImportGuard guard;
  final int version;
  final DrawingLayerSettingsConstraints drawingConstraints;
  final ShadingLayerSettingsConstraints shadingConstraints;
  final FrameConstraints frameConstraints;

  T _readMapped<T extends Object>({required final T? Function(int id) fromId, required final T? fallback, required final String label})
  {
    final int raw = reader.getUint8();
    return guard.mapped(value: fromId(raw), raw: raw, fallback: fallback, label: label);
  }

  List<HistoryRampData> readRamps()
  {
    final int rampCount = reader.getUint8();
    if (rampCount < 1) throw const _ImportRejected("No color ramp found");
    return <HistoryRampData>[
      for (int i = 0; i < rampCount; i++) _readRamp(index: i),
    ];
  }

  HistoryRampData _readRamp({required final int index})
  {
    final KPalRampSettings kPalRampSettings = KPalRampSettings();

    kPalRampSettings.colorCount = reader.getUint8();
    if (kPalRampSettings.colorCount < KPalConstraints.colorCountMin || kPalRampSettings.colorCount > KPalConstraints.colorCountMax) throw _ImportRejected("Invalid color count in palette $index: ${kPalRampSettings.colorCount}");

    kPalRampSettings.baseHue = guard.ranged(
      value: reader.getInt16(),
      min: KPalConstraints.baseHueMin,
      max: KPalConstraints.baseHueMax,
      fallback: KPalConstraints.baseHueMin,
      label: "Invalid base hue in ramp $index",
    );

    kPalRampSettings.baseSat = guard.ranged(
      value: reader.getUint8(),
      min: KPalConstraints.baseSatMin,
      max: KPalConstraints.baseSatMax,
      fallback: KPalConstraints.baseSatMin,
      label: "Invalid base sat in ramp $index",
    );

    kPalRampSettings.hueShift = guard.ranged(
      value: reader.getInt8(),
      min: KPalConstraints.hueShiftMin,
      max: KPalConstraints.hueShiftMax,
      fallback: KPalConstraints.hueShiftMin,
      label: "Invalid hue shift value in ramp $index",
    );

    kPalRampSettings.hueShiftExp = guard.ranged(
      value: reader.getUint8().toDouble() / 100.0,
      min: KPalConstraints.hueShiftExpMin,
      max: KPalConstraints.hueShiftExpMax,
      fallback: KPalConstraints.hueShiftExpMin,
      label: "Invalid hue shift exp in ramp $index",
    );

    kPalRampSettings.satShift = guard.ranged(
      value: reader.getInt8(),
      min: KPalConstraints.satShiftMin,
      max: KPalConstraints.satShiftMax,
      fallback: KPalConstraints.satShiftMin,
      label: "Invalid sat shift in ramp $index",
    );

    kPalRampSettings.satShiftExp = guard.ranged(
      value: reader.getUint8().toDouble() / 100.0,
      min: KPalConstraints.satShiftExpMin,
      max: KPalConstraints.satShiftExpMax,
      fallback: KPalConstraints.satShiftExpMin,
      label: "Invalid sat shift exp in ramp $index",
    );

    kPalRampSettings.satCurve = _readMapped(fromId: SatCurve.fromId, fallback: KPalConstraints.satCurveDefault, label: "Invalid sat curve for palette $index");

    kPalRampSettings.valueRangeMin = guard.ranged(
      value: reader.getUint8(),
      min: KPalConstraints.valueRangeMin,
      max: KPalConstraints.valueRangeMax,
      fallback: KPalConstraints.valueRangeMin,
      label: "Invalid min value range in ramp $index",
    );

    kPalRampSettings.valueRangeMax = guard.ranged(
      value: reader.getUint8(),
      min: kPalRampSettings.valueRangeMin,
      max: KPalConstraints.valueRangeMax,
      fallback: KPalConstraints.valueRangeMax,
      label: "Invalid max value range in ramp $index",
    );

    final List<ShiftSet> shifts = <ShiftSet>[];
    for (int j = 0; j < kPalRampSettings.colorCount; j++)
    {
      final int hueShift = guard.ranged(
        value: reader.getInt8(),
        min: KPalSliderConstraints.minHue,
        max: KPalSliderConstraints.maxHue,
        fallback: 0,
        label: "Invalid Hue Shift in Ramp $index, color $j",
      );

      final int satShift = guard.ranged(
        value: reader.getInt8(),
        min: KPalSliderConstraints.minSat,
        max: KPalSliderConstraints.maxSat,
        fallback: 0,
        label: "Invalid Sat Shift in Ramp $index, color $j",
      );

      final int valShift = guard.ranged(
        value: reader.getInt8(),
        min: KPalSliderConstraints.minVal,
        max: KPalSliderConstraints.maxVal,
        fallback: 0,
        label: "Invalid Val Shift in Ramp $index, color $j",
      );
      shifts.add(ShiftSet(hueShiftNotifier: ValueNotifier<int>(hueShift), satShiftNotifier: ValueNotifier<int>(satShift), valShiftNotifier: ValueNotifier<int>(valShift)));
    }
    return HistoryRampData(otherSettings: kPalRampSettings, uuid: const Uuid().v1(), notifierShifts: shifts);
  }

  CoordinateSetI readCanvasSize()
  {
    final int width = reader.getUint16();
    final int height = reader.getUint16();
    return CoordinateSetI(x: width, y: height);
  }

  LinkedHashSet<HistoryLayer> readLayers({required final List<HistoryRampData> ramps, required final CoordinateSetI canvasSize})
  {
    final int layerCount = version >= 3 ? reader.getUint16() : reader.getUint8();
    if (layerCount < 1) throw const _ImportRejected("No layer found");
    final LinkedHashSet<HistoryLayer> layers = LinkedHashSet<HistoryLayer>();
    for (int i = 0; i < layerCount; i++)
    {
      // An unknown layer type is never recoverable: layer records carry no
      // length prefix, so skipping one desynchronises the byte stream, and
      // frame layer indices are positional. Hence the null fallback.
      final Type layerType = _readMapped(fromId: (final int id) => historyLayerIdToType[id], fallback: null, label: "Invalid layer type for layer $i");
      final LayerVisibilityState visibilityState = _readMapped(fromId: LayerVisibilityState.fromId, fallback: LayerVisibilityState.visible, label: "Invalid visibility type for layer $i");

      if (layerType == HistoryDrawingLayer)
      {
        layers.add(_readDrawingLayer(index: i, visibilityState: visibilityState, ramps: ramps, canvasSize: canvasSize));
      }
      else if (layerType == HistoryReferenceLayer)
      {
        layers.add(_readReferenceLayer(index: i, visibilityState: visibilityState));
      }
      else if (layerType == HistoryGridLayer)
      {
        layers.add(_readGridLayer(index: i, visibilityState: visibilityState));
      }
      else if (layerType == HistoryShadingLayer || layerType == HistoryDitherLayer)
      {
        layers.add(_readShadingLayer(index: i, visibilityState: visibilityState, isDither: layerType == HistoryDitherLayer, canvasSize: canvasSize));
      }
    }
    return layers;
  }

  HistoryDrawingLayer _readDrawingLayer({required final int index, required final LayerVisibilityState visibilityState, required final List<HistoryRampData> ramps, required final CoordinateSetI canvasSize})
  {
    final LayerLockState lockState = _readMapped(fromId: LayerLockState.fromId, fallback: LayerLockState.unlocked, label: "Invalid lock type for layer $index");
    final HistoryDrawingLayerSettings settings = version >= 2
        ? _readDrawingLayerSettings(index: index, ramps: ramps)
        : HistoryDrawingLayerSettings.defaultValues(constraints: drawingConstraints, colRef: const HistoryColorReference(colorIndex: 0, rampIndex: 0));

    //a pixel outside the canvas is dropped by the grid
    final PixelGrid data = PixelGrid(width: canvasSize.x, height: canvasSize.y);
    if (version >= 6)
    {
      _readDrawingPixels(reader: reader, data: data, rampList: ramps, layerIndex: index);
    }
    else
    {
      _readDrawingPixelList(reader: reader, data: data, rampList: ramps, layerIndex: index);
    }
    return HistoryDrawingLayer(visibilityState: visibilityState, lockState: lockState, pixels: data.snapshot(), settings: settings, layerIdentity: index);
  }

  /// A color reference as two indices; [owner] names the effect it belongs to.
  HistoryColorReference _readColorReference({required final String owner, required final int index, required final List<HistoryRampData> ramps})
  {
    final int rampIndex = guard.ranged(
      value: reader.getUint8(),
      min: 0,
      max: ramps.length - 1,
      fallback: 0,
      label:  "$owner Color Ramp index out of range for layer $index",
    );
    final int colorIndex = guard.ranged(
      value: reader.getUint8(),
      min: 0,
      max: ramps[rampIndex].settings.colorCount - 1,
      fallback: 0,
      label: "$owner Color index out of range for layer $index",
    );
    return HistoryColorReference(colorIndex: colorIndex, rampIndex: rampIndex);
  }

  int _readDarkenBrighten({required final String owner, required final int index})
  {
    return guard.ranged(
      value: reader.getInt8(),
      min: drawingConstraints.darkenBrightenMin,
      max: drawingConstraints.darkenBrightenMax,
      fallback: drawingConstraints.darkenBrightenDefault,
      label: "Darken/Brighten for $owner is out of range for layer $index",
    );
  }

  int _readGlowDepth({required final String owner, required final int index})
  {
    return guard.ranged(
      value: reader.getInt8(),
      min: drawingConstraints.glowDepthMin,
      max: drawingConstraints.glowDepthMax,
      fallback: drawingConstraints.glowDepthDefault,
      label: "Glow Depth for $owner is out of range for layer $index",
    );
  }

  int _readDropShadowOffset({required final String axis, required final int index})
  {
    return guard.ranged(
      value: reader.getInt8(),
      min: drawingConstraints.dropShadowOffsetMin,
      max: drawingConstraints.dropShadowOffsetMax,
      fallback: drawingConstraints.dropShadowOffsetDefault,
      label: "Drop Shadow offset $axis is out of range for layer $index",
    );
  }

  HistoryDrawingLayerSettings _readDrawingLayerSettings({required final int index, required final List<HistoryRampData> ramps})
  {
    // OUTER STROKE
    final OuterStrokeStyle outerStrokeStyle = _readMapped(fromId: OuterStrokeStyle.fromId, fallback: OuterStrokeStyle.off, label: "Invalid outer stroke style for layer $index");
    final HashMap<Alignment, bool> outerStrokeDirections = _unPackAlignments(byte: reader.getUint8());
    final HistoryColorReference outerColorReference = _readColorReference(owner: "Outer Stroke", index: index, ramps: ramps);
    final int outerStrokeDarkenBrighten = _readDarkenBrighten(owner: "outer stroke", index: index);
    final int outerStrokeGlowDepth = _readGlowDepth(owner: "outer stroke", index: index);
    final bool outerStrokeGlowRecursive = guard.flag(
      value: reader.getUint8(),
      label: "Invalid outer stroke glow recursive value for layer $index",
    );

    // INNER STROKE
    final InnerStrokeStyle innerStrokeStyle = _readMapped(fromId: InnerStrokeStyle.fromId, fallback: InnerStrokeStyle.off, label: "Invalid inner stroke style for layer $index");
    final HashMap<Alignment, bool> innerStrokeDirections = _unPackAlignments(byte: reader.getUint8());
    final HistoryColorReference innerColorReference = _readColorReference(owner: "Inner Stroke", index: index, ramps: ramps);
    final int innerStrokeDarkenBrighten = _readDarkenBrighten(owner: "inner stroke", index: index);
    final int innerStrokeGlowDepth = _readGlowDepth(owner: "inner stroke", index: index);
    final bool innerStrokeGlowRecursive = guard.flag(
      value: reader.getUint8(),
      label: "Invalid inner stroke glow recursive value for layer $index",
    );
    final int innerStrokeBevelDistance = guard.ranged(
      value: reader.getUint8(),
      min: drawingConstraints.bevelDistanceMin,
      max: drawingConstraints.bevelDistanceMax,
      fallback: drawingConstraints.bevelDistanceDefault,
      label: "Bevel Distance out of range for layer $index",
    );
    final int innerStrokeBevelStrength = guard.ranged(
      value: reader.getUint8(),
      min: drawingConstraints.bevelStrengthMin,
      max: drawingConstraints.bevelStrengthMax,
      fallback: drawingConstraints.bevelStrengthDefault,
      label: "Bevel Strength out of range for layer $index",
    );

    // DROP SHADOW
    final DropShadowStyle dropShadowStyle = _readMapped(fromId: DropShadowStyle.fromId, fallback: DropShadowStyle.off, label: "Invalid drop shadow style for layer $index");
    final HistoryColorReference dropShadowColorReference = _readColorReference(owner: "Drop Shadow", index: index, ramps: ramps);
    final int dropShadowOffsetX = _readDropShadowOffset(axis: "x", index: index);
    final int dropShadowOffsetY = _readDropShadowOffset(axis: "y", index: index);
    final int dropShadowDarkenBrighten = _readDarkenBrighten(owner: "drop shadow", index: index);

    return HistoryDrawingLayerSettings(
      constraints: drawingConstraints,
      outerStrokeStyle: outerStrokeStyle,
      outerSelectionMap: outerStrokeDirections,
      outerColorReference: outerColorReference,
      outerDarkenBrighten: outerStrokeDarkenBrighten,
      outerGlowDepth: outerStrokeGlowDepth,
      outerGlowRecursive: outerStrokeGlowRecursive,
      innerStrokeStyle: innerStrokeStyle,
      innerSelectionMap: innerStrokeDirections,
      innerColorReference: innerColorReference,
      innerDarkenBrighten: innerStrokeDarkenBrighten,
      innerGlowDepth: innerStrokeGlowDepth,
      innerGlowRecursive: innerStrokeGlowRecursive,
      bevelDistance: innerStrokeBevelDistance,
      bevelStrength: innerStrokeBevelStrength,
      dropShadowStyle: dropShadowStyle,
      dropShadowColorReference: dropShadowColorReference,
      dropShadowOffset: CoordinateSetI(x: dropShadowOffsetX, y: dropShadowOffsetY),
      dropShadowDarkenBrighten: dropShadowDarkenBrighten,);
  }

  HistoryReferenceLayer _readReferenceLayer({required final int index, required final LayerVisibilityState visibilityState})
  {
    //path (string)
    final int pathLength = reader.getInt16();
    final List<int> pathBytes = <int>[];
    for (int i = 0; i < pathLength; i++)
    {
      pathBytes.add(reader.getUint8());
    }
    final String pathString = utf8.decode(pathBytes);
    //opacity ``ubyte (1)`` // 0...100
    final int opacity = guard.ranged(
      value: reader.getUint8(),
      min: ReferenceLayerConstraints.opacityMin,
      max: ReferenceLayerConstraints.opacityMax,
      fallback: ReferenceLayerConstraints.opacityDefault,
      label: "Opacity for reference layer is out of range",
    );

    //offset_x ``float (1)``
    final double offsetX = reader.getFloat32();
    //offset_y ``float (1)``
    final double offsetY = reader.getFloat32();

    //zoom ``ushort (1)``
    final int zoom = guard.ranged(
      value: reader.getUint16(),
      min: ReferenceLayerConstraints.zoomMin,
      max: ReferenceLayerConstraints.zoomMax,
      fallback: ReferenceLayerConstraints.zoomDefault,
      label: "Zoom for reference layer is out of range",
    );

    //aspect_ratio ``float (1)``
    final double aspectRatio = guard.approx(
      value: reader.getFloat32(),
      min: ReferenceLayerConstraints.aspectRatioMin,
      max: ReferenceLayerConstraints.aspectRatioMax,
      fallback: ReferenceLayerConstraints.aspectRatioDefault,
      label: "Aspect ratio for reference layer is out of range",
    );

    double brightness = ReferenceLayerConstraints.brightnessDefault;
    double contrast = ReferenceLayerConstraints.contrastDefault;
    double saturation = ReferenceLayerConstraints.saturationDefault;
    double warmth = ReferenceLayerConstraints.warmthDefault;

    if (version >= 4)
    {
      //brightness ``float (1)`` // -1...1
      brightness = guard.ranged(
        value: reader.getFloat32(),
        min: ReferenceLayerConstraints.brightnessMin,
        max: ReferenceLayerConstraints.brightnessMax,
        fallback: ReferenceLayerConstraints.brightnessDefault,
        label: "Brightness for reference layer is out of range",
      );

      //contrast ``float (1)`` // 0...2
      contrast = guard.ranged(
        value: reader.getFloat32(),
        min: ReferenceLayerConstraints.contrastMin,
        max: ReferenceLayerConstraints.contrastMax,
        fallback: ReferenceLayerConstraints.contrastDefault,
        label: "Contrast for reference layer is out of range",
      );

      //saturation ``float (1)`` // 0...2
      saturation = guard.ranged(
        value: reader.getFloat32(),
        min: ReferenceLayerConstraints.saturationMin,
        max: ReferenceLayerConstraints.saturationMax,
        fallback: ReferenceLayerConstraints.saturationDefault,
        label: "Saturation for reference layer is out of range",
      );

      //warmth ``float (1)`` // -1...1
      warmth = guard.ranged(
        value: reader.getFloat32(),
        min: ReferenceLayerConstraints.warmthMin,
        max: ReferenceLayerConstraints.warmthMax,
        fallback: ReferenceLayerConstraints.warmthDefault,
        label: "Warmth for reference layer is out of range",
      );
    }
    return HistoryReferenceLayer(
      visibilityState: visibilityState,
      zoom: zoom,
      opacity: opacity,
      offsetY: offsetY,
      offsetX: offsetX,
      path: pathString,
      aspectRatio: aspectRatio,
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      warmth: warmth,
      layerIdentity: index,
    );
  }

  HistoryGridLayer _readGridLayer({required final int index, required final LayerVisibilityState visibilityState})
  {
    //opacity ``ubyte (1)`` // 0...100
    final int opacity = guard.ranged(
      value: reader.getUint8(),
      min: GridLayerConstraints.opacityMin,
      max: GridLayerConstraints.opacityMax,
      fallback: GridLayerConstraints.opacityDefault,
      label: "Opacity for grid layer is out of range",
    );

    //brightness ``ubyte (1)`` // 0...100
    final int brightness = guard.ranged(
      value:  reader.getUint8(),
      min: GridLayerConstraints.brightnessMin,
      max: GridLayerConstraints.brightnessMax,
      fallback: GridLayerConstraints.brightnessDefault,
      label: "Brightness for grid layer is out of range",
    );

    final GridType gridType = _readMapped(fromId: GridType.fromId, fallback: GridType.rectangular, label: "Invalid grid type for layer $index");

    //interval_x ``ubyte (1)`` // 2...64
    final int intervalX = guard.ranged(
      value: reader.getUint8(),
      min: GridLayerConstraints.intervalXMin,
      max: GridLayerConstraints.intervalXMax,
      fallback: GridLayerConstraints.intervalXDefault,
      label: "Interval X for grid layer is out of range",
    );

    //interval_y ``ubyte (1)`` // 2...64
    final int intervalY = guard.ranged(
      value: reader.getUint8(),
      min: GridLayerConstraints.intervalYMin,
      max: GridLayerConstraints.intervalYMax,
      fallback: GridLayerConstraints.intervalYDefault,
      label: "Interval Y for grid layer is out of range",
    );

    //horizon_position ``float (1)``// 0...1 (vertical horizon position)
    final double horizon = guard.approx(
      value: reader.getFloat32(),
      min: GridLayerConstraints.vanishingPointMin,
      max: GridLayerConstraints.vanishingPointMax,
      fallback: GridLayerConstraints.horizonDefault,
      label: "Horizon for grid layer is out of range",
    );

    //vanishing_point_1 ``float (1)``// 0...1 (horizontal position of first vanishing point)
    final double vanishingPoint1 = guard.approx(
      value: reader.getFloat32(),
      min: GridLayerConstraints.vanishingPointMin,
      max: GridLayerConstraints.vanishingPointMax,
      fallback: GridLayerConstraints.vanishingPoint1Default,
      label: "Vanishing Point 1 for grid layer is out of range",
    );

    //vanishing_point_2 ``float (1)``// 0...1 (horizontal position of second vanishing point)
    final double vanishingPoint2 = guard.approx(
      value: reader.getFloat32(),
      min: GridLayerConstraints.vanishingPointMin,
      max: GridLayerConstraints.vanishingPointMax,
      fallback: GridLayerConstraints.vanishingPoint2Default,
      label: "Vanishing Point 2 for grid layer is out of range",
    );

    //vanishing_point_3 ``float (1)``// 0...1 (vertical position of third vanishing point)
    final double vanishingPoint3 = guard.approx(
      value: reader.getFloat32(),
      min: GridLayerConstraints.vanishingPointMin,
      max: GridLayerConstraints.vanishingPointMax,
      fallback: GridLayerConstraints.vanishingPoint3Default,
      label: "Vanishing Point 3 for grid layer is out of range",
    );

    return HistoryGridLayer(visibilityState: visibilityState, opacity: opacity, gridType: gridType, brightness: brightness, intervalX: intervalX, intervalY: intervalY, horizonPosition: horizon, vanishingPoint1: vanishingPoint1, vanishingPoint2: vanishingPoint2, vanishingPoint3: vanishingPoint3, layerIdentity: index);
  }

  HistoryShadingLayer _readShadingLayer({required final int index, required final LayerVisibilityState visibilityState, required final bool isDither, required final CoordinateSetI canvasSize})
  {
    final LayerLockState lockState = _readMapped(fromId: LayerLockState.fromId, fallback: LayerLockState.unlocked, label: "Invalid lock type for layer $index");

    HistoryShadingLayerSettings settings = HistoryShadingLayerSettings.defaultValue(constraints: shadingConstraints);
    if (version >= 2)
    {
      final int topLimit = isDither ? shadingConstraints.ditherStepsMax : shadingConstraints.shadingStepsMax;
      final int shadingStepLimitLow = guard.ranged(
        value: reader.getUint8(),
        min: shadingConstraints.shadingStepsMin,
        max: topLimit,
        fallback: shadingConstraints.shadingStepsDefaultDarken,
        label: "Shading step limit low is out of range for layer $index",
      );
      final int shadingStepLimitHigh = guard.ranged(
        value: reader.getUint8(),
        min: shadingConstraints.shadingStepsMin,
        max: topLimit,
        fallback: shadingConstraints.shadingStepsDefaultBrighten,
        label: "Shading step limit high is out of range for layer $index",
      );
      settings = HistoryShadingLayerSettings(constraints: shadingConstraints, shadingLow: shadingStepLimitLow, shadingHigh: shadingStepLimitHigh);
    }

    //a pixel outside the canvas is dropped by the grid
    final PixelGrid data = PixelGrid(width: canvasSize.x, height: canvasSize.y);
    if (version >= 6)
    {
      _readShadingPixels(reader: reader, data: data);
    }
    else
    {
      _readShadingPixelList(reader: reader, data: data);
    }

    return isDither
        ? HistoryDitherLayer(visibilityState: visibilityState, lockState: lockState, pixels: data.snapshot(), settings: settings, layerIdentity: index)
        : HistoryShadingLayer(visibilityState: visibilityState, lockState: lockState, pixels: data.snapshot(), settings: settings, layerIdentity: index);
  }

  HistoryTimeline readTimeline({required final LinkedHashSet<HistoryLayer> layers})
  {
    if (version < 3)
    {
      final HistoryFrame frame = HistoryFrame(fps: frameConstraints.defaultFps, layerIndices: LinkedHashSet<int>.of(<int>[for (int i = 0; i < layers.length; i++) i]), selectedLayerIndex: 0);
      return HistoryTimeline(frames: <HistoryFrame>[frame], loopStart: 0, loopEnd: 0, selectedFrameIndex: 0, allLayers: layers);
    }

    //before version 5 the counts and indices were single bytes, which could
    //not hold a full frame (256 layers), a full timeline or a layer past the 256th
    final int Function() readTimelineValue = version >= 5 ? reader.getUint16 : reader.getUint8;
    final int framesCount = readTimelineValue();
    final int startFrame = readTimelineValue();
    final int endFrame = readTimelineValue();

    final List<HistoryFrame> frames = <HistoryFrame>[];
    for (int i = 0; i < framesCount; i++)
    {
      final LinkedHashSet<int> indices = LinkedHashSet<int>();
      final int fps = reader.getUint8();
      final int layerCount = readTimelineValue();
      for (int j = 0; j < layerCount; j++)
      {
        final int layerIndex = readTimelineValue();
        if (layerIndex >= layers.length) throw _ImportRejected("Layer index out of range in frame $i: $layerIndex");
        indices.add(layerIndex);
      }
      frames.add(HistoryFrame(fps: fps, layerIndices: indices, selectedLayerIndex: 0));
    }
    return HistoryTimeline(frames: frames, loopStart: startFrame, loopEnd: endFrame, selectedFrameIndex: 0, allLayers: layers);
  }
}

//TODO strict parameter could be a (dev) setting
/// Reads a kpix file and turns it into a restorable history state.
///
/// The parsing runs on a background isolate, so opening a large project does not
/// freeze the UI. Only plain data crosses over, and the result is transferred
/// rather than copied, so a large pixel map costs nothing to hand back.
Future<LoadFileSet> loadKPixFile({required final Uint8List? fileData, required final String path, required final DrawingLayerSettingsConstraints drawingLayerSettingsConstraints, required final ShadingLayerSettingsConstraints shadingLayerSettingsConstraints, required final FrameConstraints frameConstraints, final bool strict = false}) async
{
  //web has no file system, so a caller that did not bring the bytes cannot be
  //served; reading through dart:io would fail with an unrelated message
  if (fileData == null && kIsWeb)
  {
    return LoadFileSet(status: "No file data for $path");
  }
  final Uint8List bytes = fileData ?? await File(path).readAsBytes();

  return await runOffThread<LoadFileSet>(
    debugLabel: "kpix-load",
    work: () => _parseKPixFile(
      bytes: bytes,
      path: path,
      drawingLayerSettingsConstraints: drawingLayerSettingsConstraints,
      shadingLayerSettingsConstraints: shadingLayerSettingsConstraints,
      frameConstraints: frameConstraints,
      strict: strict,
    ),
  );
}

/// Turns the bytes of a kpix file into a history state.
///
/// Runs on a background isolate, so it must not reach for the service locator or
/// anything from dart:ui: everything it needs arrives as a parameter.
LoadFileSet _parseKPixFile({required final Uint8List bytes, required final String path, required final DrawingLayerSettingsConstraints drawingLayerSettingsConstraints, required final ShadingLayerSettingsConstraints shadingLayerSettingsConstraints, required final FrameConstraints frameConstraints, final bool strict = false})
{
  final StringBuffer returnString = StringBuffer();
  final _ImportGuard guard = _ImportGuard(strict: strict, warnings: returnString);
  try
  {
    FileByteReader reader = FileByteReader(bytes);
    final int mNumber = reader.getUint32();
    final int fVersion = reader.getUint8();

    if (mNumber != int.parse(magicNumber, radix: 16)) return LoadFileSet(status: "Wrong magic number: $mNumber");
    if (fVersion > fileVersion) return LoadFileSet(status: "File Version: $fVersion");
    if (fVersion >= 6)
    {
      //everything after the header is compressed
      reader = FileByteReader(const ZLibDecoder().decodeBytes(Uint8List.sublistView(bytes, reader.offset), verify: true));
    }

    final _KPixParser parser = _KPixParser(
      reader: reader,
      guard: guard,
      version: fVersion,
      drawingConstraints: drawingLayerSettingsConstraints,
      shadingConstraints: shadingLayerSettingsConstraints,
      frameConstraints: frameConstraints,
    );
    final List<HistoryRampData> rampList = parser.readRamps();
    final CoordinateSetI canvasSize = parser.readCanvasSize();
    final LinkedHashSet<HistoryLayer> layerList = parser.readLayers(ramps: rampList, canvasSize: canvasSize);
    final HistoryTimeline hTimeline = parser.readTimeline(layers: layerList);

    final HistorySelectionState selectionState = HistorySelectionState.empty();
    final HistoryState historyState = HistoryState(timeline: hTimeline, selectedColor: const HistoryColorReference(colorIndex: 0, rampIndex: 0), selectionState: selectionState, canvasSize: canvasSize, rampList: rampList, type: const HistoryStateType(identifier: HistoryStateTypeIdentifier.loadData, compressionBehavior: HistoryStateCompressionBehavior.leave));

    return LoadFileSet(status: returnString.toString(), historyState: historyState, path: path);
  }
  on _ImportRejected catch (e)
  {
    return LoadFileSet(status: e.message);
  }
  catch (pnfe)
  {
    return LoadFileSet(status: "Could not load file $path");
  }
}
