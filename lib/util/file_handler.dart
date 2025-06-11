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
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_settings.dart';
import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/managers/history/history_drawing_layer.dart';
import 'package:kpix/managers/history/history_drawing_layer_settings.dart';
import 'package:kpix/managers/history/history_grid_layer.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';
import 'package:kpix/managers/history/history_reference_layer.dart';
import 'package:kpix/managers/history/history_selection_state.dart';
import 'package:kpix/managers/history/history_shading_layer.dart';
import 'package:kpix/managers/history/history_shading_layer_settings.dart';
import 'package:kpix/managers/history/history_shift_set.dart';
import 'package:kpix/managers/history/history_state.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/color_names.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/controls/kpix_direction_widget.dart';
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:kpix/widgets/file/project_manager_entry_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/palette/palette_manager_entry_widget.dart';
import 'package:kpix/widgets/stamps/stamp_manager_entry_widget.dart';
import 'package:kpix/widgets/tools/grid_layer_options_widget.dart';
import 'package:kpix/widgets/tools/reference_layer_options_widget.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class LoadFileSet
{
  final String status;
  final HistoryState? historyState;
  final String? path;
  LoadFileSet({required this.status, this.historyState, this.path});
}

class LoadProjectFileSet
{
  final String path;
  final DateTime lastModifiedDate;
  final ui.Image? thumbnail;
  LoadProjectFileSet({required this.path, required this.lastModifiedDate, required this.thumbnail});
}


enum PaletteReplaceBehavior
{
  remap,
  replace
}

class LoadPaletteSet
{
  final String status;
  final List<KPalRampData>? rampData;
  LoadPaletteSet({required this.status, this.rampData});
}


const Map<SatCurve, int> kpixKpalSatCurveMap =
<SatCurve, int>{
  SatCurve.noFlat:1,
  SatCurve.darkFlat:0,
  SatCurve.brightFlat:3,
  SatCurve.linear:2,
};

const Map<int, SatCurve> _kpalKpixSatCurveMap =
<int, SatCurve>{
  1:SatCurve.noFlat,
  0:SatCurve.darkFlat,
  3:SatCurve.brightFlat,
  2: SatCurve.linear,
};

const Map<int, Type> historyLayerValueMap =
<int, Type>{
  1: HistoryDrawingLayer,
  2: HistoryReferenceLayer,
  3: HistoryGridLayer,
  4: HistoryShadingLayer,
};

enum FileNameStatus
{
  available,
  forbidden,
  noRights,
  overwrite
}

const Map<FileNameStatus, String> fileNameStatusTextMap =
<FileNameStatus, String>{
  FileNameStatus.available:"Available",
  FileNameStatus.forbidden:"Invalid File Name",
  FileNameStatus.noRights:"Insufficient Permissions",
  FileNameStatus.overwrite:"Overwriting Existing File",
};

const Map<FileNameStatus, IconData> fileNameStatusIconMap =
<FileNameStatus, IconData>{
  FileNameStatus.available:FontAwesomeIcons.check,
  FileNameStatus.forbidden:FontAwesomeIcons.xmark,
  FileNameStatus.noRights:FontAwesomeIcons.ban,
  FileNameStatus.overwrite:FontAwesomeIcons.exclamation,
};


  const int fileVersion = 2;
  const String magicNumber = "4B504958";
  const String fileExtensionKpix = "kpix";
  const String fileExtensionKpal = "kpal";
  const String palettesSubDirName = "palettes";
  const String stampsSubDirName = "stamps";
  const String projectsSubDirName = "projects";
  const String recoverSubDirName = "recover";
  const String thumbnailExtension = "png";
  const List<String> imageExtensions = <String>["png", "jpg", "jpeg", "gif"];
  const String recoverFileName = "___recover___";
  const double _floatDelta = 0.01;


  Future<String> saveKPixFile({required final String path, required final AppState appState}) async
  {
    final ByteData byteData = await createKPixData(appState: appState);
    if (!kIsWeb)
    {
      await File(path).writeAsBytes(byteData.buffer.asUint8List());
      return path;
    }
    else
    {
      final String newPath = await FileSaver.instance.saveFile(
        name: path,
        bytes: byteData.buffer.asUint8List(),
        ext: fileExtensionKpix,
      );
      return newPath;
    }
  }

//TODO strict parameter could be a (dev) setting
  Future<LoadFileSet> loadKPixFile({required Uint8List? fileData, required final KPalConstraints constraints, required final String path, required final KPalSliderConstraints sliderConstraints, required final ReferenceLayerSettings referenceLayerSettings, required final GridLayerSettings gridLayerSettings, required final DrawingLayerSettingsConstraints drawingLayerSettingsConstraints, required final ShadingLayerSettingsConstraints shadingLayerSettingsConstraints, final bool strict = false}) async
  {
    final StringBuffer returnString = StringBuffer();
    try
    {
      fileData ??= await File(path).readAsBytes();
      final ByteData byteData = fileData.buffer.asByteData();
      int offset = 0;
      final int mNumber = byteData.getUint32(offset);
      offset+=4;
      final int fVersion = byteData.getUint8(offset++);

      if (mNumber != int.parse(magicNumber, radix: 16)) return LoadFileSet(status: "Wrong magic number: $mNumber");
      if (fVersion > fileVersion) return LoadFileSet(status: "File Version: $fVersion");

      final int rampCount = byteData.getUint8(offset++);
      if (rampCount < 1) return LoadFileSet(status: "No color ramp found");
      final List<HistoryRampData> rampList = <HistoryRampData>[];
      for (int i = 0; i < rampCount; i++)
      {
        final KPalRampSettings kPalRampSettings = KPalRampSettings(constraints: constraints);

        kPalRampSettings.colorCount = byteData.getUint8(offset++);
        if (kPalRampSettings.colorCount < constraints.colorCountMin || kPalRampSettings.colorCount > constraints.colorCountMax) return LoadFileSet(status: "Invalid color count in palette $i: ${kPalRampSettings.colorCount}");
        kPalRampSettings.baseHue = byteData.getInt16(offset);
        offset+=2;

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
        kPalRampSettings.baseSat = byteData.getUint8(offset++);
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
        kPalRampSettings.hueShift = byteData.getInt8(offset++);
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
        kPalRampSettings.hueShiftExp =  byteData.getUint8(offset++).toDouble() / 100.0;
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
        kPalRampSettings.satShift = byteData.getInt8(offset++);
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
        kPalRampSettings.satShiftExp =  byteData.getUint8(offset++).toDouble() / 100.0;
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
        final int curveVal = byteData.getUint8(offset++);
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

        kPalRampSettings.valueRangeMin = byteData.getUint8(offset++);



        // VALUE RANGE
        kPalRampSettings.valueRangeMax = byteData.getUint8(offset++);
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
          int hueShift = byteData.getInt8(offset++);
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
          int satShift = byteData.getInt8(offset++);
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
          int valShift = byteData.getInt8(offset++);
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

      final int width = byteData.getUint16(offset);
      offset+=2;
      final int height = byteData.getUint16(offset);
      offset+=2;
      final CoordinateSetI canvasSize = CoordinateSetI(x: width, y: height);
      final int layerCount = byteData.getUint8(offset++);
      if (layerCount < 1) return LoadFileSet(status: "No layer found");
      final List<HistoryLayer> layerList = <HistoryLayer>[];
      for (int i = 0; i < layerCount; i++)
      {
        // LAYER TYPE
        final int layerType = byteData.getUint8(offset++);
        if (!historyLayerValueMap.keys.contains(layerType))
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
        final int visibilityStateVal = byteData.getUint8(offset++);
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


        if (historyLayerValueMap[layerType] == HistoryDrawingLayer) //DRAWING LAYER
        {
          HistoryDrawingLayerSettings drawingLayerSettings = HistoryDrawingLayerSettings.defaultValues(constraints: drawingLayerSettingsConstraints, colRef: HistoryColorReference(colorIndex: 0, rampIndex: 0));

          // LOCK STATE
          final int lockStateVal = byteData.getUint8(offset++);
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
            final int outerStrokeStyleVal = byteData.getUint8(offset++);
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
            final int outerAlignmentMask = byteData.getUint8(offset++);
            final HashMap<Alignment, bool> outerStrokeDirections = _unPackAlignments(byte: outerAlignmentMask);

            // OUTER STROKE COLOR RAMP INDEX
            int outerStrokeColorRampIndex = byteData.getUint8(offset++);
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
            int outerStrokeColorIndex = byteData.getUint8(offset++);
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
            int outerStrokeDarkenBrighten = byteData.getInt8(offset++);
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
            int outerStrokeGlowDepth = byteData.getInt8(offset++);
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
            int outerStrokeGlowRecursiveValue = byteData.getUint8(offset++);
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
            final int innerStrokeStyleVal = byteData.getUint8(offset++);
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
            final int innerAlignmentMask = byteData.getUint8(offset++);
            final HashMap<Alignment, bool> innerStrokeDirections = _unPackAlignments(byte: innerAlignmentMask);

            // INNER STROKE COLOR RAMP INDEX
            int innerStrokeColorRampIndex = byteData.getUint8(offset++);
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
            int innerStrokeColorIndex = byteData.getUint8(offset++);
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
            int innerStrokeDarkenBrighten = byteData.getInt8(offset++);
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
            int innerStrokeGlowDepth = byteData.getInt8(offset++);
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
            int innerStrokeGlowRecursiveValue = byteData.getUint8(offset++);
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
            int innerStrokeBevelDistance = byteData.getUint8(offset++);
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
            int innerStrokeBevelStrength = byteData.getUint8(offset++);
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
            final int dropShadowStyleVal = byteData.getUint8(offset++);
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
            int dropShadowColorRampIndex = byteData.getUint8(offset++);
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
            int dropShadowColorIndex = byteData.getUint8(offset++);
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
            int dropShadowOffsetX = byteData.getInt8(offset++);
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
            int dropShadowOffsetY = byteData.getInt8(offset++);
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
            int dropShadowDarkenBrighten = byteData.getInt8(offset++);
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
          final int dataCount = byteData.getUint32(offset);
          offset+=4;
          final HashMap<CoordinateSetI, HistoryColorReference> data = HashMap<CoordinateSetI, HistoryColorReference>();
          for (int j = 0; j < dataCount; j++)
          {
            final int x = byteData.getUint16(offset);
            offset+=2;
            final int y = byteData.getUint16(offset);
            offset+=2;
            final int colorRampIndex = byteData.getUint8(offset++);
            if (colorRampIndex >= rampList.length) return LoadFileSet(status: "Color Ramp index out of range for layer $i : $colorRampIndex");
            final int colorIndex = byteData.getUint8(offset++);
            if (colorIndex >= rampList[colorRampIndex].settings.colorCount) return LoadFileSet(status: "Color index out of range for layer $i: $colorIndex");
            data[CoordinateSetI(x: x, y: y)] = HistoryColorReference(colorIndex: colorIndex, rampIndex: colorRampIndex);
          }
          layerList.add(HistoryDrawingLayer(visibilityState: visibilityState, lockState: lockState, data: data, settings: drawingLayerSettings));
        }
        else if (historyLayerValueMap[layerType] == HistoryReferenceLayer) //REFERENCE LAYER
        {
          //path (string)
          final int pathLength = byteData.getInt16(offset);
          offset += 2;
          final List<int> pathBytes = <int>[];
          for (int i = 0; i < pathLength; i++)
          {
            pathBytes.add(byteData.getUint8(offset++));
          }
          final String pathString = utf8.decode(pathBytes);
          //opacity ``ubyte (1)`` // 0...100
          int opacity = byteData.getUint8(offset++);
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
          final double offsetX = byteData.getFloat32(offset);
          offset += 4;
          //offset_y ``float (1)``
          final double offsetY = byteData.getFloat32(offset);
          offset += 4;

          //zoom ``ushort (1)``
          int zoom = byteData.getUint16(offset);
          offset += 2;
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
          double aspectRatio = byteData.getFloat32(offset);
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
          offset+=4;

          layerList.add(HistoryReferenceLayer(visibilityState: visibilityState, zoom: zoom, opacity: opacity, offsetY: offsetY, offsetX: offsetX, path: pathString, aspectRatio: aspectRatio));
        }
        else if (historyLayerValueMap[layerType] == HistoryGridLayer) //GRID LAYER
        {
          //opacity ``ubyte (1)`` // 0...100
          int opacity = byteData.getUint8(offset++);
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
          int brightness = byteData.getUint8(offset++);
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
          final int gridTypeValue = byteData.getUint8(offset++);
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
          int intervalX = byteData.getUint8(offset++);
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
          int intervalY = byteData.getUint8(offset++);
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
          double horizon = byteData.getFloat32(offset);
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
          offset += 4;

          //vanishing_point_1 ``float (1)``// 0...1 (horizontal position of first vanishing point)
          double vanishingPoint1 = byteData.getFloat32(offset);
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
          offset += 4;

          //vanishing_point_2 ``float (1)``// 0...1 (horizontal position of second vanishing point)
          double vanishingPoint2 = byteData.getFloat32(offset);
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
          offset += 4;

          //vanishing_point_3 ``float (1)``// 0...1 (vertical position of third vanishing point)
          double vanishingPoint3 = byteData.getFloat32(offset);
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
          offset += 4;

          layerList.add(HistoryGridLayer(visibilityState: visibilityState, opacity: opacity, gridType: gridType, brightness: brightness, intervalX: intervalX, intervalY: intervalY, horizonPosition: horizon, vanishingPoint1: vanishingPoint1, vanishingPoint2: vanishingPoint2, vanishingPoint3: vanishingPoint3));
        }
        else if (historyLayerValueMap[layerType] == HistoryShadingLayer) //SHADING LAYER
        {
          // LOCK STATE
          final int lockStateVal = byteData.getUint8(offset++);
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
            // SHADING LIMIT LOW
            int shadingStepLimitLow = byteData.getUint8(offset++);
            if (shadingStepLimitLow < shadingLayerSettingsConstraints.shadingStepsMin || shadingStepLimitLow > shadingLayerSettingsConstraints.shadingStepsMax)
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
            int shadingStepLimitHigh = byteData.getUint8(offset++);
            if (shadingStepLimitHigh < shadingLayerSettingsConstraints.shadingStepsMin || shadingStepLimitHigh > shadingLayerSettingsConstraints.shadingStepsMax)
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


          final int dataCount = byteData.getUint32(offset);
          offset+=4;
          final HashMap<CoordinateSetI, int> data = HashMap<CoordinateSetI, int>();
          for (int j = 0; j < dataCount; j++)
          {
            final int x = byteData.getUint16(offset);
            offset+=2;
            final int y = byteData.getUint16(offset);
            offset+=2;
            final int shading = byteData.getInt8(offset++);
            data[CoordinateSetI(x: x, y: y)] = shading;
          }

          layerList.add(HistoryShadingLayer(visibilityState: visibilityState, lockState: lockState, data: data, settings: shadingLayerSettings));
        }
      }
      final HistorySelectionState selectionState = HistorySelectionState(content: HashMap<CoordinateSetI, HistoryColorReference?>(), currentLayer: layerList[0]);
      final HistoryState historyState = HistoryState(layerList: layerList, selectedColor: HistoryColorReference(colorIndex: 0, rampIndex: 0), selectionState: selectionState, canvasSize: canvasSize, rampList: rampList, selectedLayerIndex: 0, type: const HistoryStateType(identifier: HistoryStateTypeIdentifier.loadData, description: "load data", compressionBehavior: HistoryStateCompressionBehavior.leave));

      return LoadFileSet(status: returnString.toString(), historyState: historyState, path: path);
    }
    catch (pnfe)
    {
      return LoadFileSet(status: "Could not load file $path");
    }
  }



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

  Future<String?> getPathForKPixFile() async
  {
    FilePickerResult? result;
    if (isDesktop(includingWeb: true))
    {
      result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: <String>[fileExtensionKpix],
          initialDirectory: GetIt.I.get<AppState>().exportDir,
      );
    }
    else //mobile
    {
      result = await FilePicker.platform.pickFiles(
          initialDirectory: GetIt.I.get<AppState>().exportDir,
      );
    }
    if (result != null && result.files.isNotEmpty)
    {
      String path = result.files.first.name;
      if (!kIsWeb && result.files.first.path != null)
      {
        path = result.files.first.path!;
      }
      return path;
    }
    else
    {
      return null;
    }
  }

  Future<String?> getPathForKPalFile() async
  {
    FilePickerResult? result;
    if (isDesktop(includingWeb: true))
    {
      result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: <String>[fileExtensionKpal],
          initialDirectory: GetIt.I.get<AppState>().exportDir,
      );
    }
    else //mobile
        {
      result = await FilePicker.platform.pickFiles(
          initialDirectory: GetIt.I.get<AppState>().exportDir,
      );
    }
    if (result != null && result.files.isNotEmpty)
    {
      String path = result.files.first.name;
      if (!kIsWeb && result.files.first.path != null)
      {
        path = result.files.first.path!;
      }
      return path;
    }
    else
    {
      return null;
    }
  }

  Future<(String?, Uint8List?)> getPathAndDataForImage() async
  {
    FilePickerResult? result;
    if (isDesktop())
    {
      result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowedExtensions: imageExtensions,
          initialDirectory: GetIt.I.get<AppState>().exportDir,
      );
    }
    else if (kIsWeb)
    {
      result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: imageExtensions,
          initialDirectory: GetIt.I.get<AppState>().exportDir,
      );
    }
    else //mobile
    {
      result = await FilePicker.platform.pickFiles(
          initialDirectory: GetIt.I.get<AppState>().exportDir,
      );
    }
    if (result != null && result.files.isNotEmpty)
    {
      String path = result.files.first.name;
      if (!kIsWeb && result.files.first.path != null)
      {
        path = result.files.first.path!;
      }
      return (path, result.files.first.bytes);
    }
    else
    {
      return (null, null);
    }
  }

  void loadFilePressed({final Function()? finishCallback})
  {
    if (isDesktop(includingWeb: true))
    {
      FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: <String>[fileExtensionKpix],
          initialDirectory: GetIt.I.get<AppState>().exportDir,
      ).then((final FilePickerResult? result) {_loadFileChosen(result: result, finishCallback: finishCallback);});
    }
    else //mobile
    {
      FilePicker.platform.pickFiles(
          initialDirectory: GetIt.I.get<AppState>().exportDir,
      ).then((final FilePickerResult? result) {_loadFileChosen(result: result, finishCallback: finishCallback);});
    }
  }

  void _loadFileChosen({final FilePickerResult? result, required final Function()? finishCallback})
  {
    if (result != null && result.files.isNotEmpty)
    {
      String path = result.files.first.name;
      if (!kIsWeb && result.files.first.path != null)
      {
        path = result.files.first.path!;
      }
      loadKPixFile(
        fileData: result.files.first.bytes,
        constraints: GetIt.I.get<PreferenceManager>().kPalConstraints,
        path: path,
        sliderConstraints: GetIt.I.get<PreferenceManager>().kPalSliderConstraints,
        referenceLayerSettings: GetIt.I.get<PreferenceManager>().referenceLayerSettings,
        gridLayerSettings: GetIt.I.get<PreferenceManager>().gridLayerSettings,
        drawingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().drawingLayerSettingsConstraints,
        shadingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().shadingLayerSettingsConstraints,
      ).then((final LoadFileSet loadFileSet){fileLoaded(loadFileSet: loadFileSet, finishCallback: finishCallback);});
    }
  }

  void fileLoaded({required final LoadFileSet loadFileSet, required final Function()? finishCallback})
  {
    GetIt.I.get<AppState>().restoreFromFile(loadFileSet: loadFileSet);
    if (finishCallback != null)
    {
      finishCallback();
    }
  }

  Future<void> saveFilePressed({required final String fileName, final Function()? finishCallback, final bool forceSaveAs = false}) async
  {
    final AppState appState = GetIt.I.get<AppState>();
    if (!kIsWeb)
    {
      final String finalPath = p.join(appState.internalDir, projectsSubDirName, "$fileName.$fileExtensionKpix");
      saveKPixFile(path: finalPath, appState: GetIt.I.get<AppState>()).then((final String path){_projectFileSaved(fileName: fileName, path: path, finishCallback: finishCallback);});
    }
    else
    {
      saveKPixFile(path: fileName, appState: GetIt.I.get<AppState>()).then((final String path){_projectFileSaved(fileName: fileName, path: path, finishCallback: finishCallback);});
    }
  }

  Future<void> _projectFileSaved({required final String fileName, required final String path, required final Function()? finishCallback}) async
  {
    final AppState appState = GetIt.I.get<AppState>();
    if (!kIsWeb)
    {
      final String? pngPath = await replaceFileExtension(filePath: path, newExtension: thumbnailExtension, inputFileMustExist: true);
      if (pngPath != null)
      {
        final ui.Image img = await getImageFromLayers(appState: appState);
        final ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
        await File(pngPath).writeAsBytes(pngBytes!.buffer.asUint8List());
      }
    }

    appState.fileSaved(saveName: fileName, path: path, addKPixExtension: kIsWeb);
    if (finishCallback != null)
    {
      finishCallback();
    }
  }

  Future<bool> copyImportFile({required final String inputPath, required final ui.Image image, required final String targetPath}) async
  {
    final String? pngPath = await replaceFileExtension(filePath: targetPath, newExtension: thumbnailExtension, inputFileMustExist: false);
    final File projectFile = File(inputPath);
    if (pngPath != null && await projectFile.exists())
    {
      final ByteData? pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (pngBytes != null)
      {
        await File(pngPath).writeAsBytes(pngBytes.buffer.asUint8List());
        final File createdFile = await projectFile.copy(targetPath);
        if (!await createdFile.exists())
        {
          return false;
        }
      }
      else
      {
        return false;
      }
    }
    else
    {
      return false;
    }
    return true;
  }

  Future<bool> deleteProject({required final String fullProjectPath}) async
  {
    final bool success = await deleteFile(path: fullProjectPath);
    final String? pngPath = await replaceFileExtension(filePath: fullProjectPath, newExtension: thumbnailExtension, inputFileMustExist: false);
    if (pngPath != null)
    {
      await deleteFile(path: pngPath);
    }
    return success;
  }

  Future<bool> deleteFile({required final String path}) async
  {
    final File file = File(path);
    if (await file.exists())
    {
      await file.delete();
    }
    else
    {
      return false;
    }
    return true;
  }

  Future<bool> saveCurrentPalette({required final String fileName, required final String directory, required final String extension}) async
  {
    final String finalPath = p.join(directory, fileName);
    final List<KPalRampData> rampList = GetIt.I.get<AppState>().colorRamps;
    final Uint8List data = await createPaletteKPalData(rampList: rampList);
    return await _savePaletteDataToFile(data: data, path: finalPath, extension: extension);
  }


  void exportPalettePressed({required final PaletteExportData saveData, required final PaletteExportType paletteType})
  {
    final String finalPath = p.join(saveData.directory, saveData.fileName);
    final List<KPalRampData> rampList = GetIt.I.get<AppState>().colorRamps;
    final ColorNames colorNames = GetIt.I.get<PreferenceManager>().colorNames;

    switch (paletteType)
    {
      case PaletteExportType.kpal:
        createPaletteKPalData(rampList: rampList).then((final Uint8List data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        //break;
      case PaletteExportType.png:
        getPalettePngData(ramps: rampList).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        //break;
      case PaletteExportType.aseprite:
        getPaletteAsepriteData(rampList: rampList).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        //break;
      case PaletteExportType.gimp:
        getPaletteGimpData(rampList: rampList, colorNames: colorNames).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        //break;
      case PaletteExportType.paintNet:
        getPalettePaintNetData(rampList: rampList, colorNames: colorNames).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        //break;
      case PaletteExportType.adobe:
        getPaletteAdobeData(rampList: rampList, colorNames: colorNames).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        //break;
      case PaletteExportType.jasc:
        getPaletteJascData(rampList: rampList).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        //break;
      case PaletteExportType.corel:
        getPaletteCorelData(rampList: rampList, colorNames: colorNames).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        //break;
      case PaletteExportType.openOffice:
        getPaletteOpenOfficeData(rampList: rampList, colorNames: colorNames).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        //break;
    }
  }

  Future<bool> _savePaletteDataToFile({required final Uint8List? data, required final String path, required final String extension}) async
  {
    final String pathWithExtension = "$path.$extension";
    if (data != null)
    {
      if (!kIsWeb)
      {
        await File(pathWithExtension).writeAsBytes(data);
        GetIt.I.get<AppState>().showMessage(text: "Palette saved at: $pathWithExtension");
      }
      else
      {
        final String newPath = await FileSaver.instance.saveFile(
          name: path,
          bytes: data,
          ext: extension,
        );
        GetIt.I.get<AppState>().showMessage(text: "Palette saved at: $newPath/$pathWithExtension");
      }
      return true;
    }
    else
    {
      GetIt.I.get<AppState>().showMessage(text: "Palette saving failed");
      return false;
    }
  }

  Future<LoadPaletteSet> _loadKPalFile({required Uint8List? fileData, required final String path, required final KPalConstraints constraints, required final KPalSliderConstraints sliderConstraints}) async
  {
    fileData ??= await File(path).readAsBytes();
    final ByteData byteData = fileData.buffer.asByteData();
    int offset = 0;

    //skip options
    final int optionCount = byteData.getUint8(offset++);
    offset += optionCount * 2;

    final int rampCount = byteData.getUint8(offset++);
    if (rampCount <= 0) return LoadPaletteSet(status: "no ramp found");
    final List<KPalRampData> rampList = <KPalRampData>[];
    for (int i = 0; i < rampCount; i++)
    {
      final KPalRampSettings kPalRampSettings = KPalRampSettings(constraints: constraints);
      final int nameLength = byteData.getUint8(offset++);
      offset += nameLength;
      kPalRampSettings.colorCount = byteData.getUint8(offset++);
      if (kPalRampSettings.colorCount < constraints.colorCountMin || kPalRampSettings.colorCount > constraints.colorCountMax) return LoadPaletteSet(status: "Invalid color count in palette $i: ${kPalRampSettings.colorCount}");
      kPalRampSettings.baseHue = byteData.getInt16(offset, Endian.little);
      offset+=2;
      if (kPalRampSettings.baseHue < constraints.baseHueMin || kPalRampSettings.baseHue > constraints.baseHueMax) return LoadPaletteSet(status: "Invalid base hue value in palette $i: ${kPalRampSettings.baseHue}");
      kPalRampSettings.baseSat = byteData.getInt16(offset, Endian.little);
      offset+=2;
      if (kPalRampSettings.baseSat < constraints.baseSatMin || kPalRampSettings.baseSat > constraints.baseSatMax) return LoadPaletteSet(status: "Invalid base sat value in palette $i: ${kPalRampSettings.baseSat}");
      kPalRampSettings.hueShift = byteData.getInt8(offset++);
      if (kPalRampSettings.hueShift < constraints.hueShiftMin || kPalRampSettings.hueShift > constraints.hueShiftMax) return LoadPaletteSet(status: "Invalid hue shift value in palette $i: ${kPalRampSettings.hueShift}");
      kPalRampSettings.hueShiftExp = byteData.getFloat32(offset, Endian.little);
      offset += 4;
      if (kPalRampSettings.hueShiftExp < (constraints.hueShiftExpMin - _floatDelta) || kPalRampSettings.hueShiftExp > (constraints.hueShiftExpMax + _floatDelta)) return LoadPaletteSet(status: "Invalid hue shift exp value in palette $i: ${kPalRampSettings.hueShiftExp}");
      kPalRampSettings.hueShiftExp = kPalRampSettings.hueShiftExp.clamp(constraints.hueShiftExpMin, constraints.hueShiftExpMax);
      kPalRampSettings.satShift = byteData.getInt8(offset++);
      if (kPalRampSettings.satShift < constraints.satShiftMin || kPalRampSettings.satShift > constraints.satShiftMax) return LoadPaletteSet(status: "Invalid sat shift value in palette $i: ${kPalRampSettings.satShift}");
      kPalRampSettings.satShiftExp = byteData.getFloat32(offset, Endian.little);
      offset += 4;
      if (kPalRampSettings.satShiftExp < (constraints.satShiftExpMin - _floatDelta) || kPalRampSettings.satShiftExp > (constraints.satShiftExpMax + _floatDelta)) return LoadPaletteSet(status: "Invalid sat shift exp value in palette $i: ${kPalRampSettings.satShiftExp}");
      kPalRampSettings.satShiftExp = kPalRampSettings.satShiftExp.clamp(constraints.satShiftExpMin, constraints.satShiftExpMax);
      kPalRampSettings.valueRangeMin = byteData.getUint8(offset++);
      kPalRampSettings.valueRangeMax = byteData.getUint8(offset++);
      if (kPalRampSettings.valueRangeMin < constraints.valueRangeMin || kPalRampSettings.valueRangeMax > constraints.valueRangeMax || kPalRampSettings.valueRangeMax < kPalRampSettings.valueRangeMin) return LoadPaletteSet(status: "Invalid value range in palette $i: ${kPalRampSettings.valueRangeMin}-${kPalRampSettings.valueRangeMax}");

      final List<HistoryShiftSet> shifts = <HistoryShiftSet>[];
      for (int j = 0; j < kPalRampSettings.colorCount; j++)
      {
        final int hueShift = byteData.getInt8(offset++);
        final int satShift = byteData.getInt8(offset++);
        final int valShift = byteData.getInt8(offset++);
        if (hueShift > sliderConstraints.maxHue || hueShift < sliderConstraints.minHue) return LoadPaletteSet(status: "Invalid Hue Shift in Ramp $i, color $j: $hueShift");
        if (satShift > sliderConstraints.maxSat || satShift < sliderConstraints.minSat) return LoadPaletteSet(status: "Invalid Sat Shift in Ramp $i, color $j: $satShift");
        if (valShift > sliderConstraints.maxVal || valShift < sliderConstraints.minVal) return LoadPaletteSet(status: "Invalid Val Shift in Ramp $i, color $j: $valShift");
        final HistoryShiftSet shiftSet = HistoryShiftSet(hueShift: hueShift, satShift: satShift, valShift: valShift);
        shifts.add(shiftSet);
      }
      final int rampOptionCount = byteData.getInt8(offset++);
      for (int j = 0; j < rampOptionCount; j++)
      {
        final int optionType = byteData.getInt8(offset++);
        if (optionType == 1) //sat curve
        {
          final int satCurveVal = byteData.getInt8(offset);
          kPalRampSettings.satCurve = _kpalKpixSatCurveMap[satCurveVal]?? SatCurve.noFlat;
        }
        offset++;
      }
      rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: kPalRampSettings, historyShifts: shifts));
    }
    return LoadPaletteSet(status: "loading okay", rampData: rampList);

  }

  Future<String?> getDirectory({required final String startDir}) async
  {
    return await FilePicker.platform.getDirectoryPath(dialogTitle: "Choose Directory", initialDirectory: startDir);
  }

  Future<String?> exportFile({required final ExportData exportData, required final FileExportType exportType}) async
  {
    final String path = !kIsWeb ? p.join(exportData.directory, "${exportData.fileName}.${exportData.extension}") : exportData.fileName;
    final AppState appState = GetIt.I.get<AppState>();

    Uint8List? data;

    switch (exportType)
    {
      case FileExportType.png:
        data = await exportPNG(exportData: exportData, appState: appState);
        //break;
      case FileExportType.aseprite:
        data = await getAsepriteData(exportData: exportData, appState: appState);
        //break;
      //case ExportType.photoshop:
      // TODO: Handle this case.
      //  break;
      case FileExportType.gimp:
        data = await getGimpData(exportData: exportData, appState: appState);
        //break;
      case FileExportType.kpix:
        data = (await createKPixData(appState: appState)).buffer.asUint8List();
        //break;
    }

    String? returnPath;
    if (data != null)
    {
      if (!kIsWeb)
      {
        await File(path).writeAsBytes(data);
        returnPath = path;
      }
      else
      {
        final String newPath = await FileSaver.instance.saveFile(
          name: path,
          bytes: data,
          ext: exportData.extension,
        );
        returnPath = "$newPath/$path.${exportData.extension}";
      }
    }

    return returnPath;
  }

  FileNameStatus checkFileName({required final String fileName, required final String directory, required final String extension, final bool allowRecoverFile = true})
  {
    if (fileName.isEmpty)
    {
      return FileNameStatus.forbidden;
    }

    if (kIsWeb)
    {
      return FileNameStatus.available;
    }

    if (Platform.isWindows)
    {
      final List<String> reservedFilenames = <String>[
        'CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
        'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9',
      ];
      if (fileName.endsWith(' ') || fileName.endsWith('.') || reservedFilenames.contains(fileName.toUpperCase()))
      {
        return FileNameStatus.forbidden;
      }
    }

    if (fileName == recoverFileName && !allowRecoverFile)
    {
      return FileNameStatus.forbidden;
    }

    final List<String> invalidCharacters = <String>['/', '\\', '?', '%', '*', ':', '|', '"', '<', '>'];
    for (final String char in invalidCharacters)
    {
      if (fileName.contains(char))
      {
        return FileNameStatus.forbidden;
      }
    }
    if (!hasWriteAccess(directory: directory))
    {
      return FileNameStatus.noRights;
    }

    final String fullPath = p.join(directory, "$fileName.$extension");
    final File file = File(fullPath);
    if (file.existsSync())
    {
      return FileNameStatus.overwrite;
    }

    return FileNameStatus.available;

  }

  bool hasWriteAccess({required final String directory}) {
    try {
      final File tempFile = File('$directory${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}.tmp');
      tempFile.createSync();
      tempFile.deleteSync();
      return true;
    }
    catch (e)
    {
      return false;
    }
  }

  Future<String> findExportDir() async
  {
    if (!kIsWeb)
    {
      if (isDesktop() || Platform.isIOS)
      {
        final Directory? downloadDir = await getDownloadsDirectory();
        if (downloadDir != null)
        {
          return downloadDir.path;
        }
      }
      else if (Platform.isAndroid)
      {
        final Directory directoryDL = Directory("/storage/emulated/0/Download/");
        final Directory directoryDLs = Directory("/storage/emulated/0/Downloads/");
        if (await directoryDL.exists())
        {
          return directoryDL.path;
        }
        else if (await directoryDLs.exists())
        {
          return directoryDLs.path;
        }
        else
        {
          final Directory? directory = await getExternalStorageDirectory();
          if (directory != null && await directory.exists())
          {
            return directory.path;
          }
        }
      }
    }
    return "";
  }

  Future<String> findInternalDir() async
  {
    if (kIsWeb)
    {
      return "";
    }

      final Directory internalDir = await getApplicationSupportDirectory();
      return internalDir.path;
  }

  Future<List<PaletteManagerEntryData>> loadPalettesFromAssets() async
  {
    final List<PaletteManagerEntryData> paletteData = <PaletteManagerEntryData>[];
    final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final List<String> imageAssetsList = assetManifest.listAssets().where((final String string) => string.startsWith("palettes/") && string.endsWith(".$fileExtensionKpal")).toList();
    for (final String filePath in imageAssetsList)
    {
      final ByteData bytes = await rootBundle.load(filePath);
      final Uint8List byteData = bytes.buffer.asUint8List();
      final LoadPaletteSet palSet = await _loadKPalFile(path: filePath, constraints: GetIt.I.get<PreferenceManager>().kPalConstraints, fileData: byteData, sliderConstraints: GetIt.I.get<PreferenceManager>().kPalSliderConstraints);
      if (palSet.rampData != null)
      {
        paletteData.add(PaletteManagerEntryData(name: extractFilenameFromPath(path: filePath, keepExtension: false), isLocked: true, rampDataList: palSet.rampData!, path: filePath));
      }
    }
    return paletteData;
  }

  Future<List<PaletteManagerEntryData>> loadPalettesFromInternal() async
  {
    final List<PaletteManagerEntryData> paletteData = <PaletteManagerEntryData>[];
    final Directory dir = Directory(p.join(GetIt.I.get<AppState>().internalDir, palettesSubDirName));
    final List<String> filesWithExtension = <String>[];
    if (await dir.exists())
    {
      dir.listSync(followLinks: false).forEach((final FileSystemEntity entity)
      {
        if (entity is File && entity.path.endsWith(".$fileExtensionKpal"))
        {
          filesWithExtension.add(entity.absolute.path);
        }
      });
    }
    for (final String filePath in filesWithExtension)
    {
      final LoadPaletteSet palSet = await _loadKPalFile(path: filePath, constraints: GetIt.I.get<PreferenceManager>().kPalConstraints, fileData: null, sliderConstraints: GetIt.I.get<PreferenceManager>().kPalSliderConstraints);
      if (palSet.rampData != null)
      {
         paletteData.add(PaletteManagerEntryData(name: extractFilenameFromPath(path: filePath, keepExtension: false), isLocked: false, rampDataList: palSet.rampData!, path: filePath));
      }
    }
    return paletteData;
  }
Future<List<StampManagerEntryData>> loadStamps({required final bool loadUserStamps}) async
{
  final List<StampManagerEntryData> allStamps = <StampManagerEntryData>[];
  allStamps.addAll(await _loadInstalledStamps());
  if (loadUserStamps)
  {
    allStamps.addAll(await _loadUserStamps());
  }
  return allStamps;
}

Future<List<StampManagerEntryData>> _loadInstalledStamps() async
{
  final List<StampManagerEntryData> stampData = <StampManagerEntryData>[];
  final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final List<String> stampAssetList = assetManifest.listAssets().where((final String string) => string.startsWith("stamps/") && string.endsWith(".png")).toList();

  for (final String path in stampAssetList)
  {

    final ByteData byteData = await rootBundle.load(path);
    final Uint8List pngBytes = byteData.buffer.asUint8List();
    final StampManagerEntryData data = await _readStampFromFileData(pngBytes: pngBytes, fileName: path, isLocked: true);
    if (data.thumbnail != null)
    {
      stampData.add(data);
    }
  }
  return stampData;
}

Future<List<StampManagerEntryData>> _loadUserStamps() async
{
  final List<StampManagerEntryData> stampData = <StampManagerEntryData>[];
  final Directory dir = Directory(p.join(GetIt.I.get<AppState>().internalDir, stampsSubDirName));
  final List<String> filesWithExtension = <String>[];
  if (await dir.exists())
  {
    dir.listSync(followLinks: false).forEach((final FileSystemEntity entity)
    {
      if (entity is File && entity.path.endsWith(".png"))
      {
        filesWithExtension.add(entity.absolute.path);
      }
    });
  }
  for (final String filePath in filesWithExtension)
  {
    final Uint8List pngBytes = await File(filePath).readAsBytes();
    final StampManagerEntryData data = await _readStampFromFileData(pngBytes: pngBytes, fileName: filePath, isLocked: false);

    if (data.thumbnail != null)
    {
      stampData.add(data);
    }
  }
  return stampData;
}

Future<StampManagerEntryData> _readStampFromFileData({required final Uint8List pngBytes, required final String fileName, required final bool isLocked}) async
{
  final ui.Image decImg = await decodeImageFromList(pngBytes);
  final int imgHeight = decImg.height;
  final int imgWidth = decImg.width;
  final ByteData? imgData = await decImg.toByteData();
  final HashMap<CoordinateSetI, int> stampMap = HashMap<CoordinateSetI, int>();
  ui.Image? thumbnail;

  if (imgData != null)
  {
    for (int x = 0; x < imgWidth; x++)
    {
      for (int y = 0; y < imgHeight; y++)
      {
        final int r = imgData.getUint8((y * imgWidth * 4) + (x * 4) + 0);
        final int g = imgData.getUint8((y * imgWidth * 4) + (x * 4) + 1);
        final int b = imgData.getUint8((y * imgWidth * 4) + (x * 4) + 2);
        final int a = imgData.getUint8((y * imgWidth * 4) + (x * 4) + 3);
        if (a == 255 && r == g && r == b)
        {
          int? val;
          if (r == 0)
          {
            val = -2;
          }
          else if (r == 64)
          {
            val = -1;
          }
          else if (r == 128)
          {
            val = 0;
          }
          else if (r == 192)
          {
            val = 1;
          }
          else if (r == 255)
          {
            val = 2;
          }

          if (val != null)
          {
            stampMap[CoordinateSetI(x: x, y: y)] = val;
          }
        }
      }
    }
    try
    {
      final ui.Codec codec = await ui.instantiateImageCodec(pngBytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      thumbnail = frame.image;
    }
    catch(_){}

  }
  return StampManagerEntryData(path: fileName, isLocked: isLocked, name: extractFilenameFromPath(path: fileName, keepExtension: false), data: stampMap, thumbnail: thumbnail, width: imgWidth, height: imgHeight);
}

  Future<List<ProjectManagerEntryData>> loadProjectsFromInternal() async
  {
    final List<ProjectManagerEntryData> projectData = <ProjectManagerEntryData>[];
    final Directory dir = Directory(p.join(GetIt.I.get<AppState>().internalDir, projectsSubDirName));

    if (await dir.exists())
    {
      await for (final FileSystemEntity entity in dir.list(followLinks: false))
      {
        if (entity is File && entity.path.endsWith(".$fileExtensionKpix"))
        {
          final String? pngPath = await replaceFileExtension(filePath: entity.absolute.path, newExtension: thumbnailExtension, inputFileMustExist: true);
          ui.Image? thumbnail;
          if (pngPath != null)
          {
            final File pngFile = File(pngPath);
            if (await pngFile.exists())
            {
              final Uint8List imageBytes = await pngFile.readAsBytes();
              final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
              final ui.FrameInfo frame = await codec.getNextFrame();
              thumbnail = frame.image;
            }
          }
          projectData.add(ProjectManagerEntryData(name: extractFilenameFromPath(path: entity.absolute.path, keepExtension: false), path: entity.absolute.path, thumbnail: thumbnail, dateTime: await entity.lastModified()));
        }
      }
    }
    return projectData;
  }

  void setUint64({required final ByteData bytes, required final int offset, required final int value, final Endian endian = Endian.big})
  {
    if (kIsWeb)
    {
      final int low = value & 0xFFFFFFFF;
      final int high = (value >> 32) & 0xFFFFFFFF;

      if (endian == Endian.little)
      {
        bytes.setUint32(offset, low, Endian.little);
        bytes.setUint32(offset + 4, high, Endian.little);
      }
      else
      {
        bytes.setUint32(offset, high);
        bytes.setUint32(offset + 4, low);
      }
    }
    else
    {
      bytes.setUint64(offset, value);
    }
  }

  Future<void> createInternalDirectories() async
  {
    final List<Directory> internalDirectories =
    <Directory>[
      Directory(p.join(GetIt.I.get<AppState>().internalDir, palettesSubDirName)),
      Directory(p.join(GetIt.I.get<AppState>().internalDir, projectsSubDirName)),
      Directory(p.join(GetIt.I.get<AppState>().internalDir, recoverSubDirName)),
      Directory(p.join(GetIt.I.get<AppState>().internalDir, stampsSubDirName)),
    ];

    for (final Directory dir in internalDirectories)
    {
      final bool dirExists = await dir.exists();
      if (!dirExists)
      {
        await dir.create();
      }
    }
  }

  Future<void> clearRecoverDir() async
  {
    final Directory recoverDir = Directory(p.join(GetIt.I.get<AppState>().internalDir, recoverSubDirName));
    final List<FileSystemEntity> files = await recoverDir.list().toList();
    for (final FileSystemEntity file in files)
    {
      await file.delete(recursive: true);
    }
  }

  Future<String?> getRecoveryFile() async
  {
    final Directory recoverDir = Directory(p.join(GetIt.I.get<AppState>().internalDir, recoverSubDirName));
    final List<FileSystemEntity> files = await recoverDir.list().toList();
    if (files.length == 1)
    {
      return files[0].path;
    }
    else
    {
      return null;
    }
  }

  Future<bool> importProject({required final String? path, final bool showMessages = true}) async
  {
    bool success = false;
    if (path != null && path.isNotEmpty)
    {
      if (path.endsWith(fileExtensionKpix))
      {
        final LoadFileSet loadFileSet = await loadKPixFile(
            fileData: null,
            constraints: GetIt.I.get<PreferenceManager>().kPalConstraints,
            path: path,
            sliderConstraints: GetIt.I.get<PreferenceManager>().kPalSliderConstraints,
            referenceLayerSettings: GetIt.I.get<PreferenceManager>().referenceLayerSettings,
            gridLayerSettings: GetIt.I.get<PreferenceManager>().gridLayerSettings,
            drawingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().drawingLayerSettingsConstraints,
            shadingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().shadingLayerSettingsConstraints,
        );
        final AppState appState = GetIt.I.get<AppState>();
        if (loadFileSet.historyState != null && loadFileSet.path != null)
        {
          final String fileName = extractFilenameFromPath(path: loadFileSet.path);
          final String projectPath = p.join(appState.internalDir, projectsSubDirName, fileName);
          if (!File(projectPath).existsSync())
          {
            final ui.Image? img = await getImageFromLoadFileSet(loadFileSet: loadFileSet, size: loadFileSet.historyState!.canvasSize);
            if (img != null)
            {
              success = await copyImportFile(inputPath: loadFileSet.path!, image: img, targetPath: projectPath);
            }
            else
            {
              if (showMessages) appState.showMessage(text: "Could not open file!");
            }
          }
          else
          {
            if (showMessages) appState.showMessage(text: "Project with the same name already exists!");
          }
        }
        else
        {
          if (showMessages) appState.showMessage(text: "Could not open file!");
        }
      }
      else
      {
        GetIt.I.get<AppState>().showMessage(text: "Please select a KPix file!");
      }
    }
    return success;
  }
