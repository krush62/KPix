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

const Map<int, Type> _historyLayerValueMap =
<int, Type>{
  1: HistoryDrawingLayer,
  2: HistoryReferenceLayer,
  3: HistoryGridLayer,
  4: HistoryShadingLayer,
  5: HistoryDitherLayer,
};

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

//TODO strict parameter could be a (dev) setting
Future<LoadFileSet> loadKPixFile({required Uint8List? fileData, required final KPalConstraints constraints, required final String path, required final KPalSliderConstraints sliderConstraints, required final ReferenceLayerSettings referenceLayerSettings, required final GridLayerSettings gridLayerSettings, required final DrawingLayerSettingsConstraints drawingLayerSettingsConstraints, required final ShadingLayerSettingsConstraints shadingLayerSettingsConstraints, final bool strict = false}) async
{
  final StringBuffer returnString = StringBuffer();
  try
  {
    fileData ??= await File(path).readAsBytes();
    final FileByteReader reader = FileByteReader(fileData);
    final int mNumber = reader.getUint32();
    final int fVersion = reader.getUint8();

    if (mNumber != int.parse(magicNumber, radix: 16)) return LoadFileSet(status: "Wrong magic number: $mNumber");
    if (fVersion > fileVersion) return LoadFileSet(status: "File Version: $fVersion");

    final int rampCount = reader.getUint8();
    if (rampCount < 1) return LoadFileSet(status: "No color ramp found");
    final List<HistoryRampData> rampList = <HistoryRampData>[];
    for (int i = 0; i < rampCount; i++)
    {
      final KPalRampSettings kPalRampSettings = KPalRampSettings(constraints: constraints);

      kPalRampSettings.colorCount = reader.getUint8();
      if (kPalRampSettings.colorCount < constraints.colorCountMin || kPalRampSettings.colorCount > constraints.colorCountMax) return LoadFileSet(status: "Invalid color count in palette $i: ${kPalRampSettings.colorCount}");
      kPalRampSettings.baseHue = reader.getInt16();

      // BASE HUE
      if (kPalRampSettings.baseHue < constraints.baseHueMin || kPalRampSettings.baseHue > constraints.baseHueMax)
      {
        final String msg = "Invalid base hue value in palette $i: ${kPalRampSettings.baseHue}";
        if (strict)
        {
          return LoadFileSet(status: msg);
        }
        else
        {
          kPalRampSettings.baseHue = constraints.baseHueMin;
          returnString.write("\n$msg");
        }
      }

      // BASE SAT
      kPalRampSettings.baseSat = reader.getUint8();
      if (kPalRampSettings.baseSat < constraints.baseSatMin || kPalRampSettings.baseSat > constraints.baseSatMax)
      {
        final String msg = "Invalid base sat value in palette $i: ${kPalRampSettings.baseSat}";
        if (strict)
        {
          return LoadFileSet(status: msg);
        }
        else
        {
          kPalRampSettings.baseSat = constraints.baseSatMin;
          returnString.write("\n$msg");
        }
      }

      // HUE SHIFT
      kPalRampSettings.hueShift = reader.getInt8();
      if (kPalRampSettings.hueShift < constraints.hueShiftMin || kPalRampSettings.hueShift > constraints.hueShiftMax)
      {
        final String msg = "Invalid hue shift value in palette $i: ${kPalRampSettings.hueShift}";
        if (strict)
        {
          return LoadFileSet(status: msg);
        }
        else
        {
          kPalRampSettings.hueShift = constraints.hueShiftMin;
          returnString.write("\n$msg");
        }
      }

      // HUE SHIFT EXP
      kPalRampSettings.hueShiftExp =  reader.getUint8().toDouble() / 100.0;
      if (kPalRampSettings.hueShiftExp < constraints.hueShiftExpMin || kPalRampSettings.hueShiftExp > constraints.hueShiftExpMax)
      {
        final String msg = "Invalid hue shift exp value in palette $i: ${kPalRampSettings.hueShiftExp}";
        if (strict)
        {
          return LoadFileSet(status: msg);
        }
        else
        {
          kPalRampSettings.hueShiftExp = constraints.hueShiftExpMin;
          returnString.write("\n$msg");

        }
      }

      // SAT SHIFT
      kPalRampSettings.satShift = reader.getInt8();
      if (kPalRampSettings.satShift < constraints.satShiftMin || kPalRampSettings.satShift > constraints.satShiftMax)
      {
        final String msg = "Invalid sat shift value in palette $i: ${kPalRampSettings.satShift}";
        if (strict)
        {
          return LoadFileSet(status: msg);
        }
        else
        {
          kPalRampSettings.satShift = constraints.satShiftMin;
          returnString.write("\n$msg");
        }
      }

      // SAT SHIFT EXP
      kPalRampSettings.satShiftExp =  reader.getUint8().toDouble() / 100.0;
      if (kPalRampSettings.satShiftExp < constraints.satShiftExpMin || kPalRampSettings.satShiftExp > constraints.satShiftExpMax)
      {
        final String msg = "Invalid sat shift exp value in palette $i: ${kPalRampSettings.satShiftExp}";
        if (strict)
        {
          return LoadFileSet(status: msg);
        }
        else
        {
          kPalRampSettings.satShiftExp = constraints.satShiftExpMin;
          returnString.write("\n$msg");
        }
      }

      // CURVE
      final int curveVal = reader.getUint8();
      final SatCurve? satCurve = satCurveMap[curveVal];
      if (satCurve == null)
      {
        final String msg = "Invalid sat curve for palette $i: $curveVal";
        if (strict)
        {
          return LoadFileSet(status: msg);
        }
        else
        {
          kPalRampSettings.satCurve = SatCurve.noFlat;
          returnString.write("\n$msg");
        }
      }
      else
      {
        kPalRampSettings.satCurve = satCurve;
      }

      kPalRampSettings.valueRangeMin = reader.getUint8();

      // VALUE RANGE
      kPalRampSettings.valueRangeMax = reader.getUint8();
      if (kPalRampSettings.valueRangeMin < constraints.valueRangeMin || kPalRampSettings.valueRangeMax > constraints.valueRangeMax || kPalRampSettings.valueRangeMax < kPalRampSettings.valueRangeMin)
      {
        final String msg = "Invalid value range in palette $i: ${kPalRampSettings.valueRangeMin}-${kPalRampSettings.valueRangeMax}";
        if (strict)
        {
          return LoadFileSet(status: msg);
        }
        else
        {
          kPalRampSettings.valueRangeMin = constraints.valueRangeMin;
          kPalRampSettings.valueRangeMax = constraints.valueRangeMax;
          returnString.write("\n$msg");
        }
      }

      //COLOR SHIFTS
      final List<ShiftSet> shifts = <ShiftSet>[];
      for (int j = 0; j < kPalRampSettings.colorCount; j++)
      {
        //COLOR SHIFT HUE
        int hueShift = reader.getInt8();
        if (hueShift > sliderConstraints.maxHue || hueShift < sliderConstraints.minHue)
        {
          final String msg = "Invalid Hue Shift in Ramp $i, color $j: $hueShift";
          if (strict)
          {
            return LoadFileSet(status: msg);
          }
          else
          {
            hueShift = 0;
            returnString.write("\n$msg");
          }
        }

        //COLOR SHIFT SAT
        int satShift = reader.getInt8();
        if (satShift > sliderConstraints.maxSat || satShift < sliderConstraints.minSat)
        {
          final String msg = "Invalid Sat Shift in Ramp $i, color $j: $satShift";
          if (strict)
          {
            return LoadFileSet(status: msg);
          }
          else
          {
            satShift = 0;
            returnString.write("\n$msg");
          }
        }

        // COLOR SHIFT VAL
        int valShift = reader.getInt8();
        if (valShift > sliderConstraints.maxVal || valShift < sliderConstraints.minVal) {
          final String msg = "Invalid Val Shift in Ramp $i, color $j: $valShift";
          if (strict)
          {
            return LoadFileSet(status: msg);
          }
          else
          {
            valShift = 0;
            returnString.write("\n$msg");
          }
        }

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
      final int layerType = reader.getUint8();
      if (!_historyLayerValueMap.keys.contains(layerType))
      {
        final String msg = "Invalid layer type for layer $i: $layerType";
        if (strict)
        {
          return LoadFileSet(status: msg);
        }
        else
        {
          returnString.write("\n$msg");
          continue;
        }
      }

      // VISIBILITY STATE
      final int visibilityStateVal = reader.getUint8();
      LayerVisibilityState? visibilityState = layerVisibilityStateValueMap[visibilityStateVal];
      if (visibilityState == null)
      {
        final String msg = "Invalid visibility type for layer $i: $visibilityStateVal";
        if (strict)
        {
          return LoadFileSet(status: msg);
        }
        else
        {
          visibilityState = LayerVisibilityState.visible;
          returnString.write("\nmsg");
        }
      }


      if (_historyLayerValueMap[layerType] == HistoryDrawingLayer) //DRAWING LAYER
      {
        HistoryDrawingLayerSettings drawingLayerSettings = HistoryDrawingLayerSettings.defaultValues(constraints: drawingLayerSettingsConstraints, colRef: const HistoryColorReference(colorIndex: 0, rampIndex: 0));

        // LOCK STATE
        final int lockStateVal = reader.getUint8();
        LayerLockState? lockState = layerLockStateValueMap[lockStateVal];
        if (lockState == null)
        {
          final String msg = "Invalid lock type for layer $i: $lockStateVal";
          if (strict)
          {
            return LoadFileSet(status: msg);
          }
          else
          {
            lockState = LayerLockState.unlocked;
            returnString.write("\n$msg");
          }
        }

        if (fVersion >= 2)
        {
          // OUTER STROKE STYLE
          final int outerStrokeStyleVal = reader.getUint8();
          OuterStrokeStyle? outerStrokeStyle = outerStrokeStyleValueMap[outerStrokeStyleVal];
          if (outerStrokeStyle == null)
          {
            final String msg = "Invalid outer stroke style for layer $i: $outerStrokeStyleVal";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              outerStrokeStyle = OuterStrokeStyle.off;
              returnString.write("\n$msg");
            }
          }

          // OUTER STROKE ALIGNMENT
          final int outerAlignmentMask = reader.getUint8();
          final HashMap<Alignment, bool> outerStrokeDirections = _unPackAlignments(byte: outerAlignmentMask);

          // OUTER STROKE COLOR RAMP INDEX
          int outerStrokeColorRampIndex = reader.getUint8();
          if (outerStrokeColorRampIndex >= rampList.length)
          {
            final String msg = "Outer Stroke Color Ramp index out of range for layer $i : $outerStrokeColorRampIndex";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              outerStrokeColorRampIndex = 0;
              returnString.write("\n$msg");
            }
          }

          // OUTER STROKE COLOR INDEX
          int outerStrokeColorIndex = reader.getUint8();
          if (outerStrokeColorIndex >= rampList[outerStrokeColorRampIndex].settings.colorCount)
          {
            final String msg = "Outer Stroke Color index out of range for layer $i: $outerStrokeColorIndex";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              outerStrokeColorIndex = 0;
              returnString.write("\n$msg");
            }
          }

          final HistoryColorReference outerColorReference = HistoryColorReference(colorIndex: outerStrokeColorIndex, rampIndex: outerStrokeColorRampIndex);

          // OUTER STROKE DARKEN/BRIGHTEN
          int outerStrokeDarkenBrighten = reader.getInt8();
          if (outerStrokeDarkenBrighten < drawingLayerSettingsConstraints.darkenBrightenMin || outerStrokeDarkenBrighten > drawingLayerSettingsConstraints.darkenBrightenMax)
          {
            final String msg = "Darken/Brighten for outer stroke is out of range for layer $i: $outerStrokeDarkenBrighten";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              outerStrokeDarkenBrighten = drawingLayerSettingsConstraints.darkenBrightenDefault;
              returnString.write("\n$msg");
            }
          }

          // OUTER STROKE GLOW DEPTH
          int outerStrokeGlowDepth = reader.getInt8();
          if (outerStrokeGlowDepth < drawingLayerSettingsConstraints.glowDepthMin || outerStrokeGlowDepth > drawingLayerSettingsConstraints.glowDepthMax)
          {
            final String msg = "Glow Depth for outer stroke is out of range for layer $i: $outerStrokeGlowDepth";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              outerStrokeGlowDepth = drawingLayerSettingsConstraints.glowDepthDefault;
              returnString.write("\n$msg");
            }
          }

          // OUTER STROKE GLOW RECURSIVE
          int outerStrokeGlowRecursiveValue = reader.getUint8();
          if (outerStrokeGlowRecursiveValue != 0 && outerStrokeGlowRecursiveValue != 1)
          {
            final String msg = "Invalid glow recursive value for outer stroke for layer $i: $outerStrokeGlowRecursiveValue";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              outerStrokeGlowRecursiveValue = 0;
              returnString.write("\n$msg");
            }
          }
          final bool outerStrokeGlowRecursive = outerStrokeGlowRecursiveValue != 0;


          //INNER STROKE STYLE
          final int innerStrokeStyleVal = reader.getUint8();
          InnerStrokeStyle? innerStrokeStyle = innerStrokeStyleValueMap[innerStrokeStyleVal];
          if (innerStrokeStyle == null)
          {
            final String msg = "Invalid inner stroke style for layer $i: $outerStrokeStyleVal";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              innerStrokeStyle = InnerStrokeStyle.off;
              returnString.write("\n$msg");
            }
          }

          // INNER STROKE ALIGNMENT
          final int innerAlignmentMask = reader.getUint8();
          final HashMap<Alignment, bool> innerStrokeDirections = _unPackAlignments(byte: innerAlignmentMask);

          // INNER STROKE COLOR RAMP INDEX
          int innerStrokeColorRampIndex = reader.getUint8();
          if (innerStrokeColorRampIndex >= rampList.length)
          {
            final String msg = "Inner Stroke Color Ramp index out of range for layer $i : $innerStrokeColorRampIndex";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              innerStrokeColorRampIndex = 0;
              returnString.write("\n$msg");

            }
          }

          // INNER STROKE COLOR INDEX
          int innerStrokeColorIndex = reader.getUint8();
          if (innerStrokeColorIndex >= rampList[innerStrokeColorRampIndex].settings.colorCount)
          {
            final String msg = "Inner Stroke Color index out of range for layer $i: $innerStrokeColorIndex";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              innerStrokeColorIndex = 0;
              returnString.write("\n$msg");
            }
          }

          final HistoryColorReference innerColorReference = HistoryColorReference(colorIndex: innerStrokeColorIndex, rampIndex: innerStrokeColorRampIndex);

          // INNER STROKE DARKEN/BRIGHTEN
          int innerStrokeDarkenBrighten = reader.getInt8();
          if (innerStrokeDarkenBrighten < drawingLayerSettingsConstraints.darkenBrightenMin || innerStrokeDarkenBrighten > drawingLayerSettingsConstraints.darkenBrightenMax)
          {
            final String msg = "Darken/Brighten for inner stroke is out of range for layer $i: $innerStrokeDarkenBrighten";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              innerStrokeDarkenBrighten = drawingLayerSettingsConstraints.darkenBrightenDefault;
              returnString.write("\n$msg");
            }
          }

          // INNER STROKE GLOW DEPTH
          int innerStrokeGlowDepth = reader.getInt8();
          if (innerStrokeGlowDepth < drawingLayerSettingsConstraints.glowDepthMin || innerStrokeGlowDepth > drawingLayerSettingsConstraints.glowDepthMax)
          {
            final String msg = "Glow Depth for inner stroke is out of range for layer $i: $innerStrokeGlowDepth";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              innerStrokeGlowDepth = drawingLayerSettingsConstraints.glowDepthDefault;
              returnString.write("\n$msg");
            }
          }

          // INNER STROKE GLOW RECURSIVE
          int innerStrokeGlowRecursiveValue = reader.getUint8();
          if (innerStrokeGlowRecursiveValue != 0 && innerStrokeGlowRecursiveValue != 1)
          {
            final String msg = "Invalid glow recursive value for inner stroke for layer $i: $innerStrokeGlowRecursiveValue";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              innerStrokeGlowRecursiveValue = 0;
              returnString.write("\n$msg");
            }
          }

          final bool innerStrokeGlowRecursive = innerStrokeGlowRecursiveValue != 0;

          // INNER STROKE BEVEL DISTANCE
          int innerStrokeBevelDistance = reader.getUint8();
          if (innerStrokeBevelDistance < drawingLayerSettingsConstraints.bevelDistanceMin || innerStrokeBevelDistance > drawingLayerSettingsConstraints.bevelDistanceMax)
          {
            final String msg = "Bevel Distance out of range for layer $i: $innerStrokeBevelDistance";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              innerStrokeBevelDistance = drawingLayerSettingsConstraints.bevelDistanceDefault;
              returnString.write("\n$msg");
            }
          }

          // INNER STROKE BEVEL STRENGTH
          int innerStrokeBevelStrength = reader.getUint8();
          if (innerStrokeBevelStrength < drawingLayerSettingsConstraints.bevelStrengthMin || innerStrokeBevelStrength > drawingLayerSettingsConstraints.bevelStrengthMax)
          {
            final String msg = "Bevel Strength out of range for layer $i: $innerStrokeBevelStrength";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              innerStrokeBevelStrength = drawingLayerSettingsConstraints.bevelStrengthDefault;
              returnString.write("\n$msg");
            }
          }


          // DROP SHADOW STYLE
          final int dropShadowStyleVal = reader.getUint8();
          DropShadowStyle? dropShadowStyle = dropShadowStyleValueMap[dropShadowStyleVal];
          if (dropShadowStyle == null)
          {
            final String msg = "Invalid drop shadow style for layer $i: $dropShadowStyleVal";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              dropShadowStyle = DropShadowStyle.off;
              returnString.write("\n$msg");
            }
          }

          // DROP SHADOW COLOR RAMP INDEX
          int dropShadowColorRampIndex = reader.getUint8();
          if (dropShadowColorRampIndex >= rampList.length)
          {
            final String msg = "Drop Shadow Color Ramp index out of range for layer $i : $dropShadowColorRampIndex";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              dropShadowColorRampIndex = 0;
              returnString.write("\n$msg");

            }
          }

          // DROP SHADOW COLOR INDEX
          int dropShadowColorIndex = reader.getUint8();
          if (dropShadowColorIndex >= rampList[dropShadowColorRampIndex].settings.colorCount)
          {
            final String msg = "Drop Shadow Color index out of range for layer $i: $dropShadowColorIndex";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              dropShadowColorIndex = 0;
              returnString.write("\n$msg");
            }
          }

          final HistoryColorReference dropShadowColorReference = HistoryColorReference(colorIndex: dropShadowColorIndex, rampIndex: dropShadowColorRampIndex);


          // DROP SHADOW OFFSET X
          int dropShadowOffsetX = reader.getInt8();
          if (dropShadowOffsetX < drawingLayerSettingsConstraints.dropShadowOffsetMin || dropShadowOffsetX > drawingLayerSettingsConstraints.dropShadowOffsetMax)
          {
            final String msg = "Drop Shadow offset x is out of range for layer $i: $dropShadowOffsetX";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              dropShadowOffsetX = drawingLayerSettingsConstraints.dropShadowOffsetDefault;
              returnString.write("\n$msg");
            }
          }

          // DROP SHADOW OFFSET Y
          int dropShadowOffsetY = reader.getInt8();
          if (dropShadowOffsetY < drawingLayerSettingsConstraints.dropShadowOffsetMin || dropShadowOffsetY > drawingLayerSettingsConstraints.dropShadowOffsetMax)
          {
            final String msg = "Drop Shadow offset y is out of range for layer $i: $dropShadowOffsetY";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              dropShadowOffsetY = drawingLayerSettingsConstraints.dropShadowOffsetDefault;
              returnString.write("\n$msg");
            }
          }

          // DROP SHADOW DARKEN/BRIGHTEN
          int dropShadowDarkenBrighten = reader.getInt8();
          if (dropShadowDarkenBrighten < drawingLayerSettingsConstraints.darkenBrightenMin || dropShadowDarkenBrighten > drawingLayerSettingsConstraints.darkenBrightenMax)
          {
            final String msg = "Darken/Brighten for drop shadow is out of range for layer $i: $dropShadowDarkenBrighten";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              dropShadowDarkenBrighten = drawingLayerSettingsConstraints.darkenBrightenDefault;
              returnString.write("\n$msg");
            }
          }

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
      else if (_historyLayerValueMap[layerType] == HistoryReferenceLayer) //REFERENCE LAYER
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
        int opacity = reader.getUint8();
        if (opacity < referenceLayerSettings.opacityMin || opacity > referenceLayerSettings.opacityMax)
        {
          final String msg = "Opacity for reference layer is out of range: $opacity";
          if (strict)
          {
            return LoadFileSet(status: msg);
          }
          else
          {
            opacity = referenceLayerSettings.opacityDefault;
            returnString.write("\n$msg");
          }
        }

        //offset_x ``float (1)``
        final double offsetX = reader.getFloat32();
        //offset_y ``float (1)``
        final double offsetY = reader.getFloat32();

        //zoom ``ushort (1)``
        int zoom = reader.getUint16();
        if (zoom < referenceLayerSettings.zoomMin || opacity > referenceLayerSettings.zoomMax)
        {
          final String msg = "Zoom for reference layer is out of range: $zoom";
          if (strict) {
            return LoadFileSet(status: msg);
          }
          else
          {
            zoom = referenceLayerSettings.zoomDefault;
            returnString.write("\n$msg");
          }
        }

        //aspect_ratio ``float (1)``
        double aspectRatio = reader.getFloat32();
        if (aspectRatio < (referenceLayerSettings.aspectRatioMin - _floatDelta) || aspectRatio > (referenceLayerSettings.aspectRatioMax + _floatDelta))
        {
          final String msg = "Aspect ratio for reference layer is out of range: $aspectRatio";
          if (strict) {
            return LoadFileSet(status: msg);
          }
          else
          {
            aspectRatio = referenceLayerSettings.aspectRatioDefault;
            returnString.write("\n$msg");
          }
        }

        aspectRatio = aspectRatio.clamp(referenceLayerSettings.aspectRatioMin, referenceLayerSettings.aspectRatioMax);


        double brightness = referenceLayerSettings.brightnessDefault;
        double contrast = referenceLayerSettings.contrastDefault;
        double saturation = referenceLayerSettings.saturationDefault;
        double warmth = referenceLayerSettings.warmthDefault;

        if (fVersion >= 4)
        {
          //brightness ``float (1)`` // -1...1
          brightness = reader.getFloat32();
          if (brightness < referenceLayerSettings.brightnessMin || brightness > referenceLayerSettings.brightnessMax)
          {
            final String msg = "Brightness for reference layer is out of range: $brightness";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              brightness = referenceLayerSettings.brightnessDefault;
              returnString.write("\n$msg");
            }
          }

          //contrast ``float (1)`` // 0...2
          contrast = reader.getFloat32();
          if (contrast < referenceLayerSettings.contrastMin || contrast > referenceLayerSettings.contrastMax)
          {
            final String msg = "Contrast for reference layer is out of range: $contrast";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              contrast = referenceLayerSettings.contrastDefault;
              returnString.write("\n$msg");
            }
          }

          //saturation ``float (1)`` // 0...2
          saturation = reader.getFloat32();
          if (saturation < referenceLayerSettings.saturationMin || saturation > referenceLayerSettings.saturationMax)
          {
            final String msg = "Saturation for reference layer is out of range: $saturation";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              saturation = referenceLayerSettings.saturationDefault;
              returnString.write("\n$msg");
            }
          }

          //warmth ``float (1)`` // -1...1
          warmth = reader.getFloat32();
          if (warmth < referenceLayerSettings.warmthMin || warmth > referenceLayerSettings.warmthMax)
          {
            final String msg = "Warmth for reference layer is out of range: $warmth";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              warmth = referenceLayerSettings.warmthDefault;
              returnString.write("\n$msg");
            }
          }
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
      else if (_historyLayerValueMap[layerType] == HistoryGridLayer) //GRID LAYER
          {
        //opacity ``ubyte (1)`` // 0...100
        int opacity = reader.getUint8();
        if (opacity < gridLayerSettings.opacityMin || opacity > gridLayerSettings.opacityMax)
        {
          final String msg = "Opacity for grid layer is out of range: $opacity";
          if (strict)
          {
            return LoadFileSet(status: msg);
          }
          else
          {
            opacity = gridLayerSettings.opacityDefault;
            returnString.write("\n$msg");
          }
        }

        //brightness ``ubyte (1)`` // 0...100
        int brightness = reader.getUint8();
        if (brightness < gridLayerSettings.brightnessMin || brightness > gridLayerSettings.brightnessMax)
        {
          final String msg = "Brightness for grid layer is out of range: $brightness";
          if (strict)
          {
            return LoadFileSet(status: msg);
          }
          else
          {
            brightness = gridLayerSettings.brightnessDefault;
            returnString.write("\n$msg");
          }

        }

        //grid_type
        final int gridTypeValue = reader.getUint8();
        GridType? gridType = gridValueTypeMap[gridTypeValue];
        if (gridType == null)
        {
          final String msg = "Invalid grid type for layer $i: $gridTypeValue";
          if (strict)
          {
            return LoadFileSet(status: msg);
          }
          else
          {
            gridType = GridType.rectangular;
            returnString.write("\n$msg");
          }
        }

        //interval_x ``ubyte (1)`` // 2...64
        int intervalX = reader.getUint8();
        if (intervalX < gridLayerSettings.intervalXMin || intervalX > gridLayerSettings.intervalXMax)
        {
          final String msg = "Interval X for grid layer is out of range: $intervalX";
          if (strict)
          {
            return LoadFileSet(status: msg);
          }
          else
          {
            intervalX = gridLayerSettings.intervalXDefault;
            returnString.write("\n$msg");
          }
        }

        //interval_y ``ubyte (1)`` // 2...64
        int intervalY = reader.getUint8();
        if (intervalY < gridLayerSettings.intervalYMin || intervalY > gridLayerSettings.intervalYMax)
        {
          final String msg = "Interval Y for grid layer is out of range: $intervalY";
          if (strict)
          {
            return LoadFileSet(status: msg);
          }
          else
          {
            intervalY = gridLayerSettings.intervalYDefault;
            returnString.write("\n$msg");
          }

        }

        //horizon_position ``float (1)``// 0...1 (vertical horizon position)
        double horizon = reader.getFloat32();
        if (horizon < (gridLayerSettings.vanishingPointMin - _floatDelta) || horizon > (gridLayerSettings.vanishingPointMax + _floatDelta))
        {
          final String msg = "Horizon for grid layer is out of range: $horizon";
          if (strict)
          {
            return LoadFileSet(status: msg);
          }
          else
          {
            horizon = gridLayerSettings.horizonDefault;
            returnString.write("\n$msg");
          }
        }
        horizon = horizon.clamp(gridLayerSettings.vanishingPointMin, gridLayerSettings.vanishingPointMax);

        //vanishing_point_1 ``float (1)``// 0...1 (horizontal position of first vanishing point)
        double vanishingPoint1 = reader.getFloat32();
        if (vanishingPoint1 < (gridLayerSettings.vanishingPointMin - _floatDelta) || vanishingPoint1 > (gridLayerSettings.vanishingPointMax + _floatDelta))
        {
          final String msg = "Vanishing Point 1 for grid layer is out of range: $vanishingPoint1";
          if (strict)
          {
            return LoadFileSet(status: msg);
          }
          else
          {
            vanishingPoint1 = gridLayerSettings.vanishingPoint1Default;
            returnString.write("\n$msg");
          }
        }
        vanishingPoint1 = vanishingPoint1.clamp(gridLayerSettings.vanishingPointMin, gridLayerSettings.vanishingPointMax);

        //vanishing_point_2 ``float (1)``// 0...1 (horizontal position of second vanishing point)
        double vanishingPoint2 = reader.getFloat32();
        if (vanishingPoint2 < (gridLayerSettings.vanishingPointMin - _floatDelta) || vanishingPoint2 > (gridLayerSettings.vanishingPointMax + _floatDelta))
        {
          final String msg = "Vanishing Point 2 for grid layer is out of range: $vanishingPoint2";
          if (strict)
          {
            return LoadFileSet(status: msg);
          }
          else
          {
            vanishingPoint2 = gridLayerSettings.vanishingPoint1Default;
            returnString.write("\n$msg");
          }
        }
        vanishingPoint2 = vanishingPoint2.clamp(gridLayerSettings.vanishingPointMin, gridLayerSettings.vanishingPointMax);

        //vanishing_point_3 ``float (1)``// 0...1 (vertical position of third vanishing point)
        double vanishingPoint3 = reader.getFloat32();
        if (vanishingPoint3 < (gridLayerSettings.vanishingPointMin - _floatDelta) || vanishingPoint3 > (gridLayerSettings.vanishingPointMax + _floatDelta))
        {
          final String msg = "Vanishing Point 3 for grid layer is out of range: $vanishingPoint3";
          if (strict)
          {
            return LoadFileSet(status: msg);
          }
          else
          {
            vanishingPoint3 = gridLayerSettings.vanishingPoint1Default;
            returnString.write("\n$msg");
          }
        }
        vanishingPoint3 = vanishingPoint3.clamp(gridLayerSettings.vanishingPointMin, gridLayerSettings.vanishingPointMax);

        layerList.add(HistoryGridLayer(visibilityState: visibilityState, opacity: opacity, gridType: gridType, brightness: brightness, intervalX: intervalX, intervalY: intervalY, horizonPosition: horizon, vanishingPoint1: vanishingPoint1, vanishingPoint2: vanishingPoint2, vanishingPoint3: vanishingPoint3, layerIdentity: i));
      }
      else if (_historyLayerValueMap[layerType] == HistoryShadingLayer || _historyLayerValueMap[layerType] == HistoryDitherLayer) //SHADING/DITHER LAYER
          {
        // LOCK STATE
        final int lockStateVal = reader.getUint8();
        LayerLockState? lockState = layerLockStateValueMap[lockStateVal];
        if (lockState == null)
        {
          final String msg = "Invalid lock type for layer $i: $lockStateVal";
          if (strict)
          {
            return LoadFileSet(status: msg);
          }
          else
          {
            lockState = LayerLockState.unlocked;
            returnString.write("\n$msg");
          }
        }

        HistoryShadingLayerSettings shadingLayerSettings = HistoryShadingLayerSettings.defaultValue(constraints: shadingLayerSettingsConstraints);
        if (fVersion >= 2)
        {
          final int topLimit = _historyLayerValueMap[layerType] == HistoryDitherLayer ? shadingLayerSettingsConstraints.ditherStepsMax : shadingLayerSettingsConstraints.shadingStepsMax;

          // SHADING LIMIT LOW
          int shadingStepLimitLow = reader.getUint8();
          if (shadingStepLimitLow < shadingLayerSettingsConstraints.shadingStepsMin || shadingStepLimitLow > topLimit)
          {
            final String msg = "Shading step limit low is out of range for layer $i: $shadingStepLimitLow";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              shadingStepLimitLow = shadingLayerSettingsConstraints.shadingStepsDefaultDarken;
              returnString.write("\n$msg");
            }
          }

          // SHADING LIMIT HIGH
          int shadingStepLimitHigh = reader.getUint8();
          if (shadingStepLimitHigh < shadingLayerSettingsConstraints.shadingStepsMin || shadingStepLimitHigh > topLimit)
          {
            final String msg = "Shading step limit high is out of range for layer $i: $shadingStepLimitHigh";
            if (strict)
            {
              return LoadFileSet(status: msg);
            }
            else
            {
              shadingStepLimitHigh = shadingLayerSettingsConstraints.shadingStepsDefaultBrighten;
              returnString.write("\n$msg");
            }
          }

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

        if (_historyLayerValueMap[layerType] == HistoryShadingLayer)
        {
          layerList.add(HistoryShadingLayer.full(visibilityState: visibilityState, lockState: lockState, fullData: data, settings: shadingLayerSettings, layerIdentity: i));
        }
        else if (_historyLayerValueMap[layerType] == HistoryDitherLayer)
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
      final FrameConstraints constraints = GetIt.I.get<PreferenceManager>().frameConstraints;
      final HistoryFrame hFrame = HistoryFrame(fps: constraints.defaultFps, layerIndices: indices, selectedLayerIndex: 0);
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
  catch (pnfe)
  {
    return LoadFileSet(status: "Could not load file $path");
  }
}
