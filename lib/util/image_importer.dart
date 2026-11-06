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

import 'package:get_it/get_it.dart';
import 'package:kpix/infra/reference_image_manager.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/reference_layer_constraints.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/palette_codec.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/isolate_helper.dart';
import 'package:kpix/util/helpers/pixel_grid.dart';
import 'package:kpix/util/palette_extraction.dart';
import 'package:uuid/uuid.dart';

/// Turns an external image into a palette and a drawing layer.
///
/// The expensive steps - scaling down, finding the color ramps and matching every
/// pixel against them - run on a background isolate, so the UI keeps painting its
/// loading dialog while they do. Everything that touches dart:ui, the ramps or
/// the service locator stays here, and only plain numbers cross over.
Future<ImportResult> import({required final ImportData importData, required final List<KPalRampData> currentRamps}) async
{
  //the default premultiplied format would darken every soft edge
  final ByteData? imageData = await importData.image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  if (imageData == null)
  {
    return ImportResult(result: ImageImportResult.conversionFailed);
  }
  else
  {
    final Uint8List fullBytes = imageData.buffer.asUint8List(imageData.offsetInBytes, imageData.lengthInBytes);
    final int fullWidth = importData.image.width;
    final int fullHeight = importData.image.height;
    final int width = fullWidth ~/ importData.scale;
    final int height = fullHeight ~/ importData.scale;
    final Uint8List imgBytes = (width == fullWidth && height == fullHeight) ? fullBytes : await runOffThread<Uint8List>(
      debugLabel: "image-import-scale",
      work: () => scaleDownRgba(bytes: fullBytes, width: fullWidth, height: fullHeight, newWidth: width, newHeight: height),
    );

    DrawingLayerState drawingLayer;
    List<KPalRampData> ramps = <KPalRampData>[];
    if (importData.createNewPalette)
    {
      final int maxRamps = importData.maxRamps;
      final int maxColors = importData.maxColors;
      final List<ExtractedRamp> colorRamps = await runOffThread<List<ExtractedRamp>>(
        debugLabel: "image-import-palette",
        work: () => extractColorRamps(imgBytes: imgBytes, maxRamps: maxRamps, maxColors: maxColors),
      );
      for (final ExtractedRamp colorRamp in colorRamps)
      {
        ramps.add(KPalRampData(uuid: const Uuid().v1(), settings: colorRamp.settings, historyShifts: colorRamp.shifts));
      }

      drawingLayer = await _createDrawingLayer(imgBytes: imgBytes, width: width, height: height, ramps: ramps);
      await _removeUnusedRamps(ramps: ramps, references: drawingLayer.usedColors());
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
      drawingLayer = await _createDrawingLayer(imgBytes: imgBytes, width: width, height: height, ramps: ramps);
    }

    ReferenceLayerState? referenceLayer;
    if (importData.includeReference)
    {
      referenceLayer = await _getReferenceLayer(img: importData.image, imgPath: importData.filePath);
      final double targetZoomHeight = height.toDouble() / fullHeight.toDouble();
      final double targetZoomWidth = width.toDouble() / fullWidth.toDouble();
      referenceLayer.setZoomSliderFromZoomFactor(factor: (targetZoomWidth + targetZoomHeight) / 2.0);
    }

    final ImportDataSet importDataSet = ImportDataSet(rampDataList: ramps, drawingLayer: drawingLayer, referenceLayer: referenceLayer, canvasSize: CoordinateSetI(x: width, y: height));
    return ImportResult(result: ImageImportResult.success, data: importDataSet);

  }

}

/// Averages the source pixels that land on each target pixel, weighted by alpha so transparent pixels add no color.
Uint8List scaleDownRgba({required final Uint8List bytes, required final int width, required final int height, required final int newWidth, required final int newHeight})
{
  final Uint8List out = Uint8List(newWidth * newHeight * 4);
  for (int y = 0; y < newHeight; y++)
  {
    final int y0 = y * height ~/ newHeight;
    final int y1 = max(y0 + 1, (y + 1) * height ~/ newHeight);
    for (int x = 0; x < newWidth; x++)
    {
      final int x0 = x * width ~/ newWidth;
      final int x1 = max(x0 + 1, (x + 1) * width ~/ newWidth);
      int r = 0;
      int g = 0;
      int b = 0;
      int a = 0;
      for (int sy = y0; sy < y1; sy++)
      {
        for (int i = (sy * width + x0) * 4, end = (sy * width + x1) * 4; i < end; i += 4)
        {
          final int alpha = bytes[i + 3];
          r += bytes[i] * alpha;
          g += bytes[i + 1] * alpha;
          b += bytes[i + 2] * alpha;
          a += alpha;
        }
      }
      final int o = (y * newWidth + x) * 4;
      if (a > 0)
      {
        out[o] = (r / a).round();
        out[o + 1] = (g / a).round();
        out[o + 2] = (b / a).round();
      }
      out[o + 3] = (a / ((x1 - x0) * (y1 - y0))).round();
    }
  }
  return out;
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
  final ReferenceLayerState refState = ReferenceLayerState(
      aspectRatio: ReferenceLayerConstraints.aspectRatioDefault,
      image: null,
      offsetX: 0,
      offsetY: 0,
      opacity: ReferenceLayerConstraints.opacityDefault,
      zoom: ReferenceLayerConstraints.zoomDefault,
      brightness: ReferenceLayerConstraints.brightnessDefault,
      contrast: ReferenceLayerConstraints.contrastDefault,
      saturation: ReferenceLayerConstraints.saturationDefault,
      warmth: ReferenceLayerConstraints.warmthDefault,
  );
  final ReferenceImage refImg = await GetIt.I.get<ReferenceImageManager>().addLoadedImage(path: imgPath, img: img);
  refState.imageNotifier.value = refImg;
  refState.thumbnail.value = refImg.image;
  return refState;
}

Future<DrawingLayerState> _createDrawingLayer({required final Uint8List imgBytes, required final int width, required final int height, required final List<KPalRampData> ramps}) async
{
  final PaletteLab palette = PaletteLab.fromRamps(ramps: ramps);
  final PixelGrid pixels = await runOffThread<PixelGrid>(
    debugLabel: "image-import-match",
    work: () => matchImageToPalette(imgBytes: imgBytes, width: width, height: height, palette: palette),
  );
  final DrawingLayerSettings settings = DrawingLayerSettings.defaultValues(
    startingColor: ramps.first.references.first,
    constraints: GetIt.I.get<PreferenceManager>().drawingLayerSettingsConstraints,
  );
  return DrawingLayerState.fromPixels(pixels: pixels, codec: PaletteCodec(ramps: ramps), drawingLayerSettings: settings);
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
