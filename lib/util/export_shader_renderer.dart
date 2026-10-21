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

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:kpix/models/export_shader.dart';
import 'package:kpix/util/helpers/isolate_helper.dart';

/// Outputs larger than this in either direction are rendered in tiles.
const int exportShaderMaxTileSize = 2048;

const String _flipProbeAsset = "shaders/flip_probe.frag";
Future<bool>? _flipY;

/// A rectangle of the shaded output, in output pixels.
class ExportShaderRegion
{
  final int x;
  final int y;
  final int width;
  final int height;
  const ExportShaderRegion({required this.x, required this.y, required this.width, required this.height});
}

Future<ui.Image> _paintShader({required final ui.FragmentShader shader, required final int width, required final int height}) async
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), ui.Paint()..shader = shader);
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(width, height);
  picture.dispose();
  return image;
}

/// Whether the backend samples images rendered by the engine upside down (Impeller on OpenGL ES).
///
/// Found out once by sampling a red-over-blue image.
Future<bool> _isFlipY()
{
  return _flipY ??= _probeFlipY().catchError((final Object e)
  {
    //a failed probe is tried again with the next render
    _flipY = null;
    throw e;
  });
}

Future<bool> _probeFlipY() async
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 1, 1), ui.Paint()..color = const ui.Color(0xFFFF0000));
  canvas.drawRect(const ui.Rect.fromLTWH(0, 1, 1, 1), ui.Paint()..color = const ui.Color(0xFF0000FF));
  final ui.Picture picture = recorder.endRecording();
  final ui.Image source = await picture.toImage(1, 2);
  picture.dispose();

  final ui.FragmentProgram program = await ui.FragmentProgram.fromAsset(_flipProbeAsset);
  final ui.FragmentShader shader = program.fragmentShader();
  shader.getUniformVec2("uSize").set(1, 2);
  shader.setImageSampler(0, source);
  final ui.Image result = await _paintShader(shader: shader, width: 1, height: 2);
  final ByteData? bytes = await result.toByteData();
  shader.dispose();
  result.dispose();
  source.dispose();
  return bytes != null && bytes.getUint8(2) > bytes.getUint8(0);
}

Future<ui.Image> _render({
  required final ExportShaderValues values,
  required final ui.Image source,
  required final int scaling,
  required final ExportShaderRegion region,
  required final bool flipY,
}) async
{
  final ui.FragmentProgram program = await ui.FragmentProgram.fromAsset(values.variant.asset);
  final ui.FragmentShader shader = program.fragmentShader();
  shader.getUniformVec2("uOffset").set(region.x.toDouble(), region.y.toDouble());
  shader.getUniformVec2("uSourceSize").set(source.width.toDouble(), source.height.toDouble());
  shader.getUniformFloat("uScale").set(scaling.toDouble());
  shader.getUniformFloat("uFlipY").set(flipY ? 1.0 : 0.0);
  values.applyTo(shader: shader);
  shader.setImageSampler(0, source);
  final ui.Image image = await _paintShader(shader: shader, width: region.width, height: region.height);
  shader.dispose();
  return image;
}

/// Renders [region] of [source] scaled up by [scaling] and shaded with [values].
///
/// Works on its own handle of [source] and a copy of [values], so both may change while this is running.
Future<ui.Image> renderExportShaderRegion({
  required final ExportShaderValues values,
  required final ui.Image source,
  required final int scaling,
  required final ExportShaderRegion region,
}) async
{
  final ExportShaderValues snapshot = ExportShaderValues.from(other: values);
  final ui.Image sourceHandle = source.clone();
  try
  {
    final bool flipY = await _isFlipY();
    return await _render(values: snapshot, source: sourceHandle, scaling: scaling, region: region, flipY: flipY);
  }
  finally
  {
    sourceHandle.dispose();
  }
}

//its own function, so the isolate only gets these plain values and not the images of the caller
Future<Uint8List> _encodePngOffThread({required final int width, required final int height, required final Uint8List rgba})
{
  return runOffThread<Uint8List>(
    debugLabel: "shader png encoding",
    work: () => img.encodePng(img.Image.fromBytes(width: width, height: height, bytes: rgba.buffer, numChannels: 4, order: img.ChannelOrder.rgba)),
  );
}

/// Renders the whole shaded output of [source] and encodes it as PNG.
Future<Uint8List?> renderExportShaderPng({
  required final ExportShaderValues values,
  required final ui.Image source,
  required final int scaling,
}) async
{
  final int width = source.width * scaling;
  final int height = source.height * scaling;
  final ExportShaderValues snapshot = ExportShaderValues.from(other: values);
  final ui.Image sourceHandle = source.clone();
  try
  {
    final bool flipY = await _isFlipY();
    Future<ui.Image> render(final ExportShaderRegion region) => _render(values: snapshot, source: sourceHandle, scaling: scaling, region: region, flipY: flipY);

    if (width <= exportShaderMaxTileSize && height <= exportShaderMaxTileSize)
    {
      final ui.Image image = await render(ExportShaderRegion(x: 0, y: 0, width: width, height: height));
      final ByteData? png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return png?.buffer.asUint8List();
    }

    final Uint8List rgba = Uint8List(width * height * 4);
    for (int tileY = 0; tileY < height; tileY += exportShaderMaxTileSize)
    {
      for (int tileX = 0; tileX < width; tileX += exportShaderMaxTileSize)
      {
        final ExportShaderRegion region = ExportShaderRegion(
          x: tileX,
          y: tileY,
          width: min(width - tileX, exportShaderMaxTileSize),
          height: min(height - tileY, exportShaderMaxTileSize),
        );
        final ui.Image tile = await render(region);
        final ByteData? tileBytes = await tile.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
        tile.dispose();
        if (tileBytes == null)
        {
          return null;
        }
        final Uint8List tilePixels = tileBytes.buffer.asUint8List(tileBytes.offsetInBytes, tileBytes.lengthInBytes);
        final int rowLength = region.width * 4;
        for (int row = 0; row < region.height; row++)
        {
          final int target = ((region.y + row) * width + region.x) * 4;
          rgba.setRange(target, target + rowLength, tilePixels, row * rowLength);
        }
      }
    }

    return await _encodePngOffThread(width: width, height: height, rgba: rgba);
  }
  finally
  {
    sourceHandle.dispose();
  }
}
