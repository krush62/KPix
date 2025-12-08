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
      // Extracting ALL colors
      final List<HSVColor> hsvColorList = await _extractColorsFromImage(imgBytes: imageData);
      if (importData.createNewPalette)
      {
        // Create set of DISTINCT colors
        final List<HSVColor> distinctHsvColorList = hsvColorList.toSet().toList(growable: false);
        print("Distinct colors: ${distinctHsvColorList.length}");




        final List<KPalRampSettings> colorRamps = await _extractColorRamps(hsvColorList: distinctHsvColorList, maxRamps: importData.maxRamps, maxColors: importData.maxColors);
        for (final KPalRampSettings colorRamp in colorRamps)
        {
          ramps.add(KPalRampData(uuid: const Uuid().v1(), settings: colorRamp));
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
        final double delta = getDeltaE00(
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

Future<List<KPalRampSettings>> _extractColorRamps({required final List<HSVColor> hsvColorList, required final int maxRamps, required final int maxColors}) async {

  if (hsvColorList.isEmpty) {
    final KPalConstraints constraints = GetIt.I.get<PreferenceManager>().kPalConstraints;
    return <KPalRampSettings>[
      KPalRampSettings(constraints: constraints),
    ];
  }
  else
  {
    // K-means in HSV with circular hue distance.
    final List<_Cluster> clusters = _kMeansHSV(
      hsvColorList,
      k: min(maxRamps, hsvColorList.length),
      maxIter: 30,
      seed: 123456,
      hueWeight: 2.0,
      satWeight: 1.0,
      valWeight: 0.75,
    );

    // Fit a ramp for each cluster.
    final List<KPalRampSettings> rampSettings = <KPalRampSettings>[];
    for (final _Cluster c in clusters) {
      if (c.members.isEmpty) continue;
      final KPalRampSettings ramp = _fitRampForCluster(
        c.members,
        colorCount: maxColors,
      );
      rampSettings.add(ramp);
    }
    return rampSettings;
  }
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

class _Cluster {
  HSVColor center;
  final List<HSVColor> members = [];
  _Cluster(this.center);
}

List<_Cluster> _kMeansHSV(
    List<HSVColor> data, {
      required int k,
      int maxIter = 30,
      double hueWeight = 2.0,
      double satWeight = 1.0,
      double valWeight = 0.75,
      int seed = 1337,
    }) {
  if (data.length <= k)
  {
    return data.map((d) => _Cluster(d)..members.add(d)).toList();
  }

  final rng = Random(seed);

  // k-means++ initialization
  final centers = <HSVColor>[];
  centers.add(data[rng.nextInt(data.length)]);
  while (centers.length < k) {
    final dists = List<double>.filled(data.length, 0.0);
    double sum = 0.0;
    for (int i = 0; i < data.length; i++) {
      final p = data[i];
      double best = double.infinity;
      for (final c in centers) {
        final dist = _hsvWeightedDist2(p, c, hueWeight, satWeight, valWeight);
        if (dist < best) best = dist;
      }
      dists[i] = best;
      sum += best;
    }
    if (sum == 0) break;
    final t = rng.nextDouble() * sum;
    double acc = 0.0;
    for (int i = 0; i < dists.length; i++) {
      acc += dists[i];
      if (acc >= t) {
        centers.add(data[i]);
        break;
      }
    }
    if (centers.length == 1) break;
  }
  while (centers.length < k) {
    centers.add(data[rng.nextInt(data.length)]);
  }

  List<_Cluster> clusters = centers.map((c) => _Cluster(c)).toList();

  for (int iter = 0; iter < maxIter; iter++) {
    for (final c in clusters) {
      c.members.clear();
    }
    for (final p in data) {
      int bestIdx = 0;
      double best = double.infinity;
      for (int i = 0; i < clusters.length; i++) {
        final c = clusters[i].center;
        final dist = _hsvWeightedDist2(p, c, hueWeight, satWeight, valWeight);
        if (dist < best) {
          best = dist;
          bestIdx = i;
        }
      }
      clusters[bestIdx].members.add(p);
    }

    // recompute centers
    bool changed = false;
    for (final c in clusters) {
      if (c.members.isEmpty) continue;
      final newCenter = _meanHSV(c.members);
      if (_hsvWeightedDist2(newCenter, c.center, hueWeight, satWeight, valWeight) > 1e-6) {
        c.center = newCenter;
        changed = true;
      }
    }
    if (!changed) break;
  }
  return clusters.where((c) => c.members.isNotEmpty).toList();
}

double _hsvWeightedDist2(HSVColor a, HSVColor b, double wh, double ws, double wv) {
  final dh = _hueDistanceDeg(a.hue, b.hue) / 180.0; // normalize to 0..1
  final ds = (a.saturation - b.saturation).abs();
  final dv = (a.value - b.value).abs();
  return wh * dh * dh + ws * ds * ds + wv * dv * dv;
}

HSVColor _meanHSV(List<HSVColor> pts) {
  final meanH = _circularMeanDegrees(pts.map((p) => p.hue));
  final meanS = pts.map((p) => p.saturation).reduce((a, b) => a + b) / pts.length;
  final meanV = pts.map((p) => p.value).reduce((a, b) => a + b) / pts.length;
  return HSVColor.fromAHSV(1.0, meanH, meanS, meanV);
}

double _hueDistanceDeg(double h1, double h2) {
  final d = (h1 - h2).abs();
  return d <= 180.0 ? d : 360.0 - d;
}

double _circularMeanDegrees(Iterable<double> degs) {
  double sx = 0.0, sy = 0.0;
  for (final d in degs) {
    final rad = d * pi / 180.0;
    sx += cos(rad);
    sy += sin(rad);
  }
  return (atan2(sy, sx) * 180.0 / pi + 360.0) % 360.0;
}

double _circularMedianDegrees(List<double> degs) {
  // Approximate circular median via projecting to circle and scanning a reference.
  if (degs.isEmpty) return 0.0;
  degs.sort();
  // Try several rotations and pick the rotation minimizing arc length variance.
  double bestMed = degs[degs.length ~/ 2];
  double minSpread = double.infinity;
  for (final ref in [0, 45, 90, 135, 180, 225, 270, 315]) {
    final shifted = degs.map((d) {
      var s = d - ref;
      if (s < 0) s += 360;
      return s;
    }).toList()
      ..sort();
    final med = shifted[shifted.length ~/ 2];
    // map back
    final medBack = (med + ref) % 360;
    // compute dispersion
    double spread = 0;
    for (final d in degs) {
      spread += _hueDistanceDeg(d, medBack);
    }
    if (spread < minSpread) {
      minSpread = spread;
      bestMed = medBack;
    }
  }
  return bestMed;
}


KPalRampSettings _fitRampForCluster(
    List<HSVColor> cluster, {
      required int colorCount,
    }) {
  // Sort by V to define t in [-1, 1]
  final pts = List<HSVColor>.from(cluster)..sort((a, b) => a.value.compareTo(b.value));
  final n = pts.length;

  double _percentileV(double p) {
    if (n == 1) return pts.first.value;
    final idx = (p * (n - 1)).clamp(0.0, (n - 1).toDouble());
    final lo = idx.floor();
    final hi = idx.ceil();
    if (lo == hi) return pts[lo].value;
    final t = idx - lo;
    return pts[lo].value * (1 - t) + pts[hi].value * t;
  }

  final vMin = _percentileV(0.05);
  final vMax = _percentileV(0.95);
  final vMid = _percentileV(0.50);

  // Neighborhood near center to define baseHue/baseSat robustly
  final vWidth = max(0.05, (vMax - vMin) * 0.20); // 20% mid window
  final centerPts = pts.where((p) => (p.value - vMid).abs() <= vWidth / 2).toList();
  final huesCenter = centerPts.isEmpty ? pts.map((p) => p.hue).toList() : centerPts.map((p) => p.hue).toList();
  final satsCenter = centerPts.isEmpty ? pts.map((p) => p.saturation).toList() : centerPts.map((p) => p.saturation).toList();

  final baseHueDeg = _circularMedianDegrees(huesCenter);
  int baseHue = baseHueDeg.round() % 360;
  final baseSatPct = (100.0 * _median(satsCenter)).clamp(0.0, 100.0);
  int baseSat = baseSatPct.round();

  // Build t for points and compute observed hue/sat offsets relative to base.
  final obs = <_Obs>[];
  for (final p in pts) {
    final t = _normalizeToMinusOneToOne(p.value, vMin, vMax);
    // Hue offset: shortest circular difference
    double dh = p.hue - baseHue;
    if (dh > 180) dh -= 360;
    if (dh < -180) dh += 360;
    final ds = (100.0 * p.saturation) - baseSat; // sat offset in percent
    obs.add(_Obs(t: t, hueOffset: dh, satOffset: ds));
  }

  // Fit hue model: offset ≈ sign(t) * (|t|^exp) * A_h
  final hueExpCandidates = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  final hueFit = _fitSignedPowerModel(obs, (o) => o.hueOffset, hueExpCandidates,
      maxAmp: 25.0);

  // Fit sat model with different sat curves
  final satExpCandidates = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  final satFits = <SatCurve, _SignedPowerFit>{};
  for (final curve in SatCurve.values) {
    satFits[curve] = _fitSignedPowerModel(
      obs,
          (o) => o.satOffset,
      satExpCandidates,
      maxAmp: 10.0,
      curve: curve,
    );
  }
  // Choose best sat curve by error
  SatCurve bestCurve = SatCurve.linear;
  double bestCurveErr = double.infinity;
  _SignedPowerFit bestSatFit = satFits[SatCurve.linear]!;
  satFits.forEach((curve, fit) {
    if (fit.error < bestCurveErr) {
      bestCurveErr = fit.error;
      bestCurve = curve;
      bestSatFit = fit;
    }
  });

  // Convert vMin/vMax to 0..100 integer percent
  final valueRangeMin = (vMin * 100).clamp(0.0, 100.0).round();
  final valueRangeMax = (vMax * 100).clamp(0.0, 100.0).round();

  final KPalConstraints constraints = GetIt.I.get<PreferenceManager>().kPalConstraints;
  return KPalRampSettings.fromValues(
    constraints: constraints,
    colorCount: colorCount,
    baseHue: baseHue,
    hueShift: hueFit.amplitude.round().clamp(-25, 25),
    hueShiftExp: hueFit.exp,
    baseSat: baseSat,
    satShift: bestSatFit.amplitude.round().clamp(-10, 10),
    satShiftExp: bestSatFit.exp,
    satCurve: bestCurve,
    valueRangeMin: valueRangeMin,
    valueRangeMax: valueRangeMax,
  );
}

class _Obs {
  final double t;          // [-1, 1]
  final double hueOffset;  // degrees
  final double satOffset;  // percent
  _Obs({required this.t, required this.hueOffset, required this.satOffset});
}

double _normalizeToMinusOneToOne(double v, double vMin, double vMax) {
  if (vMax <= vMin) return 0.0;
  final t01 = ((v - vMin) / (vMax - vMin)).clamp(0.0, 1.0);
  return t01 * 2.0 - 1.0; // to [-1, 1]
}

double _median(Iterable<double> xs) {
  final arr = xs.toList()..sort();
  if (arr.isEmpty) return 0.0;
  final m = arr.length ~/ 2;
  if (arr.length.isOdd) return arr[m];
  return (arr[m - 1] + arr[m]) / 2.0;
}

class _SignedPowerFit {
  final double amplitude;
  final double exp;
  final double error;
  _SignedPowerFit({required this.amplitude, required this.exp, required this.error});
}

/// Model: y ≈ A * f(t, exp, curve) where A is amplitude (can be +/-), exp in [0.5..2.0].
/// We solve A by least squares: A = (Σ y*f) / (Σ f^2), clamp A to ±maxAmp.
/// Returns amplitude, exponent and sum of squared error.
_SignedPowerFit _fitSignedPowerModel(
    List<_Obs> obs,
    double Function(_Obs) getY,
    List<double> expCandidates, {
      required double maxAmp,
      SatCurve curve = SatCurve.linear,
    }) {
  double bestErr = double.infinity;
  double bestA = 0.0;
  double bestExp = 1.0;

  for (final e in expCandidates) {
    double num = 0.0; // Σ y*f
    double den = 0.0; // Σ f^2
    for (final o in obs) {
      final f = _shapeFunction(o.t, e, curve);
      num += getY(o) * f;
      den += f * f;
    }
    if (den < 1e-12) continue;
    double A = num / den;
    A = A.clamp(-maxAmp, maxAmp);
    // compute error
    double err = 0.0;
    for (final o in obs) {
      final f = _shapeFunction(o.t, e, curve);
      final yhat = A * f;
      final diff = getY(o) - yhat;
      err += diff * diff;
    }
    if (err < bestErr) {
      bestErr = err;
      bestA = A;
      bestExp = e;
    }
  }

  return _SignedPowerFit(amplitude: bestA, exp: bestExp, error: bestErr);
}

/// Signed, exponentiated position with optional curve shape.
/// t ∈ [-1, 1]
double _shapeFunction(double t, double exp, SatCurve curve)
{
  final double t2 = t.clamp(-1.0, 1.0);
  switch (curve) {
    case SatCurve.linear:
    // sign(t) * |t|^exp
      return t2 == 0.0 ? 0.0 : (t2.isNegative ? -1.0 : 1.0) * pow(t2.abs(), exp).toDouble();

    case SatCurve.darkFlat:
      if (t2 < 0) return -1.0; // constant
      return pow(t2.abs(), exp).toDouble(); // rising after center

    case SatCurve.brightFlat:
      if (t2 > 0) return 1.0;  // constant
      return -pow(t2.abs(), exp).toDouble(); // rising before center (towards center)

    case SatCurve.noFlat:
    // Peak at center, 0 at ends. Scale to [-1,1] symmetric:
    // triangle(t) = 1 - |t|; signed so it goes positive on both sides? For saturation we want symmetric peak.
    // Use unsigned peak:  (1 - |t|)^exp ∈ [0,1], make it symmetric with sign(t)=0? We'll keep unsigned for sat.
    // For signed power model we allow amplitude to create positive/negative. Since signed is awkward for triangle,
    // we use unsigned and let amplitude carry sign.
      return pow(1.0 - t2.abs(), exp).toDouble();
  }
}
