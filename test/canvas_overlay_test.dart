/*
 * KPix
 * Copyright (C) 2023-2026 krush62 (Andreas Kruschinski)
 *
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
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/reference_image_manager.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/managers/font_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/managers/stamp_manager.dart';
import 'package:kpix/models/constraints/tool_text_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/frame_blending_options.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/symmetry_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/models/tool_type.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/painting/color_pick_painter.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:material_ui/material_ui.dart';

import 'support/selection_harness.dart';

const Size _renderSize = Size(100, 100);
const Offset _offset = Offset(10, 10);
const int _zoom = 4;

final CoordinateSetI _canvasSize = CoordinateSetI(x: 8, y: 6);

Timeline get _timeline => GetIt.I.get<DocumentState>().timeline;
List<ColorReference> _ramp({final int index = 1}) => GetIt.I.get<PaletteState>().colorRamps[index].references;

/// The canvas the way the canvas widget paints it, with the input it reacts to.
class _Canvas
{
  final ValueNotifier<CoordinateSetD?> coords = ValueNotifier<CoordinateSetD?>(null);
  final ValueNotifier<bool> primaryDown = ValueNotifier<bool>(false);
  final ValueNotifier<Offset> pressStart = ValueNotifier<Offset>(Offset.zero);
  late final KPixPainter painter;

  _Canvas()
  {
    if (!GetIt.I.isRegistered<StampManager>())
    {
      GetIt.I.registerSingleton<StampManager>(StampManager());
    }
    GetIt.I.get<ViewState>().setZoomLevel(val: _zoom);
    painter = KPixPainter(
      offset: ValueNotifier<Offset>(_offset),
      coords: coords,
      isDragging: ValueNotifier<bool>(false),
      stylusLongMoveStarted: ValueNotifier<bool>(false),
      stylusLongMoveVertical: ValueNotifier<bool>(false),
      stylusLongMoveHorizontal: ValueNotifier<bool>(false),
      primaryDown: primaryDown,
      secondaryDown: ValueNotifier<bool>(false),
      primaryPressStart: pressStart,
      stylusButton1Down: ValueNotifier<bool>(false),
      selectionPulse: ValueNotifier<double>(1.0),
    );
  }

  /// What the canvas shows now. The first render builds the checkerboard, which
  /// takes a moment to arrive.
  Future<_Picture> render() async
  {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), _renderSize);
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(_renderSize.width.round(), _renderSize.height.round());
    picture.dispose();
    final ByteData data = (await image.toByteData())!;
    image.dispose();
    return _Picture(data.buffer.asUint8List());
  }

  Future<_Picture> settledRender() async
  {
    await render();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    return render();
  }
}

class _Picture
{
  final Uint8List bytes;
  const _Picture(this.bytes);

  List<int> at({required final int x, required final int y})
  {
    final int i = (y * _renderSize.width.round() + x) * 4;
    return bytes.sublist(i, i + 4);
  }

  /// The screen pixel in the middle of the canvas pixel at [x]|[y].
  List<int> canvasAt({required final int x, required final int y}) => at(x: _offset.dx.round() + x * _zoom + _zoom ~/ 2, y: _offset.dy.round() + y * _zoom + _zoom ~/ 2);
}

List<int> _rgbaOf({required final ColorReference color})
{
  final Color c = color.getIdColor().color;
  return <int>[(c.r * 255).round(), (c.g * 255).round(), (c.b * 255).round(), 255];
}

void _overlayTest(final String description, final Future<void> Function(ProjectSession projectSession, _Canvas canvas) body, {final bool skip = false, final FontManager? fontManager})
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, fontManager: fontManager, body: (final ProjectSession projectSession) async
    {
      final _Canvas canvas = _Canvas();
      addTearDown(canvas.painter.dispose);
      await body(projectSession, canvas);
    },);
  }, skip: skip,);
}

Future<void> _paint({required final Frame frame, required final Map<CoordinateSetI, ColorReference> pixels}) async
{
  (frame.layerList.getLayer(index: 0) as DrawingLayerState).setDataAll(list: CoordinateColorMapNullable.from(pixels));
  await settle();
}

void main()
{
  group("the symmetry guides", ()
  {
    //beside the middle of the line, where the light outline shows on any background
    final int guideX = _offset.dx.round() + 4 * _zoom - 2;
    final int guideY = _offset.dy.round() + 3 * _zoom - 2;

    /// Two empty frames playing in a loop.
    Future<void> startPlayback() async
    {
      expect(_timeline.addNewFrameRight(), LayerActionResult.success, reason: "setup");
      await settle();
      _timeline.loopEndIndex.value = 1;
      _timeline.isPlaying.value = true;
      expect(_timeline.isPlaying.value, isTrue, reason: "setup");
      addTearDown(() => _timeline.isPlaying.value = false);
    }

    _overlayTest("cross the canvas and reach past it, one for each axis", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      final _Picture without = await canvas.settledRender();
      final SymmetryState symmetry = GetIt.I.get<SymmetryState>();

      symmetry.horizontalActivated.value = true;
      symmetry.horizontalValue.value = 4.0;
      final _Picture horizontal = await canvas.render();

      expect(horizontal.at(x: guideX, y: 20), isNot(without.at(x: guideX, y: 20)), reason: "on the canvas");
      expect(horizontal.at(x: guideX, y: 50), isNot(without.at(x: guideX, y: 50)), reason: "past the canvas");
      expect(horizontal.at(x: guideX + 8, y: 20), without.at(x: guideX + 8, y: 20), reason: "next to the guide");

      symmetry.horizontalActivated.value = false;
      symmetry.verticalActivated.value = true;
      symmetry.verticalValue.value = 3.0;
      final _Picture vertical = await canvas.render();

      expect(vertical.at(x: 20, y: guideY), isNot(without.at(x: 20, y: guideY)), reason: "on the canvas");
      expect(vertical.at(x: 60, y: guideY), isNot(without.at(x: 60, y: guideY)), reason: "past the canvas");
      expect(vertical.at(x: 20, y: guideY + 8), without.at(x: 20, y: guideY + 8), reason: "next to the guide");
    });

    _overlayTest("the vertical one is left out during playback", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      final SymmetryState symmetry = GetIt.I.get<SymmetryState>();
      symmetry.verticalActivated.value = true;
      symmetry.verticalValue.value = 3.0;
      await canvas.settledRender();
      await startPlayback();

      final _Picture playing = await canvas.render();

      symmetry.verticalActivated.value = false;
      expect(playing.bytes, (await canvas.render()).bytes);
    });

    _overlayTest("the horizontal one is left out during playback", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      final SymmetryState symmetry = GetIt.I.get<SymmetryState>();
      symmetry.horizontalActivated.value = true;
      symmetry.horizontalValue.value = 4.0;
      await canvas.settledRender();
      await startPlayback();

      final _Picture playing = await canvas.render();

      symmetry.horizontalActivated.value = false;
      expect(playing.bytes, (await canvas.render()).bytes);
    });
  });

  group("frame blending", ()
  {
    final CoordinateSetI dot = CoordinateSetI(x: 2, y: 2);

    FrameBlendingOptions blending() => GetIt.I.get<FrameBlendingOptions>();

    /// Two frames, the second one with a pixel, with the first one selected.
    Future<void> twoFrames() async
    {
      expect(_timeline.addNewFrameRight(), LayerActionResult.success, reason: "setup");
      await settle();
      await _paint(frame: _timeline.frames.value[1], pixels: <CoordinateSetI, ColorReference>{dot: _ramp()[2]});
      _timeline.selectFrame(frame: _timeline.frames.value.first);
      await settle();
    }

    _overlayTest("shows nothing of the other frames while it is off", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      await twoFrames();
      final _Picture before = await canvas.settledRender();

      blending().framesAfter.value = 1;

      expect((await canvas.render()).bytes, before.bytes);
    });

    _overlayTest("shows the frame after, at full strength without a tint", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      await twoFrames();
      await canvas.settledRender();
      blending().enabled.value = true;
      blending().framesAfter.value = 1;
      blending().framesBefore.value = 0;
      blending().opacity.value = 1.0;
      blending().tinting.value = false;
      blending().activeLayerOnly.value = true;

      expect((await canvas.render()).canvasAt(x: dot.x, y: dot.y), _rgbaOf(color: _ramp()[2]));
    });

    _overlayTest("tints the frame after green", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      await twoFrames();
      await canvas.settledRender();
      blending().enabled.value = true;
      blending().framesAfter.value = 1;
      blending().framesBefore.value = 0;
      blending().opacity.value = 1.0;
      blending().tinting.value = true;
      blending().activeLayerOnly.value = true;
      final List<int> original = _rgbaOf(color: _ramp()[2]);

      final List<int> tinted = (await canvas.render()).canvasAt(x: dot.x, y: dot.y);

      expect(tinted[0], lessThan(original[0] + 1));
      expect(tinted[2], lessThan(original[2] + 1));
      expect(tinted, isNot(original));
      expect(tinted[0] + tinted[2], lessThan(original[0] + original[2]), reason: "green takes out the red and the blue");
    });

    _overlayTest("reaches round the end only when wrapping", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      await twoFrames();
      final _Picture nothing = await canvas.settledRender();
      blending().enabled.value = true;
      blending().framesBefore.value = 1;
      blending().framesAfter.value = 0;
      blending().opacity.value = 1.0;
      blending().tinting.value = false;
      blending().activeLayerOnly.value = true;

      blending().wrapAroundBefore.value = false;
      expect((await canvas.render()).canvasAt(x: dot.x, y: dot.y), nothing.canvasAt(x: dot.x, y: dot.y), reason: "there is no frame before the first");

      blending().wrapAroundBefore.value = true;
      expect((await canvas.render()).canvasAt(x: dot.x, y: dot.y), _rgbaOf(color: _ramp()[2]), reason: "wrapping, that is the last one");
    });

    _overlayTest("reaches round the end after the last frame too", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      await twoFrames();
      await _paint(frame: _timeline.frames.value.first, pixels: <CoordinateSetI, ColorReference>{CoordinateSetI(x: 5, y: 2): _ramp()[3]});
      _timeline.selectFrame(frame: _timeline.frames.value.last);
      await settle();
      final _Picture nothing = await canvas.settledRender();
      blending().enabled.value = true;
      blending().framesAfter.value = 1;
      blending().framesBefore.value = 0;
      blending().opacity.value = 1.0;
      blending().tinting.value = false;
      blending().activeLayerOnly.value = true;

      blending().wrapAroundAfter.value = false;
      expect((await canvas.render()).canvasAt(x: 5, y: 2), nothing.canvasAt(x: 5, y: 2));

      blending().wrapAroundAfter.value = true;
      expect((await canvas.render()).canvasAt(x: 5, y: 2), _rgbaOf(color: _ramp()[3]));
    });

    _overlayTest("shows the frames further away fainter when gradual", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      await twoFrames();
      //a new frame goes right after the selected one
      _timeline.selectFrame(frame: _timeline.frames.value.last);
      expect(_timeline.addNewFrameRight(), LayerActionResult.success, reason: "setup");
      await settle();
      final CoordinateSetI farDot = CoordinateSetI(x: 5, y: 2);
      await _paint(frame: _timeline.frames.value[2], pixels: <CoordinateSetI, ColorReference>{farDot: _ramp()[2]});
      _timeline.selectFrame(frame: _timeline.frames.value.first);
      await settle();
      final _Picture nothing = await canvas.settledRender();
      blending().enabled.value = true;
      blending().framesAfter.value = 2;
      blending().framesBefore.value = 0;
      blending().opacity.value = 1.0;
      blending().gradualOpacity.value = true;
      blending().tinting.value = false;
      blending().activeLayerOnly.value = true;

      final _Picture blended = await canvas.render();

      expect(blended.canvasAt(x: dot.x, y: dot.y), _rgbaOf(color: _ramp()[2]), reason: "the next frame at full strength");
      expect(blended.canvasAt(x: farDot.x, y: farDot.y), isNot(_rgbaOf(color: _ramp()[2])), reason: "the one after it fainter");
      expect(blended.canvasAt(x: farDot.x, y: farDot.y), isNot(nothing.canvasAt(x: farDot.x, y: farDot.y)), reason: "but there");
    });
  });

  group("a reference layer", ()
  {
    /// A reference layer with a red image of 8 by 8, selected.
    Future<ReferenceLayerState> referenceLayer() async
    {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 16, 16), Paint()..color = const Color(0xFFCC3333));
      final ui.Image picture = await recorder.endRecording().toImage(16, 16);
      final ReferenceLayerState reference = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.reference, select: true).$2! as ReferenceLayerState;
      reference.imageNotifier.value = ReferenceImage(path: "picture.png", image: picture);
      await settle();
      return reference;
    }

    _overlayTest("shows its image on the canvas", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      final _Picture without = await canvas.settledRender();
      await referenceLayer();

      expect((await canvas.render()).canvasAt(x: 1, y: 1), isNot(without.canvasAt(x: 1, y: 1)));
    });

    _overlayTest("shows nothing while hidden or without an image", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      final _Picture without = await canvas.settledRender();
      final ReferenceLayerState reference = await referenceLayer();

      reference.visibilityState.value = LayerVisibilityState.hidden;
      expect((await canvas.render()).canvasAt(x: 1, y: 1), without.canvasAt(x: 1, y: 1));

      reference.visibilityState.value = LayerVisibilityState.visible;
      reference.imageNotifier.value = null;
      expect((await canvas.render()).canvasAt(x: 1, y: 1), without.canvasAt(x: 1, y: 1));
    });

    _overlayTest("is faded by its opacity", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      await canvas.settledRender();
      final ReferenceLayerState reference = await referenceLayer();
      final List<int> full = (await canvas.render()).canvasAt(x: 1, y: 1);

      reference.opacityNotifier.value = 20;

      expect((await canvas.render()).canvasAt(x: 1, y: 1), isNot(full));
    });

    _overlayTest("reaches past the canvas only when the preference asks for it", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      final _Picture without = await canvas.settledRender();
      final ReferenceLayerState reference = await referenceLayer();
      reference.setZoomSliderFromZoomFactor(factor: 8.0);
      final int outside = _offset.dx.round() + _canvasSize.x * _zoom + 10;

      expect((await canvas.render()).at(x: outside, y: 20), without.at(x: outside, y: 20));

      GetIt.I.get<PreferenceManager>().behaviorPreferenceContent.showReferenceOutsideCanvas.value = true;

      expect((await canvas.render()).at(x: outside, y: 20), isNot(without.at(x: outside, y: 20)));
    });

    _overlayTest("moves with a drag while it is selected", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      final ReferenceLayerState reference = await referenceLayer();
      await canvas.settledRender();
      const Offset start = Offset(20, 20);
      canvas.pressStart.value = start;
      canvas.coords.value = CoordinateSetD(x: start.dx, y: start.dy);
      canvas.primaryDown.value = true;
      await canvas.render();

      canvas.coords.value = CoordinateSetD(x: start.dx + 8, y: start.dy + 4);
      await canvas.render();

      expect(reference.offsetX, 2.0);
      expect(reference.offsetY, 1.0);

      canvas.primaryDown.value = false;
      await canvas.render();
      canvas.coords.value = CoordinateSetD(x: start.dx + 40, y: start.dy + 40);
      await canvas.render();

      expect(reference.offsetX, 2.0, reason: "the drag is over");
    });
  });

  group("the cursor info", ()
  {
    _overlayTest("shows next to the cursor during a drag when the preference asks for it", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      GetIt.I.get<ToolState>().setToolSelection(tool: ToolType.shape, forceSetting: true);
      await canvas.settledRender();
      const Offset start = Offset(12, 12);
      canvas.pressStart.value = start;
      canvas.primaryDown.value = true;
      canvas.coords.value = CoordinateSetD(x: start.dx, y: start.dy);
      await canvas.render();
      canvas.coords.value = CoordinateSetD(x: 30, y: 30);
      GetIt.I.get<PreferenceManager>().guiPreferenceContent.showCursorInfo.value = false;
      final _Picture off = await canvas.render();

      GetIt.I.get<PreferenceManager>().guiPreferenceContent.showCursorInfo.value = true;
      GetIt.I.get<PreferenceManager>().guiPreferenceContent.cursorInfoRight.value = true;
      final _Picture right = await canvas.render();
      GetIt.I.get<PreferenceManager>().guiPreferenceContent.cursorInfoRight.value = false;
      final _Picture left = await canvas.render();

      expect(listEquals(off.bytes, right.bytes), isFalse);
      expect(listEquals(right.bytes, left.bytes), isFalse, reason: "the box moved to the other side");
    });

    _overlayTest("takes its look from the theme", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      canvas.painter.setCursorInfoTheme(theme: ThemeData(tooltipTheme: const TooltipThemeData(
        textStyle: TextStyle(fontSize: 20),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, boxShadow: <BoxShadow>[BoxShadow(blurRadius: 4)]),
      ),),);
      GetIt.I.get<ToolState>().setToolSelection(tool: ToolType.shape, forceSetting: true);
      GetIt.I.get<PreferenceManager>().guiPreferenceContent.showCursorInfo.value = true;
      await canvas.settledRender();
      const Offset start = Offset(12, 12);
      canvas.pressStart.value = start;
      canvas.primaryDown.value = true;
      canvas.coords.value = CoordinateSetD(x: start.dx, y: start.dy);
      await canvas.render();
      canvas.coords.value = CoordinateSetD(x: 30, y: 30);

      await expectLater(canvas.render(), completes);
    });
  });

  group("every tool", ()
  {
    final FontManager font = FontManager(kFontMap: <PixelFontType, KFont>{pixelFontIndexMap[TextConstraints.fontIndexDefault]!: KFont(name: "test", height: 1, glyphMap: <int, Glyph>{})});

    for (final ToolType tool in ToolType.values)
    {
      _overlayTest("${tool.name} paints its cursor on the canvas and copes with leaving it", (final ProjectSession projectSession, final _Canvas canvas) async
      {
        GetIt.I.get<ToolState>().setToolSelection(tool: tool, forceSetting: true);
        final _Picture without = await canvas.settledRender();

        canvas.coords.value = CoordinateSetD(x: 30, y: 30);
        await canvas.render();
        final _Picture hovering = await canvas.render();
        expect(listEquals(hovering.bytes, without.bytes), isFalse, reason: "the cursor shows");

        canvas.coords.value = CoordinateSetD(x: 90, y: 90);
        await expectLater(canvas.render(), completes);

        canvas.coords.value = null;
        await expectLater(canvas.render(), completes);
        expect(canvas.painter.toolPainter, canvas.painter.toolPainterMap[tool]);
      }, fontManager: font,);
    }

    _overlayTest("the old tool is reset on a change", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      GetIt.I.get<ToolState>().setToolSelection(tool: ToolType.line, forceSetting: true);
      canvas.coords.value = CoordinateSetD(x: 30, y: 30);
      await canvas.settledRender();
      final IToolPainter? line = canvas.painter.toolPainter;
      expect(line, isNotNull, reason: "setup");

      GetIt.I.get<ToolState>().setToolSelection(tool: ToolType.pencil, forceSetting: true);
      await canvas.render();

      expect(canvas.painter.toolPainter, isNot(same(line)));
    });
  });

  group("a color pick on the canvas", ()
  {
    _overlayTest("finds the color under the cursor", (final ProjectSession projectSession, final _Canvas canvas) async
    {
      await _paint(frame: _timeline.frames.value.first, pixels: <CoordinateSetI, ColorReference>{CoordinateSetI(x: 2, y: 2): _ramp()[3]});
      GetIt.I.get<ToolState>().setToolSelection(tool: ToolType.pick, forceSetting: true);
      await canvas.settledRender();
      canvas.coords.value = CoordinateSetD(x: _offset.dx + 2 * _zoom + 1, y: _offset.dy + 2 * _zoom + 1);
      canvas.primaryDown.value = true;
      await canvas.render();

      expect((canvas.painter.toolPainter! as ColorPickPainter).selectedColor, _ramp()[3]);
    });
  });
}
