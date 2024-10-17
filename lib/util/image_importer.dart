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

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kpix/widgets/file/import_widget.dart';

class ImageImporter
{
  //TODO this should return the layer and the ramp
  static Future<void> import({required final ImportData importData}) async
  {
    final ByteData? imageData = await _loadImage(path: importData.filePath);
    if (imageData == null)
    {
      return; //TODO error
    }
    else
    {
      final List<HSVColor> hsvColorList = await _extractColorsFromImage(imgBytes: imageData);
      //TODO do checks
      List<List<HSVColor>> clusteredColors = await _adaptiveClusterWithMaxRamps(maxRamps: importData.maxRamps, colors: hsvColorList, initialClusters: 5); //TODO magic number


      //TODO interpolating
    }
  }



  static Future<ByteData?> _loadImage({required final String path}) async
  {
    final File imageFile = File(path);
    if (await imageFile.exists())
    {
      return null;
    }
    else
    {
      try
      {
        final Uint8List imageBytes = await imageFile.readAsBytes();
        final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
        final ui.FrameInfo frame = await codec.getNextFrame();
        final ui.Image image = frame.image;
        return image.toByteData();
      }
      catch(_)
      {
        return null;
      }
    }
  }

  static Future<List<HSVColor>> _extractColorsFromImage({required final ByteData imgBytes}) async
  {
    final List<HSVColor> colorList = [];
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

  static Future<List<List<HSVColor>>> _adaptiveClusterWithMaxRamps({required final List<HSVColor> colors, required final int initialClusters, required final int maxRamps}) async
  {
    final List<List<HSVColor>> clusters = await _clusterByHue(colors: colors, numClusters: initialClusters);
    List<List<HSVColor>> finalClusters = [];
    for (final List<HSVColor> cluster in clusters)
    {
      final double variance = await _calculateClusterVariance(cluster: cluster);
      if (variance > 0.05)  // Threshold for splitting
      {
        finalClusters.addAll(await _clusterByHue(colors: cluster, numClusters: 2));
      }
      else
      {
        finalClusters.add(cluster);
      }
    }
    while (finalClusters.length > maxRamps)
    {
      await _mergeMostSimilarClusters(clusters: finalClusters);
    }
    return finalClusters;
  }

  static Future<List<List<HSVColor>>> _clusterByHue({required final List<HSVColor> colors, required final int numClusters}) async
  {
    final List<List<HSVColor>> clusters = List.generate(numClusters, (_) => []);
    for (final HSVColor color in colors)
    {
      final int bucket = (color.hue / 360 * numClusters).floor() % numClusters;
      clusters[bucket].add(color);
    }
    return clusters;
  }

  static Future<double> _calculateClusterVariance({required final List<HSVColor> cluster}) async
  {
    double meanValue = cluster.map((c) => c.value).reduce((a, b) => a + b) / cluster.length;
    double variance = cluster.map((c) => pow(c.value - meanValue, 2)).reduce((a, b) => a + b) / cluster.length;
    return variance;
  }

  static Future<void> _mergeMostSimilarClusters({required final List<List<HSVColor>> clusters}) async
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

  static double _calculateHueDistance({required final List<HSVColor> cluster1, required final List<HSVColor> cluster2})
  {
    final double avgHue1 = _calculateMeanHue(cluster: cluster1);
    final double avgHue2 = _calculateMeanHue(cluster: cluster2);
    return (avgHue1 - avgHue2).abs();
  }

  static double _calculateMeanHue({required final List<HSVColor> cluster})
  {
    final double sumHue = cluster.map((c) => c.hue).reduce((a, b) => a + b);
    return sumHue / cluster.length;
  }

  static Future<List<HSVColor>> _interpolateColorsFromRamp({required final List<HSVColor> ramp, required final int maxColors}) async
  {
    final List<HSVColor> interpolatedColors = [];
    final HSVColor darkestColor = ramp.first;
    final HSVColor lightestColor = ramp.last;
    interpolatedColors.add(darkestColor);

    // Linearly interpolate between colors
    for (int i = 1; i < maxColors - 1; i++)
    {
      final double factor = i / (maxColors - 1);
      HSVColor interpolatedColor = _interpolateHSV(c1: darkestColor, c2: lightestColor, t: factor, originalRamp: ramp);
      interpolatedColors.add(interpolatedColor);
    }

    interpolatedColors.add(lightestColor);

    return interpolatedColors;
  }

  static HSVColor _interpolateHSV({required final HSVColor c1, required final HSVColor c2, required final double t, required final List<HSVColor> originalRamp})
  {
    final double value = (1 - t) * c1.value + t * c2.value;

    final HSVColor lowerNeighbor = originalRamp.firstWhere((c) => c.value <= value, orElse: () => c1);
    final HSVColor upperNeighbor = originalRamp.lastWhere((c) => c.value >= value, orElse: () => c2);

    final double hue = (1 - t) * lowerNeighbor.hue + t * upperNeighbor.hue;
    final double saturation = (1 - t) * lowerNeighbor.saturation + t * upperNeighbor.saturation;

    return HSVColor.fromAHSV(1.0, hue, saturation, value);
  }

}