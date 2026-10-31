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

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/stamp_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/models/tool_type.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

const Size _renderSize = Size(64, 64);

KPixPainter _pencilPainter()
{
  //the painter builds one painter per tool, and the stamp tool reaches for the
  //stamp manager, which the project harness does not boot
  if (!GetIt.I.isRegistered<StampManager>())
  {
    GetIt.I.registerSingleton<StampManager>(StampManager());
  }
  GetIt.I.get<ToolOptions>().pencilOptions.size.value = 6;
  GetIt.I.get<ToolState>().setToolSelection(tool: ToolType.pencil, forceSetting: true);
  return KPixPainter(
    offset: ValueNotifier<Offset>(const Offset(8, 8)),
    coords: ValueNotifier<CoordinateSetD?>(CoordinateSetD(x: 16, y: 16)),
    isDragging: ValueNotifier<bool>(false),
    stylusLongMoveStarted: ValueNotifier<bool>(false),
    stylusLongMoveVertical: ValueNotifier<bool>(false),
    stylusLongMoveHorizontal: ValueNotifier<bool>(false),
    primaryDown: ValueNotifier<bool>(false),
    secondaryDown: ValueNotifier<bool>(false),
    primaryPressStart: ValueNotifier<Offset>(Offset.zero),
    stylusButton1Down: ValueNotifier<bool>(false),
    selectionPulse: ValueNotifier<double>(1.0),
  );
}

Future<Uint8List> _render({required final KPixPainter painter}) async
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), _renderSize);
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(_renderSize.width.round(), _renderSize.height.round());
  picture.dispose();
  final ByteData? data = await image.toByteData();
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Whether the canvas looks any different for the preview the pencil keeps for
/// the pixels under the cursor. It shades existing pixels, as that is the one
/// preview the pencil also builds on a locked layer.
Future<bool> _previewReachesCanvas({required final ProjectSession projectSession, final LayerVisibilityState visibility = LayerVisibilityState.visible, final LayerLockState lock = LayerLockState.unlocked}) async
{
  final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references[1];
  final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
  layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{
    for (int x = 0; x < 16; x++)
      for (int y = 0; y < 16; y++) CoordinateSetI(x: x, y: y): color,
  }),);
  await settle();

  final ShaderOptions shaderOptions = GetIt.I.get<ShaderOptions>();
  shaderOptions.isEnabled.value = true;
  shaderOptions.shaderDirection.value = ShaderDirection.right;
  shaderOptions.onlyCurrentRampEnabled.value = false;

  layer.visibilityState.value = visibility;
  layer.lockState.value = lock;

  final KPixPainter painter = _pencilPainter();
  await _render(painter: painter);
  await Future<void>.delayed(const Duration(milliseconds: 40));
  expect(painter.toolPainter!.cursorRaster, isNotNull, reason: "setup: the pencil has a preview to paint");

  final Uint8List withPreview = await _render(painter: painter);
  painter.toolPainter!.cursorRaster = null;
  final Uint8List withoutPreview = await _render(painter: painter);
  painter.dispose();

  return !listEquals(withPreview, withoutPreview);
}

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 32, y: 32);

  testWidgets("a visible unlocked layer shows the tool preview", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
      expect(await _previewReachesCanvas(projectSession: projectSession), isTrue);
    },);
  });

  testWidgets("a transparency locked layer shows the tool preview", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
      expect(await _previewReachesCanvas(projectSession: projectSession, lock: LayerLockState.transparency), isTrue,
          reason: "existing pixels can still be drawn on",);
    },);
  });

  testWidgets("a hidden layer shows no tool preview", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
      expect(await _previewReachesCanvas(projectSession: projectSession, visibility: LayerVisibilityState.hidden), isFalse,
          reason: "nothing can be drawn on a hidden layer, so nothing may look like it would be",);
    },);
  });

  testWidgets("a locked layer shows no tool preview", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
      expect(await _previewReachesCanvas(projectSession: projectSession, lock: LayerLockState.locked), isFalse,
          reason: "nothing can be drawn on a locked layer, so nothing may look like it would be",);
    },);
  });
}
