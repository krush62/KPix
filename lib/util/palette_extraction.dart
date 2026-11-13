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
import 'dart:math';
import 'dart:typed_data';

import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/history/history_shift_set.dart';
import 'package:kpix/models/palette_codec.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/pixel_grid.dart';
import 'package:material_ui/material_ui.dart';

//finds color ramps for an image and matches pixels against a palette; both run on background isolates

const int _fullCircle = 360;

const int _halfCircle = 180;

const int _byteLength = 255;

/// A pixel counts as opaque from this alpha on, for the palette as well as for the matched pixels.
const int importAlphaThreshold = 128;

class PaletteLab
{
  final Uint16List codes;
  final Float64List labs;

  PaletteLab({required this.codes, required this.labs});

  factory PaletteLab.fromRamps({required final List<KPalRampData> ramps})
  {
    final List<int> codes = <int>[];
    final List<double> labs = <double>[];
    for (int rampIndex = 0; rampIndex < ramps.length; rampIndex++)
    {
      final List<ColorReference> references = ramps[rampIndex].references;
      for (int colorIndex = 0; colorIndex < references.length; colorIndex++)
      {
        final Color refColor = references[colorIndex].getIdColor().color;
        final LabColor lab = rgb2lab(r: refColor.r, g: refColor.g, b: refColor.b);
        codes.add(PaletteCodec.codeOf(rampIndex: rampIndex, colorIndex: colorIndex));
        labs..add(lab.L)..add(lab.A)..add(lab.B);
      }
    }
    return PaletteLab(codes: Uint16List.fromList(codes), labs: Float64List.fromList(labs));
  }

  int get length
  {
    return codes.length;
  }

  /// The index of the palette color closest to [lab] by ΔE00, and how far away it is.
  ({int index, double delta}) nearest({required final LabColor lab})
  {
    int closest = 0;
    double closestDelta = double.infinity;
    for (int i = 0; i < codes.length; i++)
    {
      final int base = i * 3;
      final double delta = getDeltaE00Lab(labA: LabColor(L: labs[base], A: labs[base + 1], B: labs[base + 2]), labB: lab);
      if (delta < closestDelta)
      {
        closest = i;
        closestDelta = delta;
      }
    }
    return (index: closest, delta: closestDelta);
  }

  /// Like [nearest], but by plain Lab distance (ΔE76), which is far cheaper to work out.
  ({int index, double delta}) nearestByLabDistance({required final LabColor lab})
  {
    int closest = 0;
    double closestSquared = double.infinity;
    for (int i = 0; i < codes.length; i++)
    {
      final int base = i * 3;
      final double dL = labs[base] - lab.L;
      final double dA = labs[base + 1] - lab.A;
      final double dB = labs[base + 2] - lab.B;
      final double squared = dL * dL + dA * dA + dB * dB;
      if (squared < closestSquared)
      {
        closest = i;
        closestSquared = squared;
      }
    }
    return (index: closest, delta: sqrt(closestSquared));
  }
}

/// A ramp found in an image: its settings plus the per-color shifts that pull its swatches onto the image's colors.
class ExtractedRamp
{
  final KPalRampSettings settings;
  final List<HistoryShiftSet> shifts;
  const ExtractedRamp({required this.settings, required this.shifts});
}

PixelGrid matchImageToPalette({required final Uint8List imgBytes, required final int width, required final int height, required final PaletteLab palette, final int alphaThreshold = importAlphaThreshold})
{
  final PixelGrid pixels = PixelGrid(width: width, height: height);
  if (palette.length == 0)
  {
    return pixels;
  }
  final HashMap<int, int> codeOfColor = HashMap<int, int>();
  final int pixelCount = imgBytes.length ~/ 4;
  for (int i = 0; i < pixelCount; i++)
  {
    final int base = i * 4;
    if (imgBytes[base + 3] < alphaThreshold) continue;
    final int r = imgBytes[base];
    final int g = imgBytes[base + 1];
    final int b = imgBytes[base + 2];
    final int code = codeOfColor[(r << 16) | (g << 8) | b] ??= _closestCode(r: r, g: g, b: b, palette: palette);
    pixels.set(x: i % width, y: i ~/ width, value: code);
  }
  return pixels;
}

int _closestCode({required final int r, required final int g, required final int b, required final PaletteLab palette})
{
  final LabColor pixelLab = rgb2lab(r: r / _byteLength, g: g / _byteLength, b: b / _byteLength);
  return palette.codes[palette.nearest(lab: pixelLab).index];
}

double _signedHueDelta({required final double delta})
{
  return ((delta + _halfCircle) % _fullCircle) - _halfCircle;
}

double _normalizeToMinusOneToOne({required final double v, required final double vMin, required final double vMax})
{
  if (vMax <= vMin) return 0.0;
  final double t01 = ((v - vMin) / (vMax - vMin)).clamp(0.0, 1.0);
  return t01 * 2.0 - 1.0; // to [-1, 1]
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
      required final Uint8List imgBytes,
      final int hBins = 36,
      final int sBins = 16,
      final int vBins = 16,
      final int alphaThreshold = importAlphaThreshold,
    }) {
  final Uint8List u8 = imgBytes;
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
    final double rf = r / _byteLength;
    final double gf = g / _byteLength;
    final double bf = b / _byteLength;
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
      if (hDeg < 0) hDeg += _fullCircle;
      if (hDeg >= _fullCircle) hDeg -= _fullCircle;
    }

    // --- Quantize to bins ---
    final int hi = ((hDeg / _fullCircle) * hBins).floor().clamp(0, hBins - 1);
    final int si = (s * sBins).floor().clamp(0, sBins - 1);
    final int vi = (v * vBins).floor().clamp(0, vBins - 1);
    final int idx = idxOf(hi, si, vi);

    counts[idx] += 1;
    final double rad = hDeg * pi / _halfCircle;
    sumHcos[idx] += cos(rad);
    sumHsin[idx] += sin(rad);
    sumS[idx] += s;
    sumV[idx] += v;

    // V histogram (0..255)
    vHist256[(v * _byteLength).clamp(0.0, _byteLength).toInt()] += 1;
  }

  // Emit non-empty bins as weighted centroids
  final List<_HSVBin> bins = <_HSVBin>[];
  for (int i = 0; i < binsLen; i++) {
    final int w = counts[i];
    if (w == 0) continue;
    final double h = (atan2(sumHsin[i], sumHcos[i]) * _halfCircle / pi + _fullCircle) % _fullCircle;
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
    if (acc > target) return i / _byteLength;
  }
  return 1.0;
}

class _WeightedCluster
{
  final List<_HSVBin> members = <_HSVBin>[];
  int pixelCount = 0; // sum of weights
}

/// A random index, picked with a probability proportional to its weight; zero weights are never picked.
int _pickWeighted({required final Random rng, required final Float64List weights, required final double total})
{
  double target = rng.nextDouble() * total;
  int lastPositive = 0;
  for (int i = 0; i < weights.length; i++)
  {
    if (weights[i] <= 0.0) continue;
    if (target < weights[i]) return i;
    target -= weights[i];
    lastPositive = i;
  }
  return lastPositive;
}

/// Clusters on the HSV cylinder's chroma plane plus a lightly weighted value, so hue only counts as far as a color is
/// saturated: greys end up together instead of with the reds, and a ramp's dark and bright end stay in one cluster.
List<_WeightedCluster> kMeansOnBins({
      required final List<_HSVBin> bins,
      required final int k,
      final int maxIter = 30,
      final double valWeight = 0.3,
      final int seed = 1337,
    })
{
  if (bins.isEmpty || k <= 0) return <_WeightedCluster>[];
  final int n = bins.length;
  final Float64List features = Float64List(n * 3);
  final double vScale = sqrt(valWeight);
  for (int i = 0; i < n; i++)
  {
    final KHSV c = bins[i].hsv;
    final double rad = c.h * pi / _halfCircle;
    features[i * 3] = c.s * cos(rad);
    features[i * 3 + 1] = c.s * sin(rad);
    features[i * 3 + 2] = c.v * vScale;
  }
  final Float64List weights = Float64List(n);
  double totalWeight = 0.0;
  for (int i = 0; i < n; i++)
  {
    weights[i] = bins[i].weight.toDouble();
    totalWeight += weights[i];
  }

  final int maxCenters = min(k, n);
  final Float64List centers = Float64List(maxCenters * 3);
  double dist2(final int bin, final int center)
  {
    final double d0 = features[bin * 3] - centers[center * 3];
    final double d1 = features[bin * 3 + 1] - centers[center * 3 + 1];
    final double d2 = features[bin * 3 + 2] - centers[center * 3 + 2];
    return d0 * d0 + d1 * d1 + d2 * d2;
  }

  // k-means++ seeding, weighted by pixel count
  final Random rng = Random(seed);
  int centerCount = 0;
  void addCenter(final int bin)
  {
    centers[centerCount * 3] = features[bin * 3];
    centers[centerCount * 3 + 1] = features[bin * 3 + 1];
    centers[centerCount * 3 + 2] = features[bin * 3 + 2];
    centerCount++;
  }
  addCenter(_pickWeighted(rng: rng, weights: weights, total: totalWeight));
  final Float64List nearest = Float64List(n)..fillRange(0, n, double.infinity);
  final Float64List seedWeights = Float64List(n);
  while (centerCount < maxCenters)
  {
    double sum = 0.0;
    for (int i = 0; i < n; i++)
    {
      nearest[i] = min(nearest[i], dist2(i, centerCount - 1));
      seedWeights[i] = nearest[i] * weights[i];
      sum += seedWeights[i];
    }
    //every bin sits on a center already
    if (sum <= 1e-12) break;
    addCenter(_pickWeighted(rng: rng, weights: seedWeights, total: sum));
  }

  final Int32List assignment = Int32List(n)..fillRange(0, n, -1);
  final Float64List sums = Float64List(centerCount * 4);
  for (int iter = 0; iter < maxIter; iter++)
  {
    bool changed = false;
    for (int i = 0; i < n; i++)
    {
      int best = 0;
      double bestDist = double.infinity;
      for (int c = 0; c < centerCount; c++)
      {
        final double d = dist2(i, c);
        if (d < bestDist)
        {
          bestDist = d;
          best = c;
        }
      }
      if (assignment[i] != best)
      {
        assignment[i] = best;
        changed = true;
      }
    }
    if (!changed) break;
    sums.fillRange(0, sums.length, 0.0);
    for (int i = 0; i < n; i++)
    {
      final int c = assignment[i];
      sums[c * 4] += features[i * 3] * weights[i];
      sums[c * 4 + 1] += features[i * 3 + 1] * weights[i];
      sums[c * 4 + 2] += features[i * 3 + 2] * weights[i];
      sums[c * 4 + 3] += weights[i];
    }
    for (int c = 0; c < centerCount; c++)
    {
      final double w = sums[c * 4 + 3];
      if (w <= 0.0) continue;
      centers[c * 3] = sums[c * 4] / w;
      centers[c * 3 + 1] = sums[c * 4 + 1] / w;
      centers[c * 3 + 2] = sums[c * 4 + 2] / w;
    }
  }

  final List<_WeightedCluster> clusters = List<_WeightedCluster>.generate(centerCount, (final int _) => _WeightedCluster());
  for (int i = 0; i < n; i++)
  {
    final _WeightedCluster cluster = clusters[assignment[i]];
    cluster.members.add(bins[i]);
    cluster.pixelCount += bins[i].weight;
  }
  clusters.removeWhere((final _WeightedCluster c) => c.members.isEmpty);
  clusters.sort((final _WeightedCluster a, final _WeightedCluster b) => b.pixelCount.compareTo(a.pixelCount));
  return clusters;
}

class _LinearFit
{
  final double offset;
  final double amplitude;
  final double error;
  const _LinearFit({required this.offset, required this.amplitude, required this.error});
}

const _LinearFit _noFit = _LinearFit(offset: 0.0, amplitude: 0.0, error: double.infinity);

/// Weighted least squares for y = offset + amplitude * f, with |amplitude| <= [maxAmplitude].
_LinearFit _fitLinear({required final List<double> f, required final List<double> y, required final List<double> w, required final double maxAmplitude})
{
  double sw = 0.0;
  double sf = 0.0;
  double sff = 0.0;
  double sy = 0.0;
  double sfy = 0.0;
  for (int i = 0; i < f.length; i++)
  {
    sw += w[i];
    sf += w[i] * f[i];
    sff += w[i] * f[i] * f[i];
    sy += w[i] * y[i];
    sfy += w[i] * f[i] * y[i];
  }
  if (sw <= 0.0) return _noFit;
  final double det = sw * sff - sf * sf;
  final double amplitude = (det.abs() < 1e-12 ? 0.0 : (sw * sfy - sf * sy) / det).clamp(-maxAmplitude, maxAmplitude);
  final double offset = (sy - amplitude * sf) / sw;
  double error = 0.0;
  for (int i = 0; i < f.length; i++)
  {
    final double d = y[i] - offset - amplitude * f[i];
    error += w[i] * d * d;
  }
  return _LinearFit(offset: offset, amplitude: amplitude, error: error);
}

List<double> _exponentCandidates({required final double minExp, required final double maxExp})
{
  const double step = 0.1;
  final int count = ((maxExp - minExp) / step).round() + 1;
  return <double>[for (int i = 0; i < count; i++) ((minExp + i * step) * 100).round() / 100];
}

// The shapes below mirror KPalRampData.updateColors: for t from -1 (darkest) to 1 (brightest) they give the color's
// shift as a fraction of the shift at the ramp's ends.

double _hueShape({required final double t, required final double exp})
{
  return t == 0.0 ? 0.0 : t.sign * pow(t.abs(), exp).toDouble();
}

double _satShape({required final double t, required final double exp, required final SatCurve curve})
{
  return switch (curve)
  {
    SatCurve.noFlat => pow(t.abs(), exp).toDouble(),
    SatCurve.darkFlat => t > 0.0 ? pow(t, exp).toDouble() : 0.0,
    SatCurve.brightFlat => t < 0.0 ? pow(-t, exp).toDouble() : 0.0,
    SatCurve.linear => t == 0.0 ? 0.0 : -t.sign * pow(t.abs(), exp).toDouble(),
  };
}

KPalRampSettings _fitRampForClusterBins({required final List<_HSVBin> cluster, required final int colorCount})
{
  // --- Value range from the cluster's V histogram ---
  final List<int> vHist256 = List<int>.filled(_byteLength + 1, 0);
  int total = 0;
  for (final _HSVBin p in cluster)
  {
    final int vb = (p.hsv.v * _byteLength).clamp(0.0, _byteLength).toInt();
    vHist256[vb] += p.weight;
    total += p.weight;
  }
  final double vMin = vPercentileFromHist(vHist256: vHist256, totalPixels: total, p01: 0.05);
  final double vMax = vPercentileFromHist(vHist256: vHist256, totalPixels: total, p01: 0.95);

  // --- Reference hue: circular mean, weighted by chroma since grey pixels have no meaningful hue ---
  double sx = 0.0;
  double sy = 0.0;
  for (final _HSVBin p in cluster)
  {
    final double w = p.weight * p.hsv.s * p.hsv.v;
    final double rad = p.hsv.h * pi / _halfCircle;
    sx += w * cos(rad);
    sy += w * sin(rad);
  }
  final double hueRef = (sx == 0.0 && sy == 0.0) ? 0.0 : (atan2(sy, sx) * _halfCircle / pi + _fullCircle) % _fullCircle;

  final List<double> positions = <double>[];
  final List<double> hueOffsets = <double>[];
  final List<double> hueWeights = <double>[];
  final List<double> sats = <double>[];
  final List<double> satWeights = <double>[];
  for (final _HSVBin p in cluster)
  {
    positions.add(_normalizeToMinusOneToOne(v: p.hsv.v, vMin: vMin, vMax: vMax));
    hueOffsets.add(_signedHueDelta(delta: p.hsv.h - hueRef));
    hueWeights.add(p.weight * p.hsv.s * p.hsv.v);
    sats.add(100.0 * p.hsv.s);
    satWeights.add(p.weight.toDouble());
  }

  // updateColors shifts a color by perStepShift * exp * steps^exp, so the outermost color moves by perStepShift * endFactor
  final double endSteps = (colorCount - 1) / 2.0;
  double endFactor(final double exp) => exp * pow(endSteps, exp).toDouble();

  _LinearFit hueFit = _noFit;
  double hueExp = KPalConstraints.hueShiftExpLimits.defaultValue;
  for (final double exp in _exponentCandidates(minExp: KPalConstraints.hueShiftExpLimits.min, maxExp: KPalConstraints.hueShiftExpLimits.max))
  {
    final _LinearFit fit = _fitLinear(
      f: <double>[for (final double t in positions) _hueShape(t: t, exp: exp)],
      y: hueOffsets,
      w: hueWeights,
      maxAmplitude: KPalConstraints.hueShiftLimits.max * endFactor(exp),
    );
    if (fit.error < hueFit.error)
    {
      hueFit = fit;
      hueExp = exp;
    }
  }

  _LinearFit satFit = _noFit;
  double satExp = KPalConstraints.satShiftExpLimits.defaultValue;
  SatCurve satCurve = KPalConstraints.satCurveDefault;
  for (final SatCurve curve in SatCurve.values)
  {
    for (final double exp in _exponentCandidates(minExp: KPalConstraints.satShiftExpLimits.min, maxExp: KPalConstraints.satShiftExpLimits.max))
    {
      final _LinearFit fit = _fitLinear(
        f: <double>[for (final double t in positions) _satShape(t: t, exp: exp, curve: curve)],
        y: sats,
        w: satWeights,
        maxAmplitude: KPalConstraints.satShiftLimits.max * endFactor(exp),
      );
      //a curve has to be clearly better to win, so flat data keeps the default curve
      if (fit.error < satFit.error - 1e-9)
      {
        satFit = fit;
        satExp = exp;
        satCurve = curve;
      }
    }
  }

  return KPalRampSettings.fromValues(
    colorCount: colorCount,
    baseHue: (hueRef + hueFit.offset).round() % _fullCircle,
    hueShift: KPalConstraints.hueShiftLimits.clamp((hueFit.amplitude / endFactor(hueExp)).round()),
    hueShiftExp: hueExp,
    baseSat: KPalConstraints.baseSatLimits.clamp((satFit.error.isFinite ? satFit.offset : KPalConstraints.baseSatLimits.defaultValue.toDouble()).round()),
    satShift: KPalConstraints.satShiftLimits.clamp((satFit.amplitude / endFactor(satExp)).round()),
    satShiftExp: satExp,
    satCurve: satCurve,
    valueRangeMin: (vMin * 100).clamp(0.0, 100.0).round(),
    valueRangeMax: (vMax * 100).clamp(0.0, 100.0).round(),
  );
}

/// Below this saturation or value a color's hue is noise, so refinement leaves its hue shift alone.
const double _hueNoiseLimit = 0.04;

/// The bins' centroid colors, worked out once for all refinement steps.
class _BinColors
{
  final Float64List rgb;
  final List<LabColor> labs;

  _BinColors._({required this.rgb, required this.labs});

  factory _BinColors.of({required final List<_HSVBin> bins})
  {
    final Float64List rgb = Float64List(bins.length * 3);
    final List<LabColor> labs = <LabColor>[];
    for (int i = 0; i < bins.length; i++)
    {
      final Color c = bins[i].hsv.toColor();
      rgb[i * 3] = c.r * _byteLength;
      rgb[i * 3 + 1] = c.g * _byteLength;
      rgb[i * 3 + 2] = c.b * _byteLength;
      labs.add(rgb2lab(r: c.r, g: c.g, b: c.b));
    }
    return _BinColors._(rgb: rgb, labs: labs);
  }
}

/// Lloyd steps that respect the ramp model: every swatch moves toward the mean color of the bins closest to it, through
/// its per-color shift sliders. Closeness is plain Lab distance, which suits a mean and keeps the search fast.
void _refineShifts({required final List<KPalRampData> ramps, required final List<_HSVBin> bins, required final _BinColors colors, final int iterations = 4})
{
  for (int iter = 0; iter < iterations; iter++)
  {
    final PaletteLab palette = PaletteLab.fromRamps(ramps: ramps);
    final Float64List sums = Float64List(palette.length * 4);
    for (int i = 0; i < bins.length; i++)
    {
      final int p = palette.nearestByLabDistance(lab: colors.labs[i]).index;
      final double w = bins[i].weight.toDouble();
      sums[p * 4] += colors.rgb[i * 3] * w;
      sums[p * 4 + 1] += colors.rgb[i * 3 + 1] * w;
      sums[p * 4 + 2] += colors.rgb[i * 3 + 2] * w;
      sums[p * 4 + 3] += w;
    }
    for (int p = 0; p < palette.length; p++)
    {
      final double w = sums[p * 4 + 3];
      if (w <= 0.0) continue;
      final int code = palette.codes[p];
      final KPalRampData ramp = ramps[PaletteCodec.rampIndexOf(code: code)];
      final int colorIndex = PaletteCodec.colorIndexOf(code: code);
      final KHSV target = KHSV.fromRgb(r: (sums[p * 4] / w).round(), g: (sums[p * 4 + 1] / w).round(), b: (sums[p * 4 + 2] / w).round());
      final KHSV base = ramp.baseColors[colorIndex];
      final ShiftSet shift = ramp.shifts[colorIndex];
      if (target.s >= _hueNoiseLimit && target.v >= _hueNoiseLimit)
      {
        shift.hueShiftNotifier.value = KPalSliderConstraints.hueLimits.clamp(_signedHueDelta(delta: target.h - base.h).round());
      }
      shift.satShiftNotifier.value = KPalSliderConstraints.satLimits.clamp(((target.s - base.s) * 100).round());
      shift.valShiftNotifier.value = KPalSliderConstraints.valLimits.clamp(((target.v - base.v) * 100).round());
    }
  }
}

/// Fits one ramp per cluster, then refines the swatches against all [bins].
List<KPalRampData> _fitRamps({required final List<List<_HSVBin>> members, required final List<int> colorCounts, required final List<_HSVBin> bins, required final _BinColors colors})
{
  final List<KPalRampData> ramps = <KPalRampData>[
    for (int i = 0; i < members.length; i++) KPalRampData(uuid: "extracted-$i", settings: _fitRampForClusterBins(cluster: members[i], colorCount: colorCounts[i])),
  ];
  _refineShifts(ramps: ramps, bins: bins, colors: colors);
  return ramps;
}

/// How well a palette matches [bins]: the pixel-weighted mean Lab distance to the closest swatches and the distance that
/// 95% of the pixels stay within. The mean alone would let a small area lose its color behind many well matched pixels.
({double mean, double p95}) _matchError({required final List<KPalRampData> ramps, required final List<_HSVBin> bins, required final _BinColors colors})
{
  final PaletteLab palette = PaletteLab.fromRamps(ramps: ramps);
  final List<({double delta, int weight})> deltas = <({double delta, int weight})>[];
  double sum = 0.0;
  int weight = 0;
  for (int i = 0; i < bins.length; i++)
  {
    final double delta = palette.nearestByLabDistance(lab: colors.labs[i]).delta;
    deltas.add((delta: delta, weight: bins[i].weight));
    sum += delta * bins[i].weight;
    weight += bins[i].weight;
  }
  if (weight == 0) return (mean: 0.0, p95: 0.0);
  deltas.sort((final ({double delta, int weight}) a, final ({double delta, int weight}) b) => a.delta.compareTo(b.delta));
  final double target = weight * 0.95;
  double p95 = deltas.last.delta;
  int accumulated = 0;
  for (final ({double delta, int weight}) d in deltas)
  {
    accumulated += d.weight;
    if (accumulated >= target)
    {
      p95 = d.delta;
      break;
    }
  }
  return (mean: sum / weight, p95: p95);
}

// A smaller palette is good enough when both its mean and its 95th percentile distance stay within this factor of the
// largest palette's, plus some slack.
const double _countTolerance = 1.15;
const double _meanSlack = 0.15;
const double _p95Slack = 0.5;

bool _closeEnough({required final ({double mean, double p95}) error, required final ({double mean, double p95}) best})
{
  return error.mean <= best.mean * _countTolerance + _meanSlack && error.p95 <= best.p95 * _countTolerance + _p95Slack;
}

List<List<_HSVBin>> _clusterMembers({required final List<_HSVBin> bins, required final int k})
{
  return <List<_HSVBin>>[for (final _WeightedCluster c in kMeansOnBins(bins: bins, k: k)) c.members];
}

/// The fewest colors a ramp needs to match [cluster] about as well as [maxColors] of them.
int _fewestColors({required final List<_HSVBin> cluster, required final int maxColors})
{
  final _BinColors colors = _BinColors.of(bins: cluster);
  ({double mean, double p95}) errorWith(final int colorCount)
  {
    final List<KPalRampData> ramps = _fitRamps(members: <List<_HSVBin>>[cluster], colorCounts: <int>[colorCount], bins: cluster, colors: colors);
    return _matchError(ramps: ramps, bins: cluster, colors: colors);
  }
  final ({double mean, double p95}) best = errorWith(maxColors);
  for (int colorCount = KPalConstraints.colorCountLimits.min; colorCount < maxColors; colorCount++)
  {
    if (_closeEnough(error: errorWith(colorCount), best: best)) return colorCount;
  }
  return maxColors;
}

/// The smallest palette that matches the image about as well as [maxRamps] ramps of [maxColors] colors: first the
/// fewest ramps, then ramp by ramp the fewest colors, as long as the whole palette still passes.
List<KPalRampData> _smallestRamps({required final List<_HSVBin> bins, required final _BinColors colors, required final int maxRamps, required final int maxColors})
{
  List<KPalRampData> fitFull(final List<List<_HSVBin>> members) => _fitRamps(members: members, colorCounts: List<int>.filled(members.length, maxColors), bins: bins, colors: colors);
  final List<List<_HSVBin>> full = _clusterMembers(bins: bins, k: maxRamps);
  final List<KPalRampData> fullRamps = fitFull(full);
  final ({double mean, double p95}) best = _matchError(ramps: fullRamps, bins: bins, colors: colors);

  List<List<_HSVBin>> members = full;
  List<KPalRampData> ramps = fullRamps;
  for (int k = 1; k < full.length; k++)
  {
    final List<List<_HSVBin>> candidate = _clusterMembers(bins: bins, k: k);
    final List<KPalRampData> candidateRamps = fitFull(candidate);
    if (_closeEnough(error: _matchError(ramps: candidateRamps, bins: bins, colors: colors), best: best))
    {
      members = candidate;
      ramps = candidateRamps;
      break;
    }
  }

  //a ramp's color count is judged on its own cluster, so each trimmed ramp is only kept if the whole palette still passes
  List<int> colorCounts = List<int>.filled(members.length, maxColors);
  for (int i = 0; i < members.length; i++)
  {
    final int fewest = _fewestColors(cluster: members[i], maxColors: maxColors);
    if (fewest == maxColors) continue;
    final List<int> candidate = <int>[...colorCounts]..[i] = fewest;
    final List<KPalRampData> trimmed = _fitRamps(members: members, colorCounts: candidate, bins: bins, colors: colors);
    if (_closeEnough(error: _matchError(ramps: trimmed, bins: bins, colors: colors), best: best))
    {
      colorCounts = candidate;
      ramps = trimmed;
    }
  }
  return ramps;
}

/// Finds up to [maxRamps] ramps of up to [maxColors] colors for an image. With [adaptiveCounts] both limits are only
/// used as far as more ramps or colors still match the image noticeably better; without, they are used as given.
List<ExtractedRamp> extractColorRamps({
  required final Uint8List imgBytes,
  required final int maxRamps,
  required final int maxColors,
  final bool adaptiveCounts = true,
}) {
  final _QuantizeResult q = quantizeHSVFromRGBABytes(
    imgBytes: imgBytes,
  );
  if (q.bins.isEmpty) {
    return <ExtractedRamp>[
      ExtractedRamp(settings: KPalRampSettings(), shifts: <HistoryShiftSet>[]),
    ];
  }

  // Cluster only on the (small) set of bin centroids
  final _BinColors colors = _BinColors.of(bins: q.bins);
  final List<KPalRampData> ramps;
  if (adaptiveCounts)
  {
    ramps = _smallestRamps(bins: q.bins, colors: colors, maxRamps: maxRamps, maxColors: maxColors);
  }
  else
  {
    final List<List<_HSVBin>> members = _clusterMembers(bins: q.bins, k: maxRamps);
    ramps = _fitRamps(members: members, colorCounts: List<int>.filled(members.length, maxColors), bins: q.bins, colors: colors);
  }
  return <ExtractedRamp>[
    for (final KPalRampData ramp in ramps)
      ExtractedRamp(
        settings: ramp.settings,
        shifts: <HistoryShiftSet>[
          for (int i = 0; i < ramp.settings.colorCount; i++)
            HistoryShiftSet(hueShift: ramp.shifts[i].hueShiftNotifier.value, satShift: ramp.shifts[i].satShiftNotifier.value, valShift: ramp.shifts[i].valShiftNotifier.value),
        ],
      ),
  ];
}
