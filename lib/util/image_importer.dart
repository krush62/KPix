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

import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/managers/reference_image_manager.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/file/import_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/tools/reference_layer_options_widget.dart';
import 'package:uuid/uuid.dart';

class ImportDataSet
{
  final ReferenceLayerState? referenceLayer;
  final DrawingLayerState drawingLayer;
  final CoordinateSetI canvasSize;
  final List<KPalRampData> rampDataList;

  ImportDataSet({required this.referenceLayer, required this.rampDataList, required this.drawingLayer, required this.canvasSize});
}

class ImportResult
{
  final ImportDataSet? data;
  final String message;
  ImportResult({this.data, required this.message});
}

  Future<ImportResult> import({required final ImportData importData, required final List<KPalRampData> currentRamps}) async
  {
    final ByteData? imageData = await importData.scaledImage.toByteData();
    if (imageData == null)
    {
      return ImportResult(message: "Could not convert image data!");
    }
    else
    {
      DrawingLayerState drawingLayer;
      List<KPalRampData> ramps = <KPalRampData>[];
      final List<HSVColor> hsvColorList = await _extractColorsFromImage(imgBytes: imageData);
      if (importData.createNewPalette)
      {
        final List<HSVColor> distinctHsvColorList = hsvColorList.toSet().toList(growable: false);
        final List<List<HSVColor>> clusteredColors = await _adaptiveClusterWithMaxRamps(maxRamps: importData.maxRamps, colors: distinctHsvColorList, initialClusters: 16);

        final List<List<HSVColor>> interpolatedColors = <List<HSVColor>>[];
        for (final List<HSVColor> clusterColorRamp in clusteredColors)
        {
          final List<HSVColor> interpolatedRamp = await _interpolateColorsFromRamp(ramp: clusterColorRamp, maxColors: importData.maxColors);
          interpolatedColors.add(interpolatedRamp);
        }


        for (final List<HSVColor> interRamp in interpolatedColors)
        {
          ramps.add(await _getParamsFromColorList(colors: interRamp));
        }

        drawingLayer = await _createDrawingLayer(colorList: hsvColorList, width: importData.scaledImage.width, height: importData.scaledImage.height, ramps: ramps);
        await _removeUnusedRamps(ramps: ramps, references: drawingLayer.getData().values.toSet());
        if (!ramps.contains(drawingLayer.settings.outerColorReference.value.ramp))
        {
          drawingLayer.settings.outerColorReference.value = ramps.first.references.first;
        }
        if (!ramps.contains(drawingLayer.settings.innerColorReference.value.ramp))
        {
          drawingLayer.settings.innerColorReference.value = ramps.first.references.first;
        }
        if (!ramps.contains(drawingLayer.settings.dropShadowColorReference.value.ramp))
        {
          drawingLayer.settings.dropShadowColorReference.value = ramps.first.references.first;
        }
      }
      else
      {
        ramps = currentRamps;
        drawingLayer = await _createDrawingLayer(colorList: hsvColorList, width: importData.scaledImage.width, height: importData.scaledImage.height, ramps: ramps);
      }

      ReferenceLayerState? referenceLayer;
      if (importData.includeReference)
      {
        referenceLayer = await _getReferenceLayer(img: importData.image, imgPath: importData.filePath);
        final double targetZoomHeight = importData.scaledImage.height.toDouble() / (importData.image.height.toDouble());
        final double targetZoomWidth = importData.scaledImage.width.toDouble() / (importData.image.width.toDouble());
        referenceLayer.setZoomSliderFromZoomFactor(factor: (targetZoomWidth + targetZoomHeight) / 2.0);
      }

      final ImportDataSet importDataSet = ImportDataSet(rampDataList: ramps, drawingLayer: drawingLayer, referenceLayer: referenceLayer, canvasSize: CoordinateSetI(x: importData.scaledImage.width, y: importData.scaledImage.height));
      return ImportResult(message: "SUCCESS", data: importDataSet);

    }

  }

  Future<void> _removeUnusedRamps({required final List<KPalRampData> ramps, required final Set<ColorReference> references}) async
  {
    final List<bool> rampUsed = List<bool>.filled(ramps.length, false);

    for (final ColorReference reference in references)
    {
      for (int i = 0; i < ramps.length; i++)
      {
        if (ramps[i].references.contains(reference))
        {
          rampUsed[i] = true;
          break;
        }
      }
    }

    final List<KPalRampData> deleteRamps = <KPalRampData>[];
    for (int i = 0; i < rampUsed.length; i++)
    {
      if (rampUsed[i] == false)
      {
         deleteRamps.add(ramps[i]);
      }
    }

    for (final KPalRampData deleteRamp in deleteRamps)
    {
      ramps.remove(deleteRamp);
    }
  }

  Future<ReferenceLayerState> _getReferenceLayer({required final ui.Image img, required final String imgPath}) async
  {
    final ReferenceLayerSettings refSettings = GetIt.I.get<PreferenceManager>().referenceLayerSettings;
    final ReferenceLayerState refState = ReferenceLayerState(aspectRatio: refSettings.aspectRatioDefault, image: null, offsetX: 0, offsetY: 0, opacity: refSettings.opacityDefault, zoom: refSettings.zoomDefault);
    final ReferenceImage refImg = await GetIt.I.get<ReferenceImageManager>().addLoadedImage(path: imgPath, img: img);
    refState.imageNotifier.value = refImg;
    refState.thumbnail.value = refImg.image;
    return refState;
  }

  Future<DrawingLayerState> _createDrawingLayer({required final List<HSVColor> colorList, required final int width, required final int height, required final List<KPalRampData> ramps}) async
  {
    final HashMap<CoordinateSetI, ColorReference?> layerContent = HashMap<CoordinateSetI, ColorReference?>();
    int row = 0;
    int col = 0;
    for (int i = 0; i < colorList.length; i++)
    {
      if (col >= width)
      {
        col = 0;
        row++;
      }
      if (colorList[i].alpha > 0.0)
      {
        final CoordinateSetI coord = CoordinateSetI(x: col, y: row);
        final ColorReference reference = _findClosestColor(hsvColor: colorList[i], ramps: ramps);
        layerContent[coord] = reference;
      }
      col++;
    }
    return DrawingLayerState(size: CoordinateSetI(x: width, y: height), content: layerContent, ramps: ramps);
  }

  ColorReference _findClosestColor({required final HSVColor hsvColor, required final List<KPalRampData> ramps})
  {
    late ColorReference closestReference;
    double closestDelta = double.maxFinite;

    for (int i = 0; i < ramps.length; i++)
    {
      for (int j = 0; j < ramps[i].references.length; j++)
      {
        final Color convertColor = hsvColor.toColor();
        final ColorReference reference = ramps[i].references[j];
        final double delta = getDeltaE(
            redA: reference.getIdColor().color.r,
            greenA: reference.getIdColor().color.g,
            blueA: reference.getIdColor().color.b,
            redB: convertColor.r,
            greenB: convertColor.g,
            blueB: convertColor.b,);
        /*final int redDelta = (reference.getIdColor().color.red - convertColor.red).abs();
        final int greenDelta = (reference.getIdColor().color.green - convertColor.green).abs();
        final int blueDelta = (reference.getIdColor().color.blue - convertColor.blue).abs();
        final double delta = (redDelta + greenDelta + blueDelta).toDouble();*/

        if (delta < closestDelta || (i == 0 && j == 0))
        {
          closestReference = reference;
          closestDelta = delta;
        }
      }
    }
    return closestReference;
  }

  Future<KPalRampData> _getParamsFromColorList({required final List<HSVColor> colors}) async
  {
    final KPalConstraints constraints = GetIt.I.get<PreferenceManager>().kPalConstraints;
    colors.sort((final HSVColor a, final HSVColor b) => a.value.compareTo(b.value));
    HSVColor virtualCenterColor;
    if (colors.length.isEven)
    {
      final int centerIndex2 = colors.length ~/ 2;
      final int centerIndex1 = centerIndex2 - 1;
      final HSVColor centerColor1 = colors[centerIndex1];
      final HSVColor centerColor2 = colors[centerIndex2];

      final double virtualCenterHue = _interpolateHue(hue1: centerColor1.hue, hue2: centerColor2.hue);
      final double virtualCenterSaturation = (centerColor1.saturation + centerColor2.saturation) / 2;
      final double virtualCenterValue = (centerColor1.value + centerColor2.value) / 2;
      virtualCenterColor = HSVColor.fromAHSV(1.0, virtualCenterHue, virtualCenterSaturation, virtualCenterValue);
    }
    else
    {
      virtualCenterColor = colors[colors.length ~/ 2];
    }
    final double baseHue = virtualCenterColor.hue;
    final double baseSaturation = virtualCenterColor.saturation;

    List<double> hueShifts = <double>[];
    for (int i = 1; i < colors.length; i++)
    {
      final double shift = (colors[i].hue - colors[i - 1].hue).abs();
      hueShifts.add(shift);
    }
    double hueShift = hueShifts.reduce((final double a, final double b) => a + b) / hueShifts.length;
    final double hueShiftExponent = _estimateExponent(shifts: hueShifts).clamp(constraints.hueShiftExpMin, constraints.hueShiftExpMax);
    hueShifts = _recalculateShifts(originalShifts: hueShifts, clampedExponent: hueShiftExponent);
    hueShift = hueShifts.reduce((final double a, final double b) => a + b) / hueShifts.length;
    hueShift = hueShift.clamp(constraints.hueShiftMin.toDouble() / 100.0, constraints.hueShiftMax.toDouble() / 100.0);

    // Calculate saturation shift and exponent
    List<double> satShifts = <double>[];
    for (int i = 1; i < colors.length; i++) {
      final double shift = (colors[i].saturation - colors[i - 1].saturation).abs();
      satShifts.add(shift);
    }
    double saturationShift = satShifts.reduce((final double a, final double b) => a + b) / satShifts.length;
    final double saturationShiftExponent = _estimateExponent(shifts: satShifts).clamp(constraints.satShiftExpMin, constraints.satShiftExpMax);
    satShifts = _recalculateShifts(originalShifts: satShifts, clampedExponent: saturationShiftExponent);
    saturationShift = satShifts.reduce((final double a, final double b) => a + b) / satShifts.length;
    saturationShift = saturationShift.clamp(constraints.satShiftMin.toDouble() / 100.0, constraints.satShiftMax.toDouble() / 100.0);

    final SatCurve saturationCurveType = _detectSaturationCurve(colors: colors);

    final double minValue = colors.first.value;
    final double maxValue = colors.last.value;
    final KPalRampSettings rampSettings = KPalRampSettings.fromValues(
      constraints: constraints,
      satShift: (saturationShift * 100).round() * -1,
      satShiftExp: saturationShiftExponent,
      satCurve: saturationCurveType,
      hueShift: hueShift.round(),
      hueShiftExp: hueShiftExponent,
      baseHue: baseHue.round(),
      baseSat: (baseSaturation * 100).round(),
      colorCount: colors.length,
      valueRangeMin: (minValue * 100).round(),
      valueRangeMax: (maxValue * 100).round(),
    );
    //TODO maybe add shifts (?)
    return KPalRampData(uuid: const Uuid().v1(), settings: rampSettings);

  }

  List<double> _recalculateShifts({required final List<double> originalShifts, required final double clampedExponent})
  {
    final int shiftCount = originalShifts.length;
    final List<double> adjustedShifts = List<double>.filled(shiftCount, 0);
    for (int i = 0; i < shiftCount; i++)
    {
      adjustedShifts[i] = pow(originalShifts[i].abs(), clampedExponent).toDouble();
    }
    return adjustedShifts;
  }

  SatCurve _detectSaturationCurve({required final List<HSVColor> colors})
  {
    final int colorCount = colors.length;
    final int centerIndex1 = (colorCount ~/ 2) - 1;
    final int centerIndex2 = colorCount ~/ 2;

    final double firstSat = colors.first.saturation;
    final double lastSat = colors.last.saturation;

    final double virtualCenterSaturation = (colors[centerIndex1].saturation + colors[centerIndex2].saturation) / 2;
    double linearError = 0.0;
    for (int i = 0; i < colorCount; i++)
    {
      final double expectedSat = firstSat + (lastSat - firstSat) * (i / (colorCount - 1));
      linearError += (colors[i].saturation - expectedSat).abs();
    }

    double keepDarkError = 0.0;
    for (int i = 0; i <= centerIndex1; i++)
    {
      keepDarkError += (colors[i].saturation - firstSat).abs();
    }
    for (int i = centerIndex2; i < colorCount; i++)
    {
      final double expectedSat = firstSat + (lastSat - firstSat) * ((i - centerIndex1) / (colorCount - centerIndex1 - 1));
      keepDarkError += (colors[i].saturation - expectedSat).abs();
    }

    double keepLightError = 0.0;
    for (int i = 0; i <= centerIndex1; i++)
    {
      final double expectedSat = firstSat + (lastSat - firstSat) * (i / centerIndex1);
      keepLightError += (colors[i].saturation - expectedSat).abs();
    }
    for (int i = centerIndex2; i < colorCount; i++)
    {
      keepLightError += (colors[i].saturation - lastSat).abs();
    }

    double flipError = 0.0;
    for (int i = 0; i <= centerIndex1; i++)
    {
      final double expectedSat = firstSat + (virtualCenterSaturation - firstSat) * (i / centerIndex1);
      flipError += (colors[i].saturation - expectedSat).abs();
    }
    for (int i = centerIndex2; i < colorCount; i++)
    {
      final double expectedSat = virtualCenterSaturation + (virtualCenterSaturation - lastSat) * ((i - centerIndex2) / (colorCount - centerIndex2 - 1));
      flipError += (colors[i].saturation - expectedSat).abs();
    }

    final Map<SatCurve, double> errors = <SatCurve, double>{
      SatCurve.linear: linearError,
      SatCurve.darkFlat: keepDarkError,
      SatCurve.brightFlat: keepLightError,
      SatCurve.noFlat: flipError,
    };

    final SatCurve bestFit = errors.keys.reduce((final SatCurve a, final SatCurve b) => errors[a]! < errors[b]! ? a : b);
    return bestFit;
  }

  double _estimateExponent({required final List<double> shifts})
  {
    final double avgShift = shifts.reduce((final double a, final double b) => a + b) / shifts.length;
    if (avgShift == 0 || avgShift.isNaN)
    {
      return 1.0;
    }

    double exponentSum = 0.0;
    int validShiftCount = 0;
    for (int i = 1; i < shifts.length; i++)
    {
      if (shifts[i] != 0)
      {
        exponentSum += log(shifts[i] / avgShift).abs();
        validShiftCount++;
      }
    }

    if (validShiftCount == 0)
    {
      return 1.0;  // Default exponent when all shifts are zero
    }

    return exponentSum / validShiftCount;
  }

  double _interpolateHue({required double hue1, required double hue2})
  {
    final double diff = (hue2 - hue1).abs();
    if (diff > 180)
    {
      if (hue1  < hue2)
      {
        hue1 += 360;
      }
      else
      {
        hue2 += 360;
      }
    }
    return (hue1 + hue2) / 2 % 360;
  }



  Future<ui.Image?> loadImage({required final String path, final Uint8List? bytes}) async
  {
    ui.Image? image;
    final File imageFile = File(path);
    if (bytes == null && !await imageFile.exists())
    {
      image = null;
    }
    else
    {
      try
      {
        final Uint8List imageBytes = bytes ?? await imageFile.readAsBytes();
        final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
        final ui.FrameInfo frame = await codec.getNextFrame();
        image = frame.image;
        codec.dispose();
      }
      catch(_)
      {
        image = null;
      }
    }
    return image;
  }



  Future<List<HSVColor>> _extractColorsFromImage({required final ByteData imgBytes}) async
  {
    final List<HSVColor> colorList = <HSVColor>[];
    for (int i = 0; i < imgBytes.lengthInBytes; i+=4)
    {
      final int r = imgBytes.getUint8(i + 0);
      final int g = imgBytes.getUint8(i + 1);
      final int b = imgBytes.getUint8(i + 2);
      final int a = imgBytes.getUint8(i + 3);
      final ui.Color color = ui.Color.fromARGB(a, r, g, b);
      colorList.add(HSVColor.fromColor(color));
    }
    return colorList;
  }

  Future<List<List<HSVColor>>> _adaptiveClusterWithMaxRamps({required final List<HSVColor> colors, required final int initialClusters, required final int maxRamps}) async
  {
    final List<List<HSVColor>> clusters = await _clusterByHue(colors: colors, numClusters: initialClusters);
    final List<List<HSVColor>> finalClusters = <List<HSVColor>>[];
    for (final List<HSVColor> cluster in clusters)
    {
      if (cluster.length >= 2)
      {
        final double variance = await _calculateClusterVariance(cluster: cluster);
        if (variance > 0.05) //TODO magic number
            {
          finalClusters.addAll(await _clusterByHue(colors: cluster, numClusters: 2));
        }
        else
        {
          finalClusters.add(cluster);
        }
      }
      else
      {
        finalClusters.add(cluster);
      }

    }
    finalClusters.removeWhere((final List<HSVColor> element) => element.isEmpty);
    while (finalClusters.length > maxRamps)
    {
      await _mergeMostSimilarClusters(clusters: finalClusters);
    }
    return finalClusters;
  }

  Future<List<List<HSVColor>>> _clusterByHue({required final List<HSVColor> colors, required final int numClusters}) async
  {
    final List<List<HSVColor>> clusters = List<List<HSVColor>>.generate(numClusters, (final _) => <HSVColor>[]);
    for (final HSVColor color in colors)
    {
      final int bucket = (color.hue / 360 * numClusters).floor() % numClusters;
      clusters[bucket].add(color);
    }
    return clusters;
  }

  Future<double> _calculateClusterVariance({required final List<HSVColor> cluster}) async
  {
    final double meanValue = cluster.map((final HSVColor c) => c.value).reduce((final double a, final double b) => a + b) / cluster.length;
    final double variance = cluster.map((final HSVColor c) => pow(c.value - meanValue, 2)).reduce((final num a, final num b) => a + b) / cluster.length;
    return variance;
  }

  Future<void> _mergeMostSimilarClusters({required final List<List<HSVColor>> clusters}) async
  {
    double minDistance = double.infinity;
    int mergeIndex1 = 0;
    int mergeIndex2 = 0;

    for (int i = 0; i < clusters.length; i++)
    {
      for (int j = i + 1; j < clusters.length; j++)
      {
        final double distance = _calculateHueDistance(cluster1: clusters[i], cluster2: clusters[j]);
        if (distance < minDistance) {
          minDistance = distance;
          mergeIndex1 = i;
          mergeIndex2 = j;
        }
      }
    }

    clusters[mergeIndex1].addAll(clusters[mergeIndex2]);
    clusters.removeAt(mergeIndex2);
  }

  double _calculateHueDistance({required final List<HSVColor> cluster1, required final List<HSVColor> cluster2})
  {
    final double avgHue1 = _calculateMeanHue(cluster: cluster1);
    final double avgHue2 = _calculateMeanHue(cluster: cluster2);
    return (avgHue1 - avgHue2).abs();
  }

  double _calculateMeanHue({required final List<HSVColor> cluster})
  {
    final double sumHue = cluster.map((final HSVColor c) => c.hue).reduce((final double a, final double b) => a + b);
    return sumHue / cluster.length;
  }

  Future<List<HSVColor>> _interpolateColorsFromRamp({required final List<HSVColor> ramp, required final int maxColors}) async
  {
    final List<HSVColor> interpolatedColors = <HSVColor>[];
    if (ramp.length == 1)
    {
      final HSVColor singleColor = ramp[0];
      double shift = singleColor.value;
      if (singleColor.value > 0.5)
      {
        shift = 1.0 - singleColor.value;
      }
      final HSVColor darkerColor = HSVColor.fromAHSV(1.0, singleColor.hue, singleColor.saturation, singleColor.value - shift);
      final HSVColor lighterColor = HSVColor.fromAHSV(1.0, singleColor.hue, singleColor.saturation, singleColor.value + shift);
      interpolatedColors.add(darkerColor);
      interpolatedColors.add(singleColor);
      interpolatedColors.add(lighterColor);
    }
    else if (ramp.length == 2)
    {
      final HSVColor darkerColor = ramp[0];
      final HSVColor lighterColor = ramp[1];
      final HSVColor middleColor = _interpolateHSV(c1: darkerColor, c2: lighterColor, t: 0.5, originalRamp: ramp);
      interpolatedColors.add(darkerColor);
      interpolatedColors.add(middleColor);
      interpolatedColors.add(lighterColor);
      return interpolatedColors;
    }
    else if (ramp.length >= 3)
    {
      if ( ramp.length <= maxColors)
      {
        return List<HSVColor>.from(ramp);
      }
      else
      {
        final HSVColor darkestColor = ramp.first;
        final HSVColor lightestColor = ramp.last;
        interpolatedColors.add(darkestColor);

        for (int i = 1; i < maxColors - 1; i++)
        {
          final double factor = i / (maxColors - 1);
          final HSVColor interpolatedColor = _interpolateHSV(c1: darkestColor, c2: lightestColor, t: factor, originalRamp: ramp);
          interpolatedColors.add(interpolatedColor);
        }

        interpolatedColors.add(lightestColor);
      }
    }

    return interpolatedColors;
  }

  HSVColor _interpolateHSV({required final HSVColor c1, required final HSVColor c2, required final double t, required final List<HSVColor> originalRamp})
  {
    final double value = (1 - t) * c1.value + t * c2.value;

    final HSVColor lowerNeighbor = originalRamp.firstWhere((final HSVColor c) => c.value <= value, orElse: () => c1);
    final HSVColor upperNeighbor = originalRamp.lastWhere((final HSVColor c) => c.value >= value, orElse: () => c2);

    final double hue = (1 - t) * lowerNeighbor.hue + t * upperNeighbor.hue;
    final double saturation = (1 - t) * lowerNeighbor.saturation + t * upperNeighbor.saturation;

    return HSVColor.fromAHSV(1.0, hue, saturation, value);
  }
