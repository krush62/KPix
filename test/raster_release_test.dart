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

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/layer_states/layer_settings.dart';
import 'package:kpix/layer_states/layer_settings_widget.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

class _FakeSettings extends LayerSettings
{
  @override
  bool hasActiveSettings() => false;
}

/// A rasterable layer with no rendering of its own, so the image handover can be
/// exercised without the service locator that the real layer types need.
class _FakeRasterLayer extends RasterableLayerState
{
  _FakeRasterLayer() : super(layerSettings: _FakeSettings());

  @override
  bool get hasPendingRaster => false;

  @override
  IconData get icon => Icons.circle;

  @override
  LayerMenuKind get menuKind => LayerMenuKind.raster;

  @override
  void dispose()
  {
    markDisposed();
    settleRaster();
  }

  @override
  LayerState copy({final List<RasterableLayerState>? layerStack}) => _FakeRasterLayer();

  @override
  HistoryLayer toHistoryLayer({required final List<HistoryRampData> ramps, final HistoryLayer? previousLayer})
  {
    throw UnimplementedError("not needed for release tests");
  }

  @override
  void resizeLayer({required final CoordinateSetI newSize, required final CoordinateSetI offset})
  {
    throw UnimplementedError("not needed for release tests");
  }

  @override
  LayerSettingsWidget getSettingsWidget()
  {
    throw UnimplementedError("not needed for release tests");
  }

  @override
  void forceFullRender() {}

  //the real layers call these from inside their own raster completion
  List<ui.Image?> held() => collectHeldImages();
  void release({required final Iterable<ui.Image?> outgoing}) => releaseSuperseded(outgoing: outgoing);
}

/// Stores [images] as one raster generation, the way the drawing layer does:
/// the first frame's image doubles as the layer's raster and thumbnail.
void _installGeneration({required final _FakeRasterLayer layer, required final List<Frame> frames, required final List<ui.Image> images})
{
  final Map<Frame, RasterImagePair> map = <Frame, RasterImagePair>{};
  for (int i = 0; i < frames.length; i++)
  {
    map[frames[i]] = RasterImagePair(raster: images[i], thumbnail: images[i]);
  }
  layer.rasterImage.value = images.first;
  layer.thumbnail.value = images.first;
  layer.rasterImageMap.value = map;
}

/// Builds a 1x1 image synchronously, avoiding the async decode that the test
/// binding's fake clock would have to be pumped through.
ui.Image _makeImage()
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint());
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = picture.toImageSync(1, 1);
  picture.dispose();
  return image;
}

void main()
{
  group('raster generation handover', () {
    late _FakeRasterLayer layer;
    late List<Frame> frames;

    setUp(() {
      layer = _FakeRasterLayer();
      frames = <Frame>[Frame.empty(fps: 1), Frame.empty(fps: 1), Frame.empty(fps: 1)];
    });

    testWidgets('releases the per frame images the new generation does not reuse', (final WidgetTester tester) async {
      final List<ui.Image> first = <ui.Image>[
        _makeImage(), _makeImage(), _makeImage(),
      ];
      _installGeneration(layer: layer, frames: frames, images: first);

      final List<ui.Image> second = <ui.Image>[
        _makeImage(), _makeImage(), _makeImage(),
      ];

      final List<ui.Image?> outgoing = layer.held();
      layer.previousRaster = layer.rasterImage.value;
      _installGeneration(layer: layer, frames: frames, images: second);
      layer.release(outgoing: outgoing);
      await tester.pump();

      //the first frame's image carries over as previousRaster, which the regional
      //renderer still composes against
      expect(first[0].debugDisposed, isFalse, reason: "carried over as previousRaster");
      //these were stranded before the fix: one image per frame beyond the first,
      //on every single raster
      expect(first[1].debugDisposed, isTrue);
      expect(first[2].debugDisposed, isTrue);

      for (final ui.Image image in second)
      {
        expect(image.debugDisposed, isFalse, reason: "belongs to the new generation");
      }
    });

    testWidgets('releases the previous generation once it is superseded', (final WidgetTester tester) async {
      final List<ui.Image> first = <ui.Image>[_makeImage()];
      final List<ui.Image> second = <ui.Image>[_makeImage()];
      final List<ui.Image> third = <ui.Image>[_makeImage()];
      final List<Frame> single = <Frame>[frames.first];

      _installGeneration(layer: layer, frames: single, images: first);

      List<ui.Image?> outgoing = layer.held();
      layer.previousRaster = layer.rasterImage.value;
      _installGeneration(layer: layer, frames: single, images: second);
      layer.release(outgoing: outgoing);
      await tester.pump();

      expect(first[0].debugDisposed, isFalse, reason: "still held as previousRaster");

      outgoing = layer.held();
      layer.previousRaster = layer.rasterImage.value;
      _installGeneration(layer: layer, frames: single, images: third);
      layer.release(outgoing: outgoing);
      await tester.pump();

      //the shading layer never released this one at all
      expect(first[0].debugDisposed, isTrue, reason: "two generations old");
      expect(second[0].debugDisposed, isFalse, reason: "now previousRaster");
      expect(third[0].debugDisposed, isFalse);
    });

    testWidgets('keeps an image the new generation still points at', (final WidgetTester tester) async {
      final ui.Image shared = _makeImage();
      final List<Frame> single = <Frame>[frames.first];

      _installGeneration(layer: layer, frames: single, images: <ui.Image>[shared]);
      final List<ui.Image?> outgoing = layer.held();
      //a generation that hands the very same handle back must not release it
      _installGeneration(layer: layer, frames: single, images: <ui.Image>[shared]);
      layer.release(outgoing: outgoing);
      await tester.pump();

      expect(shared.debugDisposed, isFalse);
    });

    testWidgets('separate thumbnail images are released too', (final WidgetTester tester) async {
      //the shading layer renders a distinct full size thumbnail per frame
      final ui.Image raster = _makeImage();
      final ui.Image thumb = _makeImage();
      layer.rasterImage.value = raster;
      layer.thumbnail.value = thumb;
      layer.rasterImageMap.value = <Frame, RasterImagePair>{
        frames.first: RasterImagePair(raster: raster, thumbnail: thumb),
      };

      final List<ui.Image?> outgoing = layer.held();
      final ui.Image newRaster = _makeImage();
      final ui.Image newThumb = _makeImage();
      layer.previousRaster = layer.rasterImage.value;
      layer.rasterImage.value = newRaster;
      layer.thumbnail.value = newThumb;
      layer.rasterImageMap.value = <Frame, RasterImagePair>{
        frames.first: RasterImagePair(raster: newRaster, thumbnail: newThumb),
      };
      layer.release(outgoing: outgoing);
      await tester.pump();

      expect(raster.debugDisposed, isFalse, reason: "carried over as previousRaster");
      expect(thumb.debugDisposed, isTrue, reason: "nothing points at the old thumbnail");
      expect(newRaster.debugDisposed, isFalse);
      expect(newThumb.debugDisposed, isFalse);
    });
  });
}
