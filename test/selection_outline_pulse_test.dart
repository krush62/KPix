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

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/stamps/stamp_manager_widget.dart';
import 'package:kpix/widgets/tools/tool_type.dart';

import 'support/selection_harness.dart';

/// The pulse scales the opacity of the selection outline only. Everything else
/// that is drawn with the selection colours - the reference layer border and the
/// drag cursor - keeps the opacity that was configured in the preferences.
///
/// The animation swings the factor between half and full, so the two cases below
/// are the ends of the cycle: the outline changes with the pulse, and it is still
/// drawn where the pulse is at its dimmest.
void main()
{
  const Size renderSize = Size(80, 80);

  testWidgets('the selection outline follows the pulse and stays visible at its dimmest', (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async {
      final _PainterHarness harness = _PainterHarness();

      GetIt.I.get<DocumentState>().selectionState.selectAll();
      expect(GetIt.I.get<DocumentState>().selectionState.selectionLines, isNotEmpty);

      final Uint8List fullOutline = await harness.render(size: renderSize, pulse: 1.0);
      final Uint8List dimmedOutline = await harness.render(size: renderSize, pulse: 0.5);

      GetIt.I.get<DocumentState>().selectionState.deselect(addToHistoryStack: false);
      expect(GetIt.I.get<DocumentState>().selectionState.selection.isEmpty, isTrue);
      final Uint8List withoutSelection = await harness.render(size: renderSize, pulse: 1.0);

      expect(fullOutline, isNot(equals(dimmedOutline)), reason: 'the outline has to react to the pulse');
      //the pulse bottoms out at half the configured opacity, it never fades out
      expect(dimmedOutline, isNot(equals(withoutSelection)), reason: 'the dimmed outline is still drawn');

      harness.dispose();
    },);
  });

  testWidgets('the drag cursor does not pulse', (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async {
      //the dragging cursor is the one drawn with the selection colours
      final _PainterHarness harness = _PainterHarness()
        ..cursorPos.value = CoordinateSetD(x: 40, y: 40)
        ..isDragging.value = true;

      final Uint8List fullPulse = await harness.render(size: renderSize, pulse: 1.0);
      final Uint8List noPulse = await harness.render(size: renderSize, pulse: 0.0);

      expect(fullPulse, equals(noPulse), reason: 'the cursor keeps the configured opacity');

      harness.dispose();
    },);
  });
}

/// A [KPixPainter] with every input notifier it needs, rendered into an image.
class _PainterHarness
{
  final ValueNotifier<Offset> offset = ValueNotifier<Offset>(const Offset(8, 8));
  final ValueNotifier<CoordinateSetD?> cursorPos = ValueNotifier<CoordinateSetD?>(null);
  final ValueNotifier<bool> isDragging = ValueNotifier<bool>(false);
  final ValueNotifier<bool> primaryDown = ValueNotifier<bool>(false);
  final ValueNotifier<bool> secondaryDown = ValueNotifier<bool>(false);
  final ValueNotifier<bool> stylusLongMoveStarted = ValueNotifier<bool>(false);
  final ValueNotifier<bool> stylusLongMoveVertical = ValueNotifier<bool>(false);
  final ValueNotifier<bool> stylusLongMoveHorizontal = ValueNotifier<bool>(false);
  final ValueNotifier<bool> stylusButton1Down = ValueNotifier<bool>(false);
  final ValueNotifier<Offset> primaryPressStart = ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<double> selectionPulse = ValueNotifier<double>(1.0);
  late final KPixPainter painter;

  _PainterHarness()
  {
    //the painter builds one painter per tool, and the stamp tool reaches for the
    //stamp manager, which the project harness does not boot
    if (!GetIt.I.isRegistered<StampManager>())
    {
      GetIt.I.registerSingleton<StampManager>(StampManager());
    }
    GetIt.I.get<ToolState>().setToolSelection(tool: ToolType.select, forceSetting: true);
    painter = KPixPainter(
      offset: offset,
      coords: cursorPos,
      isDragging: isDragging,
      stylusLongMoveStarted: stylusLongMoveStarted,
      stylusLongMoveVertical: stylusLongMoveVertical,
      stylusLongMoveHorizontal: stylusLongMoveHorizontal,
      primaryDown: primaryDown,
      secondaryDown: secondaryDown,
      primaryPressStart: primaryPressStart,
      stylusButton1Down: stylusButton1Down,
      selectionPulse: selectionPulse,
    );
  }

  Future<Uint8List> render({required final Size size, required final double pulse}) async
  {
    selectionPulse.value = pulse;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), size);
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(size.width.round(), size.height.round());
    picture.dispose();
    final ByteData? data = await image.toByteData();
    image.dispose();
    return data!.buffer.asUint8List();
  }

  void dispose()
  {
    painter.dispose();
  }
}
