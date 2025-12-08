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
      final List<KHSV> hsvColorList = await _extractColorsFromImage(imgBytes: imageData);
      if (importData.createNewPalette)
      {
        final List<KPalRampSettings> colorRamps = await _extractColorRamps(imgBytes: imageData, maxRamps: importData.maxRamps, maxColors: importData.maxColors);
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

  Future<DrawingLayerState> _createDrawingLayer({required final List<KHSV> colorList, required final int width, required final int height, required final List<KPalRampData> ramps}) async
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
      final CoordinateSetI coord = CoordinateSetI(x: col, y: row);
      final ColorReference reference = _findClosestColor(hsvColor: colorList[i], ramps: ramps);
      layerContent[coord] = reference;
      col++;
    }
    return DrawingLayerState(size: CoordinateSetI(x: width, y: height), content: layerContent, ramps: ramps);
  }


ColorReference _findClosestColor({required final KHSV hsvColor, required final List<KPalRampData> ramps,})
{
  final Color pixelColor = hsvColor.toColor();

  ColorReference? closestReference;
  double closestDelta = double.infinity;

  for (final KPalRampData ramp in ramps)
  {
    for (final ColorReference reference in ramp.references)
    {
      final Color refColor = reference.getIdColor().color;

      final double delta = getDeltaE00(
        redA: refColor.r,
        greenA: refColor.g,
        blueA: refColor.b,
        redB: pixelColor.r,
        greenB: pixelColor.g,
        blueB: pixelColor.b,
      );

      if (delta < closestDelta) {
        closestReference = reference;
        closestDelta = delta;
      }
    }
  }
  // closestReference is guaranteed non-null if ramps has at least one reference
  return closestReference!;
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



Future<List<KHSV>> _extractColorsFromImage({required final ByteData imgBytes, final int alphaThreshold = 0}) async
{
  final Uint8List u8 = imgBytes.buffer.asUint8List(
    imgBytes.offsetInBytes,
    imgBytes.lengthInBytes,
  );
  final int pixelCount = u8.length ~/ 4;

  final List<KHSV>colors = <KHSV>[];
  for (int i = 0; i < pixelCount; i++)
  {
    final int base = i * 4;
    final int r = u8[base + 0];
    final int g = u8[base + 1];
    final int b = u8[base + 2];
    final int a = u8[base + 3];
    if (a <= alphaThreshold) continue;

    // Inline RGB -> HSV (same math you use elsewhere)
    final double rf = r / 255.0;
    final double gf = g / 255.0;
    final double bf = b / 255.0;
    double maxc = rf;
    double minc = rf;
    if (gf > maxc) maxc = gf; if (bf > maxc) maxc = bf;
    if (gf < minc) minc = gf; if (bf < minc) minc = bf;
    final double delta = maxc - minc;

    double h;
    double s;
    final double v = maxc;
    if (delta == 0.0)
    {
      h = 0.0; s = 0.0;
    }
    else
    {
      s = (maxc == 0.0) ? 0.0 : delta / maxc;
      if (maxc == rf)
      {
        h = 60.0 * (((gf - bf) / delta) % 6.0);
      }
      else if (maxc == gf)
      {
        h = 60.0 * (((bf - rf) / delta) + 2.0);
      }
      else
      {
        h = 60.0 * (((rf - gf) / delta) + 4.0);
      }
      if (h < 0) h += 360.0;
      if (h >= 360.0) h -= 360.0;
    }
    colors.add(KHSV(h: h, s: s, v: v));
  }
  return colors;
}


double _hueDistanceDeg({required final double h1, required final double h2})
{
  final double d = (h1 - h2).abs();
  return d <= 180.0 ? d : 360.0 - d;
}


double _normalizeToMinusOneToOne({required final double v, required final double vMin, required final double vMax})
{
  if (vMax <= vMin) return 0.0;
  final double t01 = ((v - vMin) / (vMax - vMin)).clamp(0.0, 1.0);
  return t01 * 2.0 - 1.0; // to [-1, 1]
}

class _SignedPowerFit {
  final double amplitude;
  final double exp;
  final double error;
  _SignedPowerFit({required this.amplitude, required this.exp, required this.error});
}

/// Signed, exponentiated position with optional curve shape.
/// t ∈ [-1, 1]
double _shapeFunction({required final double t, required final double exp, required final SatCurve curve})
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



class _HSVBin {
  KHSV hsv;
  final int weight;
  _HSVBin(this.hsv, this.weight);
}

class _QuantizeResult {
  final List<_HSVBin> bins;
  final List<int> vHist256; // histogram of V (0..255)
  final int totalPixels;
  _QuantizeResult(this.bins, this.vHist256, this.totalPixels);
}

_QuantizeResult quantizeHSVFromRGBABytes({
      required final ByteData imgBytes,
      final int hBins = 36,
      final int sBins = 16,
      final int vBins = 16,
      final int alphaThreshold = 16,
    }) {
  final Uint8List u8 = imgBytes.buffer.asUint8List(imgBytes.offsetInBytes, imgBytes.lengthInBytes);
  final int pixelCount = u8.lengthInBytes ~/ 4;

  final int binsLen = hBins * sBins * vBins;
  final Int32List counts = Int32List(binsLen);

  final Float64List sumHcos = Float64List(binsLen);
  final Float64List sumHsin = Float64List(binsLen);
  final Float64List sumS = Float64List(binsLen);
  final Float64List sumV = Float64List(binsLen);

  final List<int> vHist256 = List<int>.filled(256, 0);

  int idxOf(final int hi, final int si, final int vi) => (hi * sBins + si) * vBins + vi;

  for (int p = 0; p < pixelCount; p++) {
    final int base = p * 4;
    final int r = u8[base + 0];
    final int g = u8[base + 1];
    final int b = u8[base + 2];
    final int a = u8[base + 3];
    if (a < alphaThreshold) continue;

    // --- RGB -> HSV ---
    final double rf = r / 255.0;
    final double gf = g / 255.0;
    final double bf = b / 255.0;
    final double maxc = max(rf, max(gf, bf));
    final double minc = min(rf, min(gf, bf));
    final double delta = maxc - minc;

    double hDeg;
    double s;
    final double v = maxc;

    if (delta == 0.0) {
      hDeg = 0.0;
      s = 0.0;
    } else {
      s = (maxc == 0.0) ? 0.0 : delta / maxc;
      double hue;
      if (maxc == rf) {
        hue = ((gf - bf) / delta) % 6.0;
      } else if (maxc == gf) {
        hue = ((bf - rf) / delta) + 2.0;
      } else {
        hue = ((rf - gf) / delta) + 4.0;
      }
      hDeg = 60.0 * hue;
      if (hDeg < 0) hDeg += 360.0;
      if (hDeg >= 360.0) hDeg -= 360.0;
    }

    // --- Quantize to bins ---
    final int hi = ((hDeg / 360.0) * hBins).floor().clamp(0, hBins - 1);
    final int si = (s * sBins).floor().clamp(0, sBins - 1);
    final int vi = (v * vBins).floor().clamp(0, vBins - 1);
    final int idx = idxOf(hi, si, vi);

    counts[idx] += 1;
    final double rad = hDeg * pi / 180.0;
    sumHcos[idx] += cos(rad);
    sumHsin[idx] += sin(rad);
    sumS[idx] += s;
    sumV[idx] += v;

    // V histogram (0..255)
    vHist256[(v * 255.0).clamp(0.0, 255.0).toInt()] += 1;
  }

  // Emit non-empty bins as weighted centroids
  final List<_HSVBin> bins = <_HSVBin>[];
  for (int i = 0; i < binsLen; i++) {
    final int w = counts[i];
    if (w == 0) continue;
    final double h = (atan2(sumHsin[i], sumHcos[i]) * 180.0 / pi + 360.0) % 360.0;
    final double s = sumS[i] / w;
    final double v = sumV[i] / w;
    bins.add(_HSVBin(KHSV(h: h, s: s, v: v), w));
  }

  final int total = vHist256.fold<int>(0, (final int a, final int b) => a + b);
  return _QuantizeResult(bins, vHist256, total);
}

double vPercentileFromHist({required final List<int> vHist256, required final int totalPixels, required final double p01}) {
  if (totalPixels <= 0) return 0.0;
  final int target = (p01.clamp(0.0, 1.0) * (totalPixels - 1)).round();
  int acc = 0;
  for (int i = 0; i < 256; i++) {
    acc += vHist256[i];
    if (acc > target) return i / 255.0;
  }
  return 1.0;
}


class _WeightedCluster {
  KHSV center;
  final List<_HSVBin> members = <_HSVBin>[];
  int pixelCount = 0; // sum of weights
  _WeightedCluster(this.center);
}

List<_WeightedCluster> kMeansOnBins({
      required final List<_HSVBin> bins,
      required final int k,
      final int maxIter = 20,
      final double hueWeight = 2.0,
      final double satWeight = 1.0,
      final double valWeight = 0.75,
      final int seed = 1337,
    })
{
  if (bins.isEmpty) return <_WeightedCluster>[];
  if (bins.length <= k)
  {
    final List<_WeightedCluster> cs = bins.map((final _HSVBin b)
    {
      final KHSV c = KHSV.fromOther(other: b.hsv);
      final _WeightedCluster cl = _WeightedCluster(c);
      cl.members.add(b);
      cl.pixelCount = b.weight;
      return cl;
    }).toList();
    cs.sort((final _WeightedCluster a, final _WeightedCluster b) => b.pixelCount.compareTo(a.pixelCount));
    return cs;
  }

  final Random rng = Random(seed);

  // -- k-means++ init weighted by bin counts --
  final List<KHSV> centers = <KHSV>[];
  {
    final int totalW = bins.fold<int>(0, (final int a, final _HSVBin b) => a + b.weight);
    int pick = rng.nextInt(max(1, totalW));
    for (final _HSVBin b in bins)
    {
      pick -= b.weight;
      if (pick <= 0)
      {
        centers.add(KHSV.fromOther(other: b.hsv));
        break;
      }
    }
    if (centers.isEmpty) {
      final _HSVBin b = bins[rng.nextInt(bins.length)];
      centers.add(KHSV.fromOther(other: b.hsv));
    }
  }

  while (centers.length < k)
  {
    final List<double> dists = List<double>.filled(bins.length, 0.0);
    double sum = 0.0;
    for (int i = 0; i < bins.length; i++)
    {
      final _HSVBin p = bins[i];
      double best = double.infinity;
      for (final KHSV c in centers)
      {
        final double dist = _hsvWeightedDist2Bin(a: p, b: c, wh: hueWeight, ws: satWeight, wv: valWeight);
        if (dist < best) best = dist;
      }
      final double wdist = best * best * p.weight; // km++: proportional to dist^2 * weight
      dists[i] = wdist;
      sum += wdist;
    }
    if (sum <= 1e-12) break;
    double t = rng.nextDouble() * sum;
    for (int i = 0; i < dists.length; i++)
    {
      t -= dists[i];
      if (t <= 0)
      {
        final _HSVBin b = bins[i];
        centers.add(KHSV(h: b.hsv.h, s: b.hsv.s, v: b.hsv.v));
        break;
      }
    }
    if (centers.length == 1) break;
  }
  while (centers.length < k)
  {
    final _HSVBin b = bins[rng.nextInt(bins.length)];
    centers.add(KHSV(h: b.hsv.h, s: b.hsv.s, v: b.hsv.v));
  }

  List<_WeightedCluster> clusters = centers.map((final KHSV c) => _WeightedCluster(c)).toList();

  for (int iter = 0; iter < maxIter; iter++)
  {
    for (final _WeightedCluster c in clusters)
    {
      c.members.clear();
      c.pixelCount = 0;
    }
    // Assignment
    for (final _HSVBin p in bins)
    {
      int bestIdx = 0;
      double best = double.infinity;
      for (int i = 0; i < clusters.length; i++)
      {
        final KHSV c = clusters[i].center;
        final double dist = _hsvWeightedDist2Bin(a: p, b: c, wh: hueWeight, ws: satWeight, wv: valWeight);
        if (dist < best) {
          best = dist;
          bestIdx = i;
        }
      }
      final _WeightedCluster cl = clusters[bestIdx];
      cl.members.add(p);
      cl.pixelCount += p.weight;
    }

    // Update centers (weighted means)
    bool changed = false;
    for (final _WeightedCluster cl in clusters)
    {
      if (cl.members.isEmpty) continue;
      final KHSV newCenter = _weightedMeanHSV(pts: cl.members);
      if (_hsvWeightedDist2Hsv(a: newCenter, b: cl.center, wh: hueWeight, ws: satWeight, wv: valWeight) > 1e-6)
      {
        cl.center = newCenter;
        changed = true;
      }
    }
    if (!changed) break;
  }

  clusters = clusters.where((final _WeightedCluster c) => c.members.isNotEmpty).toList();
  clusters.sort((final _WeightedCluster a, final _WeightedCluster b) => b.pixelCount.compareTo(a.pixelCount));
  return clusters;
}

double _hsvWeightedDist2Bin({required final _HSVBin a, required final KHSV b, required final double wh, required final double ws, required final double wv})
{
  final double dh = _hueDistanceDeg(h1: a.hsv.h, h2: b.h) / 180.0;
  final double ds = (a.hsv.s - b.s).abs();
  final double dv = (a.hsv.v - b.v).abs();
  return wh * dh * dh + ws * ds * ds + wv * dv * dv;
}

double _hsvWeightedDist2Hsv({required final KHSV a, required final KHSV b, required final double wh, required final double ws, required final double wv})
{
  final double dh = _hueDistanceDeg(h1: a.h, h2: b.h) / 180.0;
  final double ds = (a.s - b.s).abs();
  final double dv = (a.v - b.v).abs();
  return wh * dh * dh + ws * ds * ds + wv * dv * dv;
}

KHSV _weightedMeanHSV({required final List<_HSVBin> pts})
{
  double sx = 0.0;
  double sy = 0.0;
  double sumW = 0.0;
  double sumS = 0.0;
  double sumV = 0.0;
  for (final _HSVBin p in pts)
  {
    final double w = p.weight.toDouble();
    final double rad = p.hsv.h * pi / 180.0;
    sx += w * cos(rad);
    sy += w * sin(rad);
    sumS += w * p.hsv.s;
    sumV += w * p.hsv.v;
    sumW += w;
  }
  final double meanH = (atan2(sy, sx) * 180.0 / pi + 360.0) % 360.0;
  final double meanS = sumS / sumW;
  final double meanV = sumV / sumW;
  return KHSV(h: meanH, s: meanS, v: meanV);
}



KPalRampSettings _fitRampForClusterBins({
      required final List<_HSVBin> cluster,
      required final int colorCount,

      final int hueShiftMin = -10,
      final int hueShiftMax = 10,
      final int satShiftMin = -20,
      final int satShiftMax = 20,
      final double hueExpMin = 0.75,
      final double hueExpMax = 1.5,
      final double satExpMin = 0.75,
      final double satExpMax = 1.5,

      final List<double>? hueExpCandidatesOverride,
      final List<double>? satExpCandidatesOverride,
    })
{
  // --- Build V histogram for this cluster (0..255) ---
  final List<int> vHist256 = List<int>.filled(256, 0);
  int total = 0;
  for (final _HSVBin p in cluster)
  {
    final int vb = (p.hsv.v * 255.0).clamp(0.0, 255.0).toInt();
    vHist256[vb] += p.weight;
    total += p.weight;
  }
  final double vMin = vPercentileFromHist(vHist256: vHist256, totalPixels: total, p01: 0.05);
  final double vMax = vPercentileFromHist(vHist256: vHist256, totalPixels: total, p01: 0.95);
  final double vMid = vPercentileFromHist(vHist256: vHist256, totalPixels: total, p01: 0.50);

  // --- Robust base hue/sat (weighted means in a window around vMid) ---
  final double vWidth = max(0.05, (vMax - vMin) * 0.20);
  double sx = 0.0;
  double sy = 0.0;
  double sumW = 0.0;
  double sumS = 0.0;
  for (final _HSVBin p in cluster) {
    if ((p.hsv.v - vMid).abs() <= vWidth / 2)
    {
      final double w = p.weight.toDouble();
      final double rad = p.hsv.h * pi / 180.0;
      sx += w * cos(rad);
      sy += w * sin(rad);
      sumS += w * p.hsv.s;
      sumW += w;
    }
  }
  if (sumW == 0.0) {
    for (final _HSVBin p in cluster)
    {
      final double w = p.weight.toDouble();
      final double rad = p.hsv.h * pi / 180.0;
      sx += w * cos(rad);
      sy += w * sin(rad);
      sumS += w * p.hsv.s;
      sumW += w;
    }
  }
  final double baseHueDeg = (atan2(sy, sx) * 180.0 / pi + 360.0) % 360.0;
  final int baseHue = baseHueDeg.round() % 360;
  final double baseSatPct = (100.0 * (sumS / sumW)).clamp(0.0, 100.0);
  final int baseSat = baseSatPct.round();

  // --- Observations (weighted) ---
  final List<_ObsWeighted> obs = <_ObsWeighted>[];
  for (final _HSVBin p in cluster)
  {
    final double t = _normalizeToMinusOneToOne(v: p.hsv.v, vMin: vMin, vMax: vMax);
    double dh = p.hsv.h - baseHue;
    if (dh > 180) dh -= 360;
    if (dh < -180) dh += 360;
    final double ds = (100.0 * p.hsv.s) - baseSat;
    obs.add(_ObsWeighted(t: t, hueOffset: dh, satOffset: ds, w: p.weight.toDouble()));
  }

  // --- Build exponent candidate sets within requested ranges ---
  const List<double> defaultExpCandidates = <double>[0.75, 1.0, 1.25, 1.5];

  List<double> filterCandidates({required final List<double> cands, required final double minE, required final double maxE})
  {
    final List<double> filtered = cands.where((final double e) => e >= minE && e <= maxE).toList()..sort();
    // Fallback: if nothing is inside range, include the bounds themselves.
    if (filtered.isEmpty)
    {
      filtered.add(minE);
      if (maxE != minE) filtered.add(maxE);
    }
    return filtered;
  }

  final List<double> hueExpCandidates = filterCandidates(
    cands: hueExpCandidatesOverride ?? defaultExpCandidates,
    minE: hueExpMin,
    maxE: hueExpMax,
  );
  final List<double> satExpCandidates = filterCandidates(
    cands: satExpCandidatesOverride ?? defaultExpCandidates,
    minE: satExpMin,
    maxE: satExpMax,
  );

  // --- Fit hue model: offset ≈ sign(t) * |t|^exp * A_h ---
  final _SignedPowerFit hueFit = _fitSignedPowerModelWeighted(
    obs: obs,
    getY: (final _ObsWeighted o) => o.hueOffset,
    expCandidates: hueExpCandidates,
    // Use the passed amplitude limits; maxAmp bounds the solver, final clamp enforces integer limit.
    maxAmp: max(hueShiftMax.abs(), hueShiftMin.abs()).toDouble(),
    //curve: SatCurve.linear,
  );

  // --- Fit sat model across SatCurve choices ---
  final Map<SatCurve, _SignedPowerFit> satFits = <SatCurve, _SignedPowerFit>{};
  for (final SatCurve curve in SatCurve.values)
  {
    satFits[curve] = _fitSignedPowerModelWeighted(
      obs: obs,
      getY: (final _ObsWeighted o) => o.satOffset,
      expCandidates: satExpCandidates,
      maxAmp: max(satShiftMax.abs(), satShiftMin.abs()).toDouble(),
      curve: curve,
    );
  }

  SatCurve bestCurve = SatCurve.linear;
  double bestCurveErr = double.infinity;
  _SignedPowerFit bestSatFit = satFits[SatCurve.linear]!;
  satFits.forEach((final SatCurve curve, final _SignedPowerFit fit)
  {
    if (fit.error < bestCurveErr)
    {
      bestCurveErr = fit.error;
      bestCurve = curve;
      bestSatFit = fit;
    }
  });

  // --- Final clamping of results to requested limits ---
  final double hueExp = hueFit.exp.clamp(hueExpMin, hueExpMax);
  final double satExp = bestSatFit.exp.clamp(satExpMin, satExpMax);
  final int hueShift = hueFit.amplitude.round().clamp(hueShiftMin, hueShiftMax);
  final int satShift = bestSatFit.amplitude.round().clamp(satShiftMin, satShiftMax);

  // Value range as before
  final int valueRangeMin = (vMin * 100).clamp(0.0, 100.0).round();
  final int valueRangeMax = (vMax * 100).clamp(0.0, 100.0).round();

  final KPalConstraints constraints = GetIt.I.get<PreferenceManager>().kPalConstraints;
  return KPalRampSettings.fromValues(
    constraints: constraints,
    colorCount: colorCount,
    baseHue: baseHue,
    hueShift: hueShift,
    hueShiftExp: hueExp,
    baseSat: baseSat,
    satShift: satShift,
    satShiftExp: satExp,
    satCurve: bestCurve,
    valueRangeMin: valueRangeMin,
    valueRangeMax: valueRangeMax,
  );
}


class _ObsWeighted {
  final double t;          // [-1, 1]
  final double hueOffset;  // degrees
  final double satOffset;  // percent
  final double w;          // weight
  _ObsWeighted({required this.t, required this.hueOffset, required this.satOffset, required this.w});
}

// Weighted version of your signed-power fit
_SignedPowerFit _fitSignedPowerModelWeighted({
      required final List<_ObsWeighted> obs,
      required final double Function(_ObsWeighted) getY,
      required final List<double> expCandidates,
      required final double maxAmp,
      final SatCurve curve = SatCurve.linear,
    }) {
  double bestErr = double.infinity;
  double bestA = 0.0;
  double bestExp = 1.0;

  for (final double e in expCandidates)
  {
    double num = 0.0; // Σ w * y * f
    double den = 0.0; // Σ w * f^2
    for (final _ObsWeighted o in obs)
    {
      final double f = _shapeFunction(t: o.t, exp: e, curve: curve);
      num += o.w * getY(o) * f;
      den += o.w * f * f;
    }
    if (den < 1e-12) continue;
    double A = num / den;
    A = A.clamp(-maxAmp, maxAmp);

    double err = 0.0;
    for (final _ObsWeighted o in obs)
    {
      final double f = _shapeFunction(t: o.t, exp: e, curve: curve);
      final double yhat = A * f;
      final double diff = getY(o) - yhat;
      err += o.w * diff * diff;
    }
    if (err < bestErr) {
      bestErr = err;
      bestA = A;
      bestExp = e;
    }
  }
  return _SignedPowerFit(amplitude: bestA, exp: bestExp, error: bestErr);
}


Future<List<KPalRampSettings>> _extractColorRamps({
  required final ByteData imgBytes,
  required final int maxRamps,
  required final int maxColors,
}) async {
  final _QuantizeResult q = quantizeHSVFromRGBABytes(
    imgBytes: imgBytes,
  );
  if (q.bins.isEmpty) {
    final KPalConstraints constraints = GetIt.I.get<PreferenceManager>().kPalConstraints;
    return <KPalRampSettings>[
      KPalRampSettings(constraints: constraints),
    ];
  }

  // Cluster only on the (small) set of bin centroids
  final List<_WeightedCluster> clusters = kMeansOnBins(
    bins: q.bins,
    k: min(maxRamps, q.bins.length),
  );

  // Fit ramps per weighted cluster
  final List<KPalRampSettings> rampSettings = <KPalRampSettings>[];
  for (final _WeightedCluster c in clusters) {
    if (c.members.isEmpty) continue;
    final KPalRampSettings ramp = _fitRampForClusterBins(
      cluster: c.members,
      colorCount: maxColors,
    );
    rampSettings.add(ramp);
  }
  return rampSettings;
}
