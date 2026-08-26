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

part of '../file_handler.dart';

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
    final double delta = _floatDelta,
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
    final FileByteReader reader = FileByteReader(bytes);
    final int mNumber = reader.getUint32();
    final int fVersion = reader.getUint8();

    if (mNumber != int.parse(magicNumber, radix: 16)) return LoadFileSet(status: "Wrong magic number: $mNumber");
    if (fVersion > fileVersion) return LoadFileSet(status: "File Version: $fVersion");

    final int rampCount = reader.getUint8();
    if (rampCount < 1) return LoadFileSet(status: "No color ramp found");
    final List<HistoryRampData> rampList = <HistoryRampData>[];
    for (int i = 0; i < rampCount; i++)
    {
      final KPalRampSettings kPalRampSettings = KPalRampSettings();

      kPalRampSettings.colorCount = reader.getUint8();
      if (kPalRampSettings.colorCount < KPalConstraints.colorCountMin || kPalRampSettings.colorCount > KPalConstraints.colorCountMax) return LoadFileSet(status: "Invalid color count in palette $i: ${kPalRampSettings.colorCount}");

      // BASE HUE
      kPalRampSettings.baseHue = guard.ranged(
        value: reader.getInt16(),
        min: KPalConstraints.baseHueMin,
        max: KPalConstraints.baseHueMax,
        fallback: KPalConstraints.baseHueMin,
        label: "Invalid base hue in ramp $i",
      );

      // BASE SAT
      kPalRampSettings.baseSat = guard.ranged(
        value: reader.getUint8(),
        min: KPalConstraints.baseSatMin,
        max: KPalConstraints.baseSatMax,
        fallback: KPalConstraints.baseSatMin,
        label: "Invalid base sat in ramp $i",
      );

      // HUE SHIFT
      kPalRampSettings.hueShift = guard.ranged(
        value: reader.getInt8(),
        min: KPalConstraints.hueShiftMin,
        max: KPalConstraints.hueShiftMax,
        fallback: KPalConstraints.hueShiftMin,
        label: "Invalid hue shift value in ramp $i",
      );

      // HUE SHIFT EXP
      kPalRampSettings.hueShiftExp = guard.ranged(
        value: reader.getUint8().toDouble() / 100.0,
        min: KPalConstraints.hueShiftExpMin,
        max: KPalConstraints.hueShiftExpMax,
        fallback: KPalConstraints.hueShiftExpMin,
        label: "Invalid hue shift exp in ramp $i",
      );

      // SAT SHIFT
      kPalRampSettings.satShift = guard.ranged(
        value: reader.getInt8(),
        min: KPalConstraints.satShiftMin,
        max: KPalConstraints.satShiftMax,
        fallback: KPalConstraints.satShiftMin,
        label: "Invalid sat shift in ramp $i",
      );

      // SAT SHIFT EXP
      kPalRampSettings.satShiftExp = guard.ranged(
        value: reader.getUint8().toDouble() / 100.0,
        min: KPalConstraints.satShiftExpMin,
        max: KPalConstraints.satShiftExpMax,
        fallback: KPalConstraints.satShiftExpMin,
        label: "Invalid sat shift exp in ramp $i",
      );

      // CURVE
      final int curveVal = reader.getUint8();
      kPalRampSettings.satCurve = guard.mapped(
        value: SatCurve.fromId(curveVal),
        raw: curveVal,
        fallback: KPalConstraints.satCurveDefault,
        label: "Invalid sat curve for palette $i",
      );

      // VALUE RANGE MIN
      kPalRampSettings.valueRangeMin = guard.ranged(
        value: reader.getUint8(),
        min: KPalConstraints.valueRangeMin,
        max: KPalConstraints.valueRangeMax,
        fallback: KPalConstraints.valueRangeMin,
        label: "Invalid min value range in ramp $i",
      );

      kPalRampSettings.valueRangeMax = guard.ranged(
        value: reader.getUint8(),
        min: kPalRampSettings.valueRangeMin,
        max: KPalConstraints.valueRangeMax,
        fallback: KPalConstraints.valueRangeMax,
        label: "Invalid max value range in ramp $i",
      );


      //COLOR SHIFTS
      final List<ShiftSet> shifts = <ShiftSet>[];
      for (int j = 0; j < kPalRampSettings.colorCount; j++)
      {
        //COLOR SHIFT HUE
        final int hueShift = guard.ranged(
          value: reader.getInt8(),
          min: KPalSliderConstraints.minHue,
          max: KPalSliderConstraints.maxHue,
          fallback: 0,
          label: "Invalid Hue Shift in Ramp $i, color $j",
        );

        //COLOR SHIFT SAT
        final int satShift = guard.ranged(
          value: reader.getInt8(),
          min: KPalSliderConstraints.minSat,
          max: KPalSliderConstraints.maxSat,
          fallback: 0,
          label: "Invalid Sat Shift in Ramp $i, color $j",
        );

        // COLOR SHIFT VAL
        final int valShift = guard.ranged(
          value: reader.getInt8(),
          min: KPalSliderConstraints.minVal,
          max: KPalSliderConstraints.maxVal,
          fallback: 0,
          label: "Invalid Val Shift in Ramp $i, color $j",
        );
        final ShiftSet shiftSet = ShiftSet(hueShiftNotifier: ValueNotifier<int>(hueShift), satShiftNotifier: ValueNotifier<int>(satShift), valShiftNotifier: ValueNotifier<int>(valShift));
        shifts.add(shiftSet);
      }
      rampList.add(HistoryRampData(otherSettings: kPalRampSettings, uuid: const Uuid().v1(), notifierShifts: shifts));
    }

    final int width = reader.getUint16();
    final int height = reader.getUint16();
    final CoordinateSetI canvasSize = CoordinateSetI(x: width, y: height);
    int layerCount = 0;
    if (fVersion >= 3)
    {
      layerCount = reader.getUint16();
    }
    else
    {
      layerCount = reader.getUint8();
    }
    if (layerCount < 1) return LoadFileSet(status: "No layer found");
    final LinkedHashSet<HistoryLayer> layerList = LinkedHashSet<HistoryLayer>();
    for (int i = 0; i < layerCount; i++)
    {
      // LAYER TYPE
      // An unknown layer type is never recoverable: layer records carry no
      // length prefix, so skipping one desynchronises the byte stream, and
      // frame layer indices are positional. Hence the null fallback.
      final int layerTypeVal = reader.getUint8();
      final Type layerType = guard.mapped(
        value: historyLayerIdToType[layerTypeVal],
        raw: layerTypeVal,
        fallback: null,
        label: "Invalid layer type for layer $i",
      );

      // VISIBILITY STATE
      final int visibilityStateVal = reader.getUint8();
      final LayerVisibilityState visibilityState = guard.mapped(
        value: LayerVisibilityState.fromId(visibilityStateVal),
        raw: visibilityStateVal,
        fallback: LayerVisibilityState.visible,
        label: "Invalid visibility type for layer $i",
      );


      if (layerType == HistoryDrawingLayer) //DRAWING LAYER
      {
        HistoryDrawingLayerSettings drawingLayerSettings = HistoryDrawingLayerSettings.defaultValues(constraints: drawingLayerSettingsConstraints, colRef: const HistoryColorReference(colorIndex: 0, rampIndex: 0));

        // LOCK STATE
        final int lockStateVal = reader.getUint8();
        final LayerLockState lockState = guard.mapped(
          value: LayerLockState.fromId(lockStateVal),
          raw: lockStateVal,
          fallback: LayerLockState.unlocked,
          label: "Invalid lock type for layer $i",
        );

        if (fVersion >= 2)
        {
          // OUTER STROKE STYLE
          final int outerStrokeStyleVal = reader.getUint8();
          final OuterStrokeStyle outerStrokeStyle = guard.mapped(
            value: OuterStrokeStyle.fromId(outerStrokeStyleVal),
            raw: outerStrokeStyleVal,
            fallback: OuterStrokeStyle.off,
            label: "Invalid outer stroke style for layer $i",
          );


          // OUTER STROKE ALIGNMENT
          final int outerAlignmentMask = reader.getUint8();
          final HashMap<Alignment, bool> outerStrokeDirections = _unPackAlignments(byte: outerAlignmentMask);

          // OUTER STROKE COLOR RAMP INDEX
          final int outerStrokeColorRampIndex = guard.ranged(
            value: reader.getUint8(),
            min: 0,
            max: rampList.length - 1,
            fallback: 0,
            label:  "Outer Stroke Color Ramp index out of range for layer $i",
          );

          // OUTER STROKE COLOR INDEX
          final int outerStrokeColorIndex = guard.ranged(
            value: reader.getUint8(),
            min: 0,
            max: rampList[outerStrokeColorRampIndex].settings.colorCount - 1,
            fallback: 0,
            label: "Outer Stroke Color index out of range for layer $i",
          );

          final HistoryColorReference outerColorReference = HistoryColorReference(colorIndex: outerStrokeColorIndex, rampIndex: outerStrokeColorRampIndex);

          // OUTER STROKE DARKEN/BRIGHTEN
          final int outerStrokeDarkenBrighten = guard.ranged(
            value: reader.getInt8(),
            min: drawingLayerSettingsConstraints.darkenBrightenMin,
            max: drawingLayerSettingsConstraints.darkenBrightenMax,
            fallback: drawingLayerSettingsConstraints.darkenBrightenDefault,
            label: "Darken/Brighten for outer stroke is out of range for layer $i",
          );

          // OUTER STROKE GLOW DEPTH
          final int outerStrokeGlowDepth = guard.ranged(
            value: reader.getInt8(),
            min: drawingLayerSettingsConstraints.glowDepthMin,
            max: drawingLayerSettingsConstraints.glowDepthMax,
            fallback: drawingLayerSettingsConstraints.glowDepthDefault,
            label: "Glow Depth for outer stroke is out of range for layer $i",
          );

          // OUTER STROKE GLOW RECURSIVE
          final bool outerStrokeGlowRecursive = guard.flag(
            value: reader.getUint8(),
            label: "Invalid outer stroke glow recursive value for layer $i",
          );

          //INNER STROKE STYLE
          final int innerStrokeStyleVal = reader.getUint8();
          final InnerStrokeStyle innerStrokeStyle = guard.mapped(
            value: InnerStrokeStyle.fromId(innerStrokeStyleVal),
            raw: innerStrokeStyleVal,
            fallback: InnerStrokeStyle.off,
            label: "Invalid inner stroke style for layer $i",
          );

          // INNER STROKE ALIGNMENT
          final int innerAlignmentMask = reader.getUint8();
          final HashMap<Alignment, bool> innerStrokeDirections = _unPackAlignments(byte: innerAlignmentMask);

          // INNER STROKE COLOR RAMP INDEX
          final int innerStrokeColorRampIndex = guard.ranged(
            value: reader.getUint8(),
            min: 0,
            max: rampList.length - 1,
            fallback: 0,
            label:  "Inner Stroke Color Ramp index out of range for layer $i",
          );

          // INNER STROKE COLOR INDEX
          final int innerStrokeColorIndex = guard.ranged(
            value: reader.getUint8(),
            min: 0,
            max: rampList[innerStrokeColorRampIndex].settings.colorCount - 1,
            fallback: 0,
            label: "Inner Stroke Color index out of range for layer $i",
          );

          final HistoryColorReference innerColorReference = HistoryColorReference(colorIndex: innerStrokeColorIndex, rampIndex: innerStrokeColorRampIndex);

          // INNER STROKE DARKEN/BRIGHTEN
          final int innerStrokeDarkenBrighten = guard.ranged(
            value: reader.getInt8(),
            min: drawingLayerSettingsConstraints.darkenBrightenMin,
            max: drawingLayerSettingsConstraints.darkenBrightenMax,
            fallback: drawingLayerSettingsConstraints.darkenBrightenDefault,
            label: "Darken/Brighten for inner stroke is out of range for layer $i",
          );

          // INNER STROKE GLOW DEPTH
          final int innerStrokeGlowDepth = guard.ranged(
            value: reader.getInt8(),
            min: drawingLayerSettingsConstraints.glowDepthMin,
            max: drawingLayerSettingsConstraints.glowDepthMax,
            fallback: drawingLayerSettingsConstraints.glowDepthDefault,
            label: "Glow Depth for inner stroke is out of range for layer $i",
          );

          // INNER STROKE GLOW RECURSIVE
          final bool innerStrokeGlowRecursive = guard.flag(
            value: reader.getUint8(),
            label: "Invalid inner stroke glow recursive value for layer $i",
          );

          // INNER STROKE BEVEL DISTANCE
          final int innerStrokeBevelDistance = guard.ranged(
            value: reader.getUint8(),
            min: drawingLayerSettingsConstraints.bevelDistanceMin,
            max: drawingLayerSettingsConstraints.bevelDistanceMax,
            fallback: drawingLayerSettingsConstraints.bevelDistanceDefault,
            label: "Bevel Distance out of range for layer $i",
          );

          // INNER STROKE BEVEL STRENGTH
          final int innerStrokeBevelStrength = guard.ranged(
            value: reader.getUint8(),
            min: drawingLayerSettingsConstraints.bevelStrengthMin,
            max: drawingLayerSettingsConstraints.bevelStrengthMax,
            fallback: drawingLayerSettingsConstraints.bevelStrengthDefault,
            label: "Bevel Strength out of range for layer $i",
          );

          // DROP SHADOW STYLE
          final int dropShadowStyleVal = reader.getUint8();
          final DropShadowStyle dropShadowStyle = guard.mapped(
            value: DropShadowStyle.fromId(dropShadowStyleVal),
            raw: dropShadowStyleVal,
            fallback: DropShadowStyle.off,
            label: "Invalid drop shadow style for layer $i",
          );

          // DROP SHADOW COLOR RAMP INDEX
          final int dropShadowColorRampIndex = guard.ranged(
            value: reader.getUint8(),
            min: 0,
            max: rampList.length - 1,
            fallback: 0,
            label: "Drop Shadow Color Ramp index out of range for layer $i",
          );

          // DROP SHADOW COLOR INDEX
          final int dropShadowColorIndex = guard.ranged(
            value: reader.getUint8(),
            min: 0,
            max: rampList[dropShadowColorRampIndex].settings.colorCount - 1,
            fallback: 0,
            label: "Drop Shadow Color index out of range for layer $i",
          );

          final HistoryColorReference dropShadowColorReference = HistoryColorReference(colorIndex: dropShadowColorIndex, rampIndex: dropShadowColorRampIndex);

          // DROP SHADOW OFFSET X
          final int dropShadowOffsetX = guard.ranged(
            value: reader.getInt8(),
            min: drawingLayerSettingsConstraints.dropShadowOffsetMin,
            max: drawingLayerSettingsConstraints.dropShadowOffsetMax,
            fallback: drawingLayerSettingsConstraints.dropShadowOffsetDefault,
            label: "Drop Shadow offset x is out of range for layer $i",
          );

          // DROP SHADOW OFFSET Y
          final int dropShadowOffsetY = guard.ranged(
            value: reader.getInt8(),
            min: drawingLayerSettingsConstraints.dropShadowOffsetMin,
            max: drawingLayerSettingsConstraints.dropShadowOffsetMax,
            fallback: drawingLayerSettingsConstraints.dropShadowOffsetDefault,
            label: "Drop Shadow offset y is out of range for layer $i",
          );

          // DROP SHADOW DARKEN/BRIGHTEN
          final int dropShadowDarkenBrighten = guard.ranged(
            value: reader.getInt8(),
            min: drawingLayerSettingsConstraints.darkenBrightenMin,
            max: drawingLayerSettingsConstraints.darkenBrightenMax,
            fallback: drawingLayerSettingsConstraints.darkenBrightenDefault,
            label: "Darken/Brighten for drop shadow is out of range for layer $i",
          );

          drawingLayerSettings = HistoryDrawingLayerSettings(
            constraints: drawingLayerSettingsConstraints,
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
        final int dataCount = reader.getUint32();
        final HashMap<CoordinateSetI, HistoryColorReference> data = HashMap<CoordinateSetI, HistoryColorReference>();
        for (int j = 0; j < dataCount; j++)
        {
          final int x = reader.getUint16();
          final int y = reader.getUint16();
          final int colorRampIndex = reader.getUint8();
          if (colorRampIndex >= rampList.length) return LoadFileSet(status: "Color Ramp index out of range for layer $i : $colorRampIndex");
          final int colorIndex = reader.getUint8();
          if (colorIndex >= rampList[colorRampIndex].settings.colorCount) return LoadFileSet(status: "Color index out of range for layer $i: $colorIndex");
          data[CoordinateSetI(x: x, y: y)] = HistoryColorReference(colorIndex: colorIndex, rampIndex: colorRampIndex);
        }
        layerList.add(HistoryDrawingLayer.full(visibilityState: visibilityState, lockState: lockState, fullData: data, settings: drawingLayerSettings, layerIdentity: i));
      }
      else if (layerType == HistoryReferenceLayer) //REFERENCE LAYER
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

        if (fVersion >= 4)
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
        layerList.add(
            HistoryReferenceLayer(
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
                layerIdentity: i,
            ),
        );
      }
      else if (layerType == HistoryGridLayer) //GRID LAYER
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

        //grid_type
        final int gridTypeValue = reader.getUint8();
        final GridType gridType = guard.mapped(
          value: GridType.fromId(gridTypeValue),
          raw: gridTypeValue,
          fallback: GridType.rectangular,
          label: "Invalid grid type for layer $i",
        );

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

        layerList.add(HistoryGridLayer(visibilityState: visibilityState, opacity: opacity, gridType: gridType, brightness: brightness, intervalX: intervalX, intervalY: intervalY, horizonPosition: horizon, vanishingPoint1: vanishingPoint1, vanishingPoint2: vanishingPoint2, vanishingPoint3: vanishingPoint3, layerIdentity: i));
      }
      else if (layerType == HistoryShadingLayer || layerType == HistoryDitherLayer) //SHADING/DITHER LAYER
          {
        // LOCK STATE
        final int lockStateVal = reader.getUint8();
        final LayerLockState lockState = guard.mapped(
          value: LayerLockState.fromId(lockStateVal),
          raw: lockStateVal,
          fallback: LayerLockState.unlocked,
          label: "Invalid lock type for layer $i",
        );

        HistoryShadingLayerSettings shadingLayerSettings = HistoryShadingLayerSettings.defaultValue(constraints: shadingLayerSettingsConstraints);
        if (fVersion >= 2)
        {
          final int topLimit = layerType == HistoryDitherLayer ? shadingLayerSettingsConstraints.ditherStepsMax : shadingLayerSettingsConstraints.shadingStepsMax;

          // SHADING LIMIT LOW
          final int shadingStepLimitLow = guard.ranged(
            value: reader.getUint8(),
            min: shadingLayerSettingsConstraints.shadingStepsMin,
            max: topLimit,
            fallback: shadingLayerSettingsConstraints.shadingStepsDefaultDarken,
            label: "Shading step limit low is out of range for layer $i",
          );

          // SHADING LIMIT HIGH
          final int shadingStepLimitHigh = guard.ranged(
            value: reader.getUint8(),
            min: shadingLayerSettingsConstraints.shadingStepsMin,
            max: topLimit,
            fallback: shadingLayerSettingsConstraints.shadingStepsDefaultBrighten,
            label: "Shading step limit high is out of range for layer $i",
          );

          shadingLayerSettings = HistoryShadingLayerSettings(constraints: shadingLayerSettingsConstraints, shadingLow: shadingStepLimitLow, shadingHigh: shadingStepLimitHigh);
        }

        final int dataCount = reader.getUint32();
        final HashMap<CoordinateSetI, int> data = HashMap<CoordinateSetI, int>();
        for (int j = 0; j < dataCount; j++)
        {
          final int x = reader.getUint16();
          final int y = reader.getUint16();
          final int shading = reader.getInt8();
          data[CoordinateSetI(x: x, y: y)] = shading;
        }

        if (layerType == HistoryShadingLayer)
        {
          layerList.add(HistoryShadingLayer.full(visibilityState: visibilityState, lockState: lockState, fullData: data, settings: shadingLayerSettings, layerIdentity: i));
        }
        else if (layerType == HistoryDitherLayer)
        {
          layerList.add(HistoryDitherLayer.full(visibilityState: visibilityState, lockState: lockState, fullData: data, settings: shadingLayerSettings, layerIdentity: i));
        }
      }
    }

    HistoryTimeline hTimeline;
    if (fVersion < 3)
    {
      final LinkedHashSet<int> indices = LinkedHashSet<int>();
      for (int i = 0; i < layerList.length; i++)
      {
        indices.add(i);
      }
      final HistoryFrame hFrame = HistoryFrame(fps: frameConstraints.defaultFps, layerIndices: indices, selectedLayerIndex: 0);
      hTimeline = HistoryTimeline(frames: <HistoryFrame>[hFrame], loopStart: 0, loopEnd: 0, selectedFrameIndex: 0, allLayers: layerList);
    }
    else
    {
      final int framesCount = reader.getUint8();
      final int startFrame = reader.getUint8();
      final int endFrame = reader.getUint8();

      final List<HistoryFrame> hFrames = <HistoryFrame>[];
      for (int i = 0; i < framesCount; i++)
      {
        final LinkedHashSet<int> indices = LinkedHashSet<int>();
        final int fps = reader.getUint8();
        final int layerCount = reader.getUint8();
        for (int j = 0; j < layerCount; j++)
        {
          final int layerIndex = reader.getUint8();
          indices.add(layerIndex);
        }
        hFrames.add(HistoryFrame(fps: fps, layerIndices: indices, selectedLayerIndex: 0));
      }
      hTimeline = HistoryTimeline(frames: hFrames, loopStart: startFrame, loopEnd: endFrame, selectedFrameIndex: 0, allLayers: layerList);
    }

    final HistorySelectionState selectionState = HistorySelectionState(content: HashMap<CoordinateSetI, HistoryColorReference?>());
    final HistoryState historyState = HistoryState(timeline: hTimeline, selectedColor: const HistoryColorReference(colorIndex: 0, rampIndex: 0), selectionState: selectionState, canvasSize: canvasSize, rampList: rampList, type: const HistoryStateType(identifier: HistoryStateTypeIdentifier.loadData, description: "load data", compressionBehavior: HistoryStateCompressionBehavior.leave));

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
