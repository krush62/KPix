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
/// The two expensive steps - finding the color ramps and matching every pixel
/// against them - run on a background isolate, so the UI keeps painting its
/// loading dialog while they do. Everything that touches dart:ui, the ramps or
/// the service locator stays here, and only plain numbers cross over.
Future<ImportResult> import({required final ImportData importData, required final List<KPalRampData> currentRamps}) async
{
  final ByteData? imageData = await importData.scaledImage.toByteData();
  if (imageData == null)
  {
    return ImportResult(result: ImageImportResult.conversionFailed);
  }
  else
  {
    final Uint8List imgBytes = imageData.buffer.asUint8List(imageData.offsetInBytes, imageData.lengthInBytes);
    final int width = importData.scaledImage.width;
    final int height = importData.scaledImage.height;

    DrawingLayerState drawingLayer;
    List<KPalRampData> ramps = <KPalRampData>[];
    if (importData.createNewPalette)
    {
      final int maxRamps = importData.maxRamps;
      final int maxColors = importData.maxColors;
      final List<KPalRampSettings> colorRamps = await runOffThread<List<KPalRampSettings>>(
        debugLabel: "image-import-palette",
        work: () => extractColorRamps(imgBytes: imgBytes, maxRamps: maxRamps, maxColors: maxColors),
      );
      for (final KPalRampSettings colorRamp in colorRamps)
      {
        ramps.add(KPalRampData(uuid: const Uuid().v1(), settings: colorRamp));
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
      final double targetZoomHeight = importData.scaledImage.height.toDouble() / (importData.image.height.toDouble());
      final double targetZoomWidth = importData.scaledImage.width.toDouble() / (importData.image.width.toDouble());
      referenceLayer.setZoomSliderFromZoomFactor(factor: (targetZoomWidth + targetZoomHeight) / 2.0);
    }

    final ImportDataSet importDataSet = ImportDataSet(rampDataList: ramps, drawingLayer: drawingLayer, referenceLayer: referenceLayer, canvasSize: CoordinateSetI(x: width, y: height));
    return ImportResult(result: ImageImportResult.success, data: importDataSet);

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
