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

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:material_ui/material_ui.dart';

import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 8, y: 8);
final CoordinateSetI _pixel = CoordinateSetI(x: 3, y: 3);
final CoordinateSetI _otherPixel = CoordinateSetI(x: 5, y: 5);

LayerManager get _manager => GetIt.I.get<LayerManager>();
Timeline get _timeline => GetIt.I.get<DocumentState>().timeline;
HistoryManager get _history => GetIt.I.get<HistoryManager>();
SelectionState get _selection => GetIt.I.get<DocumentState>().selectionState;
LayerCollection get _layers => _timeline.selectedFrame!.layerList;
List<ColorReference> get _ramp => GetIt.I.get<PaletteState>().colorRamps[0].references;

void _test(final String description, final Future<void> Function(DrawingLayerState bottom) body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
    {
      await body(layerAt(projectSession: projectSession, index: 0));
    },);
  });
}

void _paint({required final DrawingLayerState layer, required final CoordinateSetI coord, required final ColorReference color})
{
  layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{coord: color}));
}

T _add<T extends LayerState>({required final LayerKind kind, final bool select = true})
{
  return _manager.addNewLayer(layerType: kind, select: select, addToHistoryStack: false).$2! as T;
}

/// Three drawing layers, [a, b, c] from top to bottom, each with a mark of its own
/// in the top row that [_order] reads. What the mark is lets the order be checked
/// after an undo, which brings back other objects.
Future<List<DrawingLayerState>> _stack({required final DrawingLayerState bottom}) async
{
  final DrawingLayerState b = _add<DrawingLayerState>(kind: LayerKind.drawing);
  final DrawingLayerState a = _add<DrawingLayerState>(kind: LayerKind.drawing);
  _paint(layer: a, coord: CoordinateSetI(x: 0, y: 0), color: _ramp[0]);
  _paint(layer: b, coord: CoordinateSetI(x: 1, y: 0), color: _ramp[0]);
  _paint(layer: bottom, coord: CoordinateSetI(x: 2, y: 0), color: _ramp[0]);
  await settle();
  _history.addState(identifier: HistoryStateTypeIdentifier.generic);
  return <DrawingLayerState>[a, b, bottom];
}

String _order()
{
  final StringBuffer order = StringBuffer();
  for (int i = 0; i < _layers.length; i++)
  {
    final LayerState layer = _layers.getLayer(index: i);
    if (layer is DrawingLayerState)
    {
      for (int x = 0; x < 3; x++)
      {
        if (layer.getDataEntry(coord: CoordinateSetI(x: x, y: 0)) != null)
        {
          order.write(<String>["a", "b", "c"][x]);
        }
      }
    }
    else
    {
      order.write(layer.kind.name);
    }
  }
  return order.toString();
}

Future<(Frame, Frame)> _twoFrames() async
{
  _timeline.addNewFrameRight();
  await settle();
  _timeline.selectFrameByIndex(index: 0, addLayerSelectionToHistory: false);
  await settle();
  return (_timeline.frames.value[0], _timeline.frames.value[1]);
}

void _fill({required final LayerCollection layers})
{
  while (layers.length < LayerCollection.maxLayers)
  {
    layers.addNewReferenceLayer();
  }
}

Future<void> _undo() async
{
  await GetIt.I.get<HistoryController>().undoPressed()!.restore;
  await settle();
}

Future<void> _redo() async
{
  await GetIt.I.get<HistoryController>().redoPressed()!.restore;
  await settle();
}

/// Rastering a grid goes through a future, which [settle] does not know about.
Future<void> _until({required final bool Function() condition}) async
{
  for (int tick = 0; tick < 100 && !condition(); tick++)
  {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue);
  await settle();
}

void _expectNoUndoStep({required final HistoryState? before})
{
  expect(_history.getCurrentState(), same(before), reason: "nothing happened, so there is nothing to undo");
}

void main()
{
  group("adding a layer", ()
  {
    for (final (LayerKind, HistoryStateTypeIdentifier, Type) entry in <(LayerKind, HistoryStateTypeIdentifier, Type)>[
      (LayerKind.drawing, HistoryStateTypeIdentifier.layerNewDrawing, DrawingLayerState),
      (LayerKind.reference, HistoryStateTypeIdentifier.layerNewReference, ReferenceLayerState),
      (LayerKind.grid, HistoryStateTypeIdentifier.layerNewGrid, GridLayerState),
      (LayerKind.shading, HistoryStateTypeIdentifier.layerNewShading, ShadingLayerState),
      (LayerKind.dither, HistoryStateTypeIdentifier.layerNewDither, DitherLayerState),
    ])
    {
      _test("of kind ${entry.$1.name} is its own undo step", (final DrawingLayerState bottom) async
      {
        final (LayerActionResult, LayerState?) result = _manager.addNewLayer(layerType: entry.$1, select: true);
        await settle();

        expect(result.$1, LayerActionResult.success);
        expect(result.$2.runtimeType, entry.$3);
        expect(_timeline.getCurrentLayer(), same(result.$2));
        expect(_layers.getLayer(index: 0), same(result.$2), reason: "it goes above the layer that was selected");
        expect(_history.getCurrentIdentifier(), entry.$2);
      });
    }

    _test("without selecting it stays on the layer that was selected", (final DrawingLayerState bottom) async
    {
      final LayerState? added = _manager.addNewLayer(layerType: LayerKind.drawing).$2;
      await settle();

      expect(_layers.getLayer(index: 0), same(added));
      expect(_timeline.getCurrentLayer(), same(bottom));
    });

    _test("to an empty frame gives the selection a layer to float over", (final DrawingLayerState bottom) async
    {
      _layers.clear(notify: false);

      final LayerState? added = _manager.addNewLayer(layerType: LayerKind.drawing).$2;
      await settle();

      expect(_timeline.getCurrentLayer(), same(added));
      expect(_selection.selection.isEmpty, isTrue);
    });

    _test("to a full frame is refused", (final DrawingLayerState bottom) async
    {
      _fill(layers: _layers);
      final HistoryState? before = _history.getCurrentState();

      final (LayerActionResult, LayerState?) result = _manager.addNewLayer(layerType: LayerKind.shading);

      expect(result.$1, LayerActionResult.layerLimitReached);
      expect(result.$2, isNull);
      expect(_layers.length, LayerCollection.maxLayers);
      _expectNoUndoStep(before: before);
    });
  });

  group("moving a layer", ()
  {
    _test("goes one place at a time, keeps it selected and can be undone", (final DrawingLayerState bottom) async
    {
      final List<DrawingLayerState> stack = await _stack(bottom: bottom);
      _manager.selectLayer(newLayer: stack[1], addToHistoryStack: false);

      _manager.moveUpLayer(layerState: stack[1]);
      await settle();
      expect(_order(), "bac");
      expect(_timeline.getCurrentLayer(), same(stack[1]));
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerOrderChange);

      _manager.moveDownLayer(layerState: stack[1]);
      _manager.moveDownLayer(layerState: stack[1]);
      await settle();
      expect(_order(), "acb");
      expect(_timeline.getCurrentLayer(), same(stack[1]));

      await _undo();
      expect(_order(), "abc");
    });

    _test("keeps the selection on the selected layer when another one passes it", (final DrawingLayerState bottom) async
    {
      final List<DrawingLayerState> stack = await _stack(bottom: bottom);
      _manager.selectLayer(newLayer: stack[1], addToHistoryStack: false);

      _manager.moveDownLayer(layerState: stack[0]);
      expect(_order(), "bac");
      expect(_timeline.getCurrentLayer(), same(stack[1]));

      _manager.moveUpLayer(layerState: stack[0]);
      expect(_order(), "abc");
      expect(_timeline.getCurrentLayer(), same(stack[1]));
    });

    _test("stays put at either end, without an undo step", (final DrawingLayerState bottom) async
    {
      final List<DrawingLayerState> stack = await _stack(bottom: bottom);
      final HistoryState? before = _history.getCurrentState();

      _manager.moveUpLayer(layerState: stack.first);
      _manager.moveDownLayer(layerState: stack.last);

      expect(_order(), "abc");
      _expectNoUndoStep(before: before);
    });

    _test("does nothing without a layer, or with one of another frame", (final DrawingLayerState bottom) async
    {
      final (Frame _, Frame other) = await _twoFrames();
      final HistoryState? before = _history.getCurrentState();

      _manager.moveUpLayer(layerState: null);
      _manager.moveDownLayer(layerState: null);
      _manager.moveUpLayer(layerState: other.layerList.getLayer(index: 0));
      _manager.moveDownLayer(layerState: other.layerList.getLayer(index: 0));

      _expectNoUndoStep(before: before);
    });
  });

  group("locking a layer", ()
  {
    _test("runs a drawing layer through all three states, each an undo step", (final DrawingLayerState bottom) async
    {
      expect(bottom.lockState.value, LayerLockState.unlocked);

      for (final LayerLockState expected in <LayerLockState>[LayerLockState.transparency, LayerLockState.locked, LayerLockState.unlocked])
      {
        final HistoryState? before = _history.getCurrentState();
        _manager.changeLayerLockState(layerState: bottom);

        expect(bottom.lockState.value, expected);
        expect(_history.getCurrentState(), isNot(same(before)));
        expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerLockChange);
      }
    });

    _test("can be undone", (final DrawingLayerState bottom) async
    {
      _manager.changeLayerLockState(layerState: bottom);
      await settle();

      await _undo();

      expect((_timeline.getCurrentLayer()! as DrawingLayerState).lockState.value, LayerLockState.unlocked);
    });

    for (final LayerKind kind in <LayerKind>[LayerKind.shading, LayerKind.dither])
    {
      _test("has no transparency state on a ${kind.name} layer", (final DrawingLayerState bottom) async
      {
        final ShadingLayerState layer = _add<ShadingLayerState>(kind: kind);

        _manager.changeLayerLockState(layerState: layer);
        expect(layer.lockState.value, LayerLockState.locked);
        expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerLockChange);

        _manager.changeLayerLockState(layerState: layer);
        expect(layer.lockState.value, LayerLockState.unlocked);
      });
    }

    for (final LayerKind kind in <LayerKind>[LayerKind.reference, LayerKind.grid])
    {
      _test("means nothing on a ${kind.name} layer", (final DrawingLayerState bottom) async
      {
        final LayerState layer = _add<LayerState>(kind: kind);
        final HistoryState? before = _history.getCurrentState();

        _manager.changeLayerLockState(layerState: layer);

        _expectNoUndoStep(before: before);
      });
    }

    _test("does nothing without a layer", (final DrawingLayerState bottom) async
    {
      final HistoryState? before = _history.getCurrentState();

      _manager.changeLayerLockState(layerState: null);

      _expectNoUndoStep(before: before);
    });
  });

  group("hiding a layer", ()
  {
    _test("switches it back and forth, each an undo step", (final DrawingLayerState bottom) async
    {
      _manager.changeLayerVisibility(layerState: bottom);
      expect(bottom.visibilityState.value, LayerVisibilityState.hidden);
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerVisibilityChange);

      _manager.changeLayerVisibility(layerState: bottom);
      expect(bottom.visibilityState.value, LayerVisibilityState.visible);
    });

    _test("rasters it again when it comes back", (final DrawingLayerState bottom) async
    {
      _manager.changeLayerVisibility(layerState: bottom);
      await settle();
      expect(bottom.doManualRaster, isFalse);

      _manager.changeLayerVisibility(layerState: bottom);

      expect(bottom.doManualRaster, isTrue);
      await settle();
    });

    _test("does nothing without a layer", (final DrawingLayerState bottom) async
    {
      final HistoryState? before = _history.getCurrentState();

      _manager.changeLayerVisibility(layerState: null);

      _expectNoUndoStep(before: before);
    });
  });

  group("stepping through the layers", ()
  {
    _test("goes up and down and stops at either end", (final DrawingLayerState bottom) async
    {
      final List<DrawingLayerState> stack = await _stack(bottom: bottom);
      expect(_timeline.getCurrentLayer(), same(stack[0]));

      _manager.selectLayerAbove();
      expect(_timeline.getCurrentLayer(), same(stack[0]), reason: "nothing above the top layer");

      _manager.selectLayerBelow();
      expect(_timeline.getCurrentLayer(), same(stack[1]));
      _manager.selectLayerBelow();
      expect(_timeline.getCurrentLayer(), same(stack[2]));

      _manager.selectLayerBelow();
      expect(_timeline.getCurrentLayer(), same(stack[2]), reason: "nothing below the bottom layer");

      _manager.selectLayerAbove();
      expect(_timeline.getCurrentLayer(), same(stack[1]));
    });

    _test("hands a floating selection over, like clicking the layer does", (final DrawingLayerState bottom) async
    {
      final DrawingLayerState upper = _add<DrawingLayerState>(kind: LayerKind.drawing);
      _paint(layer: upper, coord: _pixel, color: _ramp[0]);
      await settle();
      _selection.selectAll();
      await settle();
      expect(upper.getDataEntry(coord: _pixel), isNull, reason: "setup: the pixel floats");

      _manager.selectLayerBelow();
      await settle();

      expect(_timeline.getCurrentLayer(), same(bottom));
      expect(upper.getDataEntry(coord: _pixel), _ramp[0], reason: "the layer that was left gets its pixel back");
      expect(_selection.selection.owner, same(bottom));
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerChangeWithSelection);

      _selection.deselect(addToHistoryStack: false);
      await settle();
      expect(upper.getDataEntry(coord: _pixel), _ramp[0], reason: "deselecting leaves the pixel on its own layer");
      expect(bottom.getDataEntry(coord: _pixel), isNull);
    });

    _test("tells the widgets about it, like clicking the layer does", (final DrawingLayerState bottom) async
    {
      _add<DrawingLayerState>(kind: LayerKind.drawing);
      int reports = 0;
      void listener() {reports++;}
      _timeline.layerChangeNotifier.addListener(listener);
      addTearDown(() {_timeline.layerChangeNotifier.removeListener(listener);});

      _manager.selectLayerBelow();

      expect(reports, greaterThan(0), reason: "the tool bar and the tools follow the kind of layer that is selected");
    });

    _test("is an undo step, like clicking the layer is", (final DrawingLayerState bottom) async
    {
      _add<DrawingLayerState>(kind: LayerKind.drawing);
      await settle();
      _history.addState(identifier: HistoryStateTypeIdentifier.generic);

      _manager.selectLayerBelow();

      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerChange);

      await _undo();
      expect(_layers.selectedLayerIndex, 0);
    });

    _test("adds no undo step at either end", (final DrawingLayerState bottom) async
    {
      final HistoryState? before = _history.getCurrentState();

      _manager.selectLayerAbove();
      _manager.selectLayerBelow();

      _expectNoUndoStep(before: before);
    });
  });

  group("copying a layer to another frame", ()
  {
    _test("gives that frame a layer of its own and moves there", (final DrawingLayerState bottom) async
    {
      _paint(layer: bottom, coord: _pixel, color: _ramp[1]);
      await settle();
      final (Frame _, Frame target) = await _twoFrames();
      final int sizeBefore = target.layerList.length;

      final LayerActionResult result = _manager.copyLayerToOtherFrame(sourceLayer: bottom, targetFrame: target, position: 0);
      await settle();

      expect(result, LayerActionResult.success);
      expect(target.layerList.length, sizeBefore + 1);
      final DrawingLayerState copy = target.layerList.getLayer(index: 0) as DrawingLayerState;
      expect(copy, isNot(same(bottom)));
      expect(copy.getDataEntry(coord: _pixel), _ramp[1]);
      expect(_timeline.selectedFrame, same(target));
      expect(_timeline.getCurrentLayer(), same(copy));
      expect(_timeline.isLayerLinked(layer: bottom), isFalse);
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerDuplicate);

      _paint(layer: copy, coord: _otherPixel, color: _ramp[2]);
      await settle();
      expect(bottom.getDataEntry(coord: _otherPixel), isNull, reason: "the copy is on its own");
    });

    _test("can be undone and redone", (final DrawingLayerState bottom) async
    {
      final (Frame _, Frame target) = await _twoFrames();
      final int sizeBefore = target.layerList.length;
      _history.addState(identifier: HistoryStateTypeIdentifier.generic);

      _manager.copyLayerToOtherFrame(sourceLayer: bottom, targetFrame: target, position: 0);
      await settle();

      await _undo();
      expect(_timeline.frames.value[1].layerList.length, sizeBefore);

      await _redo();
      expect(_timeline.frames.value[1].layerList.length, sizeBefore + 1);
    });

    _test("leaves the history alone when asked to", (final DrawingLayerState bottom) async
    {
      final (Frame _, Frame target) = await _twoFrames();
      final HistoryState? before = _history.getCurrentState();

      expect(_manager.copyLayerToOtherFrame(sourceLayer: bottom, targetFrame: target, position: 0, addToHistoryStack: false), LayerActionResult.success);
      await settle();

      _expectNoUndoStep(before: before);
    });

    _test("is refused at a place the frame does not have", (final DrawingLayerState bottom) async
    {
      final (Frame source, Frame target) = await _twoFrames();
      final HistoryState? before = _history.getCurrentState();
      final int sizeBefore = target.layerList.length;

      expect(_manager.copyLayerToOtherFrame(sourceLayer: bottom, targetFrame: target, position: -1), LayerActionResult.invalidIndex);
      expect(_manager.copyLayerToOtherFrame(sourceLayer: bottom, targetFrame: target, position: sizeBefore + 1), LayerActionResult.invalidIndex);

      expect(target.layerList.length, sizeBefore);
      expect(_timeline.selectedFrame, same(source));
      _expectNoUndoStep(before: before);
    });

    _test("is refused when the frame is full", (final DrawingLayerState bottom) async
    {
      final (Frame source, Frame target) = await _twoFrames();
      _fill(layers: target.layerList);
      final HistoryState? before = _history.getCurrentState();

      expect(_manager.copyLayerToOtherFrame(sourceLayer: bottom, targetFrame: target, position: 0), LayerActionResult.layerLimitReached);

      expect(_timeline.selectedFrame, same(source));
      _expectNoUndoStep(before: before);
    });
  });

  group("linking a layer to another frame", ()
  {
    _test("puts the very same layer there and moves there", (final DrawingLayerState bottom) async
    {
      final (Frame source, Frame target) = await _twoFrames();

      final LayerActionResult result = _manager.linkLayerToOtherFrame(sourceLayer: bottom, targetFrame: target, position: 0);
      await settle();

      expect(result, LayerActionResult.success);
      expect(target.layerList.getLayer(index: 0), same(bottom));
      expect(source.layerList.getLayer(index: 0), same(bottom));
      expect(_timeline.isLayerLinked(layer: bottom), isTrue);
      expect(_timeline.selectedFrame, same(target));
      expect(_timeline.getCurrentLayer(), same(bottom));
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerDuplicate);
    });

    _test("keeps the layer alive until its last frame lets go", (final DrawingLayerState bottom) async
    {
      final (Frame source, Frame target) = await _twoFrames();
      _manager.linkLayerToOtherFrame(sourceLayer: bottom, targetFrame: target, position: 0, addToHistoryStack: false);
      await settle();

      expect(_manager.layerDeletedSelected(deleteLayer: bottom, addToHistoryStack: false), LayerActionResult.success);
      await settle();

      expect(target.layerList.contains(layer: bottom), isFalse);
      expect(source.layerList.contains(layer: bottom), isTrue);
      expect(bottom.isDisposed, isFalse);
      expect(_timeline.isLayerLinked(layer: bottom), isFalse);
    });

    _test("can be undone", (final DrawingLayerState bottom) async
    {
      final (Frame _, Frame target) = await _twoFrames();
      final int sizeBefore = target.layerList.length;
      _history.addState(identifier: HistoryStateTypeIdentifier.generic);

      _manager.linkLayerToOtherFrame(sourceLayer: bottom, targetFrame: target, position: 0);
      await settle();
      await _undo();

      expect(_timeline.frames.value[1].layerList.length, sizeBefore);
    });

    _test("is refused when it is there already", (final DrawingLayerState bottom) async
    {
      final (Frame source, Frame target) = await _twoFrames();
      _manager.linkLayerToOtherFrame(sourceLayer: bottom, targetFrame: target, position: 0, addToHistoryStack: false);
      await settle();
      final HistoryState? before = _history.getCurrentState();
      final int sizeBefore = target.layerList.length;

      expect(_manager.linkLayerToOtherFrame(sourceLayer: bottom, targetFrame: source, position: 0), LayerActionResult.alreadyExists);

      expect(target.layerList.length, sizeBefore);
      _expectNoUndoStep(before: before);
    });

    _test("is refused at a place the frame does not have", (final DrawingLayerState bottom) async
    {
      final (Frame _, Frame target) = await _twoFrames();
      final HistoryState? before = _history.getCurrentState();

      expect(_manager.linkLayerToOtherFrame(sourceLayer: bottom, targetFrame: target, position: -1), LayerActionResult.invalidIndex);
      expect(_manager.linkLayerToOtherFrame(sourceLayer: bottom, targetFrame: target, position: target.layerList.length + 1), LayerActionResult.invalidIndex);

      _expectNoUndoStep(before: before);
    });

    _test("is refused when the frame is full", (final DrawingLayerState bottom) async
    {
      final (Frame _, Frame target) = await _twoFrames();
      _fill(layers: target.layerList);
      final HistoryState? before = _history.getCurrentState();

      expect(_manager.linkLayerToOtherFrame(sourceLayer: bottom, targetFrame: target, position: 0), LayerActionResult.layerLimitReached);

      _expectNoUndoStep(before: before);
    });
  });

  group("duplicating a layer", ()
  {
    _test("puts the copy on top of it and selects that", (final DrawingLayerState bottom) async
    {
      _paint(layer: bottom, coord: _pixel, color: _ramp[1]);
      await settle();

      final (LayerActionResult, LayerState?) result = _manager.layerDuplicateSelected(duplicateLayer: bottom);
      await settle();

      expect(result.$1, LayerActionResult.success);
      expect(_layers.getLayer(index: 0), same(result.$2));
      expect(_layers.getLayer(index: 1), same(bottom));
      expect((result.$2! as DrawingLayerState).getDataEntry(coord: _pixel), _ramp[1]);
      expect(_timeline.getCurrentLayer(), same(result.$2));
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerDuplicate);
    });

    _test("above the selected layer leaves that one selected", (final DrawingLayerState bottom) async
    {
      final DrawingLayerState upper = _add<DrawingLayerState>(kind: LayerKind.drawing);
      _manager.selectLayer(newLayer: bottom, addToHistoryStack: false);
      await settle();

      _manager.layerDuplicateSelected(duplicateLayer: upper);
      await settle();

      expect(_layers.length, 3);
      expect(_timeline.getCurrentLayer(), same(bottom));
    });

    _test("below the selected layer leaves that one selected", (final DrawingLayerState bottom) async
    {
      final DrawingLayerState upper = _add<DrawingLayerState>(kind: LayerKind.drawing);
      await settle();

      _manager.layerDuplicateSelected(duplicateLayer: bottom);
      await settle();

      expect(_layers.length, 3);
      expect(_timeline.getCurrentLayer(), same(upper));
    });

    _test("leaves the history alone when asked to", (final DrawingLayerState bottom) async
    {
      final HistoryState? before = _history.getCurrentState();

      _manager.layerDuplicateSelected(duplicateLayer: bottom, addToHistoryStack: false);
      await settle();

      _expectNoUndoStep(before: before);
    });

    _test("does nothing without a layer", (final DrawingLayerState bottom) async
    {
      final HistoryState? before = _history.getCurrentState();

      final (LayerActionResult, LayerState?) result = _manager.layerDuplicateSelected(duplicateLayer: null);

      expect(result.$1, LayerActionResult.unknownError);
      expect(result.$2, isNull);
      _expectNoUndoStep(before: before);
    });

    _test("is refused when the frame is full", (final DrawingLayerState bottom) async
    {
      _fill(layers: _layers);

      final (LayerActionResult, LayerState?) result = _manager.layerDuplicateSelected(duplicateLayer: bottom);

      expect(result.$1, LayerActionResult.layerLimitReached);
      expect(result.$2, isNull);
      expect(_layers.length, LayerCollection.maxLayers);
    });

    _test("adds no undo step when it is refused", (final DrawingLayerState bottom) async
    {
      _fill(layers: _layers);
      final HistoryState? before = _history.getCurrentState();

      _manager.layerDuplicateSelected(duplicateLayer: bottom);

      _expectNoUndoStep(before: before);
    });
  });

  group("merging a layer", ()
  {
    _test("into the one below keeps what is on top and shows what is not covered", (final DrawingLayerState bottom) async
    {
      final DrawingLayerState upper = _add<DrawingLayerState>(kind: LayerKind.drawing);
      _paint(layer: upper, coord: _pixel, color: _ramp[1]);
      bottom.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{_pixel: _ramp[2], _otherPixel: _ramp[3]}));
      await settle();
      _history.addState(identifier: HistoryStateTypeIdentifier.generic);

      expect(_manager.layerMerged(mergeLayer: upper), LayerActionResult.success);
      await settle();

      expect(_layers.length, 1);
      expect(_layers.getLayer(index: 0), same(upper));
      expect(_timeline.getCurrentLayer(), same(upper));
      expect(upper.getDataEntry(coord: _pixel), _ramp[1]);
      expect(upper.getDataEntry(coord: _otherPixel), _ramp[3]);
      expect(bottom.isDisposed, isTrue);
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerMerge);

      await _undo();
      expect(_layers.length, 2);
      final DrawingLayerState upperBack = _layers.getLayer(index: 0) as DrawingLayerState;
      final DrawingLayerState bottomBack = _layers.getLayer(index: 1) as DrawingLayerState;
      expect(upperBack.getDataEntry(coord: _otherPixel), isNull);
      expect(bottomBack.getDataEntry(coord: _pixel), _ramp[2]);

      await _redo();
      expect(_layers.length, 1);
      final DrawingLayerState merged = _layers.getLayer(index: 0) as DrawingLayerState;
      expect(merged.getDataEntry(coord: _pixel), _ramp[1]);
      expect(merged.getDataEntry(coord: _otherPixel), _ramp[3]);
    });

    _test("drops a floating selection first", (final DrawingLayerState bottom) async
    {
      final DrawingLayerState upper = _add<DrawingLayerState>(kind: LayerKind.drawing);
      _paint(layer: upper, coord: _pixel, color: _ramp[1]);
      await settle();
      _selection.selectAll();
      await settle();

      expect(_manager.layerMerged(mergeLayer: upper), LayerActionResult.success);
      await settle();

      expect(_selection.selection.isEmpty, isTrue);
      expect(upper.getDataEntry(coord: _pixel), _ramp[1]);
    });

    _test("while the layer below is selected", (final DrawingLayerState bottom) async
    {
      final DrawingLayerState upper = _add<DrawingLayerState>(kind: LayerKind.drawing);
      _manager.selectLayer(newLayer: bottom, addToHistoryStack: false);
      await settle();

      expect(_manager.layerMerged(mergeLayer: upper), LayerActionResult.success);
      await settle();

      expect(_layers.length, 1);
      expect(_timeline.getCurrentLayer(), same(upper));
    });

    _test("while a layer further down is selected", (final DrawingLayerState bottom) async
    {
      final List<DrawingLayerState> stack = await _stack(bottom: bottom);
      _manager.selectLayer(newLayer: stack[2], addToHistoryStack: false);
      await settle();

      expect(_manager.layerMerged(mergeLayer: stack[0]), LayerActionResult.success);
      await settle();

      expect(_layers.length, 2);
    });

    _test("is refused for the bottom layer", (final DrawingLayerState bottom) async
    {
      final HistoryState? before = _history.getCurrentState();

      expect(_manager.layerMerged(mergeLayer: bottom), LayerActionResult.noLayerBelow);

      _expectNoUndoStep(before: before);
    });

    _test("does nothing without a layer", (final DrawingLayerState bottom) async
    {
      expect(_manager.layerMerged(mergeLayer: null), LayerActionResult.unknownError);
    });

    _test("is refused for anything but a drawing layer", (final DrawingLayerState bottom) async
    {
      final LayerState reference = _add<LayerState>(kind: LayerKind.reference);

      expect(_manager.layerMerged(mergeLayer: reference), LayerActionResult.onlyMergeDrawingLayers);
    });

    _test("is refused into anything but a drawing layer", (final DrawingLayerState bottom) async
    {
      _add<LayerState>(kind: LayerKind.reference);
      final DrawingLayerState upper = _add<DrawingLayerState>(kind: LayerKind.drawing);

      expect(_manager.layerMerged(mergeLayer: upper), LayerActionResult.onlyMergeDrawingLayers);
    });

    for (final (String, LayerActionResult, void Function(DrawingLayerState upper, DrawingLayerState lower)) refusal in <(String, LayerActionResult, void Function(DrawingLayerState, DrawingLayerState))>[
      ("a hidden layer", LayerActionResult.invisibleLayerMergeFrom, (final DrawingLayerState upper, final DrawingLayerState lower) {upper.visibilityState.value = LayerVisibilityState.hidden;}),
      ("into a hidden layer", LayerActionResult.invisibleLayerMergeTo, (final DrawingLayerState upper, final DrawingLayerState lower) {lower.visibilityState.value = LayerVisibilityState.hidden;}),
      ("a locked layer", LayerActionResult.lockedLayerMergeFrom, (final DrawingLayerState upper, final DrawingLayerState lower) {upper.lockState.value = LayerLockState.locked;}),
      ("into a locked layer", LayerActionResult.lockedLayerMergeTo, (final DrawingLayerState upper, final DrawingLayerState lower) {lower.lockState.value = LayerLockState.locked;}),
      ("a layer with effects", LayerActionResult.effectLayerMerge, (final DrawingLayerState upper, final DrawingLayerState lower) {upper.settings.outerStrokeStyle.value = OuterStrokeStyle.solid;}),
      ("into a layer with effects", LayerActionResult.effectLayerMerge, (final DrawingLayerState upper, final DrawingLayerState lower) {lower.settings.dropShadowStyle.value = DropShadowStyle.solid;}),
    ])
    {
      _test("is refused for ${refusal.$1}", (final DrawingLayerState bottom) async
      {
        final DrawingLayerState upper = _add<DrawingLayerState>(kind: LayerKind.drawing);
        refusal.$3(upper, bottom);
        final HistoryState? before = _history.getCurrentState();

        expect(_manager.layerMerged(mergeLayer: upper), refusal.$2);

        expect(_layers.length, 2);
        _expectNoUndoStep(before: before);
        upper.settings.outerStrokeStyle.value = OuterStrokeStyle.off;
        await settle();
      });
    }

    _test("is refused for a linked layer", (final DrawingLayerState bottom) async
    {
      final DrawingLayerState upper = _add<DrawingLayerState>(kind: LayerKind.drawing);
      await settle();
      final (Frame _, Frame target) = await _twoFrames();
      _manager.linkLayerToOtherFrame(sourceLayer: upper, targetFrame: target, position: 0, addToHistoryStack: false);
      _timeline.selectFrameByIndex(index: 0, addLayerSelectionToHistory: false);
      await settle();

      expect(_manager.layerMerged(mergeLayer: upper), LayerActionResult.linkedLayerMergeFrom);
    });

    _test("is refused into a linked layer", (final DrawingLayerState bottom) async
    {
      final DrawingLayerState upper = _add<DrawingLayerState>(kind: LayerKind.drawing);
      await settle();
      final (Frame _, Frame target) = await _twoFrames();
      _manager.linkLayerToOtherFrame(sourceLayer: bottom, targetFrame: target, position: 0, addToHistoryStack: false);
      _timeline.selectFrameByIndex(index: 0, addLayerSelectionToHistory: false);
      await settle();

      expect(_manager.layerMerged(mergeLayer: upper), LayerActionResult.linkedLayerMergeTo);
    });
  });

  group("rastering", ()
  {
    group("a grid layer", ()
    {
      _test("replaces it by a drawing layer in the selected color, at the same place", (final DrawingLayerState bottom) async
      {
        final GridLayerState grid = _add<GridLayerState>(kind: LayerKind.grid);
        await settle();
        final Set<CoordinateSetI> lines = await grid.getRasterData();
        expect(lines, isNotEmpty, reason: "setup: a grid with lines on this canvas");
        final ColorReference color = GetIt.I.get<PaletteState>().selectedColor!;

        _manager.layerRasterPressed(rasterLayer: grid);
        await _until(condition: () => _layers.getLayer(index: 0) is DrawingLayerState);

        final DrawingLayerState drawing = _layers.getLayer(index: 0) as DrawingLayerState;
        expect(_layers.length, 2);
        expect(_layers.getLayer(index: 1), same(bottom));
        expect(_timeline.getCurrentLayer(), same(drawing));
        expect(grid.isDisposed, isTrue);
        for (final CoordinateSetI line in lines)
        {
          expect(drawing.getDataEntry(coord: line), color);
        }
        expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerRaster);
      });

      _test("tells the widgets once the new layer is there", (final DrawingLayerState bottom) async
      {
        final GridLayerState grid = _add<GridLayerState>(kind: LayerKind.grid);
        await settle();
        final List<LayerKind?> reported = <LayerKind?>[];
        void listener() {reported.add(_timeline.getCurrentLayer()?.kind);}
        _timeline.layerChangeNotifier.addListener(listener);
        addTearDown(() {_timeline.layerChangeNotifier.removeListener(listener);});

        _manager.layerRasterPressed(rasterLayer: grid);
        await _until(condition: () => reported.isNotEmpty);

        expect(reported, <LayerKind>[LayerKind.drawing], reason: "the tools follow the kind of layer that is selected");
      });

      _test("keeps a hidden grid hidden", (final DrawingLayerState bottom) async
      {
        final GridLayerState grid = _add<GridLayerState>(kind: LayerKind.grid);
        grid.visibilityState.value = LayerVisibilityState.hidden;

        _manager.layerRasterPressed(rasterLayer: grid, addToHistoryStack: false);
        await _until(condition: () => _layers.getLayer(index: 0) is DrawingLayerState);

        expect(_layers.getLayer(index: 0).visibilityState.value, LayerVisibilityState.hidden);
      });

      _test("can be undone", (final DrawingLayerState bottom) async
      {
        final GridLayerState grid = _add<GridLayerState>(kind: LayerKind.grid);
        await settle();
        _history.addState(identifier: HistoryStateTypeIdentifier.generic);

        _manager.layerRasterPressed(rasterLayer: grid);
        await _until(condition: () => _layers.getLayer(index: 0) is DrawingLayerState);
        await _undo();

        expect(_layers.getLayer(index: 0), isA<GridLayerState>());
      });

      _test("can be redone", (final DrawingLayerState bottom) async
      {
        final GridLayerState grid = _add<GridLayerState>(kind: LayerKind.grid);
        await settle();
        _history.addState(identifier: HistoryStateTypeIdentifier.generic);

        _manager.layerRasterPressed(rasterLayer: grid);
        await _until(condition: () => _layers.getLayer(index: 0) is DrawingLayerState);
        await _undo();
        await _redo();

        expect(_layers.getLayer(index: 0), isA<DrawingLayerState>());
      });
    });

    group("a shading layer", ()
    {
      ShadingLayerState shadeAbove({required final DrawingLayerState layer})
      {
        _paint(layer: layer, coord: _pixel, color: _ramp[3]);
        final ShadingLayerState shading = _add<ShadingLayerState>(kind: LayerKind.shading);
        shading.addCoords(coords: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{_pixel: 1}));
        return shading;
      }

      _test("can be undone", (final DrawingLayerState bottom) async
      {
        final ShadingLayerState shading = shadeAbove(layer: bottom);
        await settle();
        _history.addState(identifier: HistoryStateTypeIdentifier.generic);

        _manager.layerRasterPressed(rasterLayer: shading);
        await settle();
        expect(_layers.length, 1);
        expect((_layers.getLayer(index: 0) as DrawingLayerState).getDataEntry(coord: _pixel), _ramp[4]);

        await _undo();

        expect(_layers.length, 2);
        expect(_layers.getLayer(index: 0), isA<ShadingLayerState>());
        expect((_layers.getLayer(index: 1) as DrawingLayerState).getDataEntry(coord: _pixel), _ramp[3]);
      });

      _test("can be redone", (final DrawingLayerState bottom) async
      {
        final ShadingLayerState shading = shadeAbove(layer: bottom);
        await settle();
        _history.addState(identifier: HistoryStateTypeIdentifier.generic);

        _manager.layerRasterPressed(rasterLayer: shading);
        await settle();
        await _undo();
        await _redo();

        expect(_layers.length, 1);
        expect((_layers.getLayer(index: 0) as DrawingLayerState).getDataEntry(coord: _pixel), _ramp[4]);
      });

      _test("reaches the pixels of a floating selection below it", (final DrawingLayerState bottom) async
      {
        final ShadingLayerState shading = shadeAbove(layer: bottom);
        _manager.selectLayer(newLayer: bottom, addToHistoryStack: false);
        await settle();
        _selection.selectAll();
        await settle();
        expect(bottom.getDataEntry(coord: _pixel), isNull, reason: "setup: the pixel floats");

        _manager.layerRasterPressed(rasterLayer: shading, addToHistoryStack: false);
        await settle();

        expect(_selection.selection.isEmpty, isTrue);
        expect(bottom.getDataEntry(coord: _pixel), _ramp[4]);
      });

      _test("leaves no selection behind that belongs to it", (final DrawingLayerState bottom) async
      {
        final ShadingLayerState shading = shadeAbove(layer: bottom);
        _manager.selectLayer(newLayer: bottom, addToHistoryStack: false);
        await settle();
        _selection.selectAll();
        await settle();
        _manager.selectLayer(newLayer: shading, addToHistoryStack: false);
        await settle();

        _manager.layerRasterPressed(rasterLayer: shading, addToHistoryStack: false);
        await settle();

        expect(_selection.selection.isEmpty, isTrue);
        expect(_timeline.getCurrentLayer(), same(bottom));
        expect(bottom.getDataEntry(coord: _pixel), _ramp[4]);
      });

      _test("only reaches the visible layers below it", (final DrawingLayerState bottom) async
      {
        final ShadingLayerState shading = shadeAbove(layer: bottom);
        final DrawingLayerState above = _add<DrawingLayerState>(kind: LayerKind.drawing);
        _paint(layer: above, coord: _pixel, color: _ramp[2]);
        bottom.visibilityState.value = LayerVisibilityState.hidden;
        await settle();

        _manager.layerRasterPressed(rasterLayer: shading, addToHistoryStack: false);
        await settle();

        expect(above.getDataEntry(coord: _pixel), _ramp[2], reason: "it is above the shading");
        expect(bottom.getDataEntry(coord: _pixel), _ramp[3], reason: "it is hidden");
        bottom.visibilityState.value = LayerVisibilityState.visible;
      });
    });

    group("a dither layer", ()
    {
      _test("shifts only the pixels its pattern reaches", (final DrawingLayerState bottom) async
      {
        final Set<CoordinateSetI> block = <CoordinateSetI>{
          for (int x = 0; x < 4; x++)
            for (int y = 0; y < 4; y++) CoordinateSetI(x: x, y: y),
        };
        bottom.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{for (final CoordinateSetI c in block) c: _ramp[3]}));
        final DitherLayerState dither = _add<DitherLayerState>(kind: LayerKind.dither);
        dither.addCoords(coords: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{for (final CoordinateSetI c in block) c: 2}));
        await settle();
        final Map<CoordinateSetI, int> pattern = <CoordinateSetI, int>{for (final CoordinateSetI c in block) c: dither.getDisplayValueAt(coord: c)};
        expect(pattern.values.toSet().length, greaterThan(1), reason: "setup: some pixels shifted, some not");

        _manager.layerRasterPressed(rasterLayer: dither, addToHistoryStack: false);
        await settle();

        expect(_layers.length, 1);
        for (final CoordinateSetI c in block)
        {
          expect(bottom.getDataEntry(coord: c), _ramp[3].shiftedBy(steps: pattern[c]!), reason: "at $c");
        }
      });
    });
  });

  group("deleting a layer", ()
  {
    _test("does nothing without a layer", (final DrawingLayerState bottom) async
    {
      expect(_manager.layerDeletedSelected(deleteLayer: null), LayerActionResult.unknownError);
    });

    _test("is refused for the last one", (final DrawingLayerState bottom) async
    {
      final HistoryState? before = _history.getCurrentState();

      expect(_manager.layerDeletedSelected(deleteLayer: bottom), LayerActionResult.lastLayerDelete);

      expect(_layers.length, 1);
      expect(bottom.isDisposed, isFalse);
      _expectNoUndoStep(before: before);
    });
  });

  group("a frame's layers", ()
  {
    _test("say what they hold", (final DrawingLayerState bottom) async
    {
      expect(_layers.isNotEmpty, isTrue);
      expect(_layers.first, same(bottom));
      expect(_layers.getLayerPosition(state: bottom), 0);
      expect(LayerCollection.empty().isEmpty, isTrue);
    });

    _test("start on the first one if the given index is off", (final DrawingLayerState bottom) async
    {
      final LayerCollection layers = LayerCollection(layers: <LayerState>[bottom], selLayerIdx: 5);

      expect(layers.selectedLayerIndex, 0);
      expect(layers.getSelectedLayer(), same(bottom));
    });

    _test("drop what does not fit", (final DrawingLayerState bottom) async
    {
      final List<LayerState> tooMany = <LayerState>[
        for (int i = 0; i < LayerCollection.maxLayers + 2; i++) _layers.addNewReferenceLayer().$2 ?? bottom,
      ];

      final LayerCollection layers = LayerCollection(layers: tooMany, selLayerIdx: 0);

      expect(layers.length, LayerCollection.maxLayers);
    });

    _test("can be replaced by none at all", (final DrawingLayerState bottom) async
    {
      final LayerCollection layers = LayerCollection(layers: <LayerState>[bottom], selLayerIdx: 0);

      layers.replaceLayers(layers: <LayerState>[], selLayerIdx: 3);

      expect(layers.selectedLayerIndex, isNull);
      expect(layers.getSelectedLayer(), isNull);
    });

    _test("can be cleared, which disposes those no other frame holds", (final DrawingLayerState bottom) async
    {
      final (Frame source, Frame target) = await _twoFrames();
      final LayerState unused = target.layerList.getLayer(index: 0);
      _manager.linkLayerToOtherFrame(sourceLayer: bottom, targetFrame: target, position: 0, addToHistoryStack: false);
      _timeline.selectFrameByIndex(index: 0, addLayerSelectionToHistory: false);
      await settle();
      int notifications = 0;
      void listener() {notifications++;}
      target.layerList.addListener(listener);
      addTearDown(() {target.layerList.removeListener(listener);});

      target.layerList.clear(notify: false);
      expect(notifications, 0);
      expect(target.layerList.isEmpty, isTrue);
      expect(target.layerList.selectedLayerIndex, isNull);
      expect(unused.isDisposed, isTrue);
      expect(bottom.isDisposed, isFalse, reason: "the other frame still holds it");
      expect(source.layerList.contains(layer: bottom), isTrue);

      target.layerList.clear();
      expect(notifications, 1);
    });

    _test("keep a dependent that is busy on the list instead of dropping the request", (final DrawingLayerState bottom) async
    {
      final ShadingLayerState shading = _add<ShadingLayerState>(kind: LayerKind.shading);
      await settle();
      _layers.lockLayerForRendering(layer: shading);
      expect(shading.doManualRaster, isFalse);

      _layers.invalidateDependents(layer: bottom);

      expect(shading.doManualRaster, isTrue);
      _layers.unlockLayerFromRendering(layer: shading);
      await settle();
    });

    group("read a color off the canvas", ()
    {
      _test("through the shading above it, unless asked for the raw one", (final DrawingLayerState bottom) async
      {
        _paint(layer: bottom, coord: _pixel, color: _ramp[3]);
        final ShadingLayerState shading = _add<ShadingLayerState>(kind: LayerKind.shading);
        shading.addCoords(coords: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{_pixel: 1}));
        await settle();

        expect(_layers.getColorFromImageAtPosition(normPos: _pixel, selectionReference: null, rawMode: false), _ramp[4]);
        expect(_layers.getColorFromImageAtPosition(normPos: _pixel, selectionReference: null, rawMode: true), _ramp[3]);
      });

      _test("not through a hidden shading", (final DrawingLayerState bottom) async
      {
        _paint(layer: bottom, coord: _pixel, color: _ramp[3]);
        final ShadingLayerState shading = _add<ShadingLayerState>(kind: LayerKind.shading);
        shading.addCoords(coords: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{_pixel: 1}));
        shading.visibilityState.value = LayerVisibilityState.hidden;
        await settle();

        expect(_layers.getColorFromImageAtPosition(normPos: _pixel, selectionReference: null, rawMode: false), _ramp[3]);
      });

      _test("from the floating selection on the selected layer", (final DrawingLayerState bottom) async
      {
        _paint(layer: bottom, coord: _pixel, color: _ramp[3]);
        await settle();

        expect(_layers.getColorFromImageAtPosition(normPos: _pixel, selectionReference: _ramp[0], rawMode: false), _ramp[0]);
      });

      _test("from an effect of the selected layer rather than the floating selection, unless asked for the raw one", (final DrawingLayerState bottom) async
      {
        final CoordinateSetI right = CoordinateSetI(x: _pixel.x + 1, y: _pixel.y);
        _paint(layer: bottom, coord: _pixel, color: _ramp[1]);
        bottom.settings.outerColorReference.value = _ramp[3];
        bottom.settings.outerSelectionMap.value = HashMap<Alignment, bool>.of(<Alignment, bool>{
          for (final Alignment direction in bottom.settings.outerSelectionMap.value.keys) direction: direction == Alignment.centerRight,
        });
        bottom.settings.outerStrokeStyle.value = OuterStrokeStyle.solid;
        await settle();

        expect(_layers.getColorFromImageAtPosition(normPos: right, selectionReference: _ramp[0], rawMode: false), _ramp[3]);
        expect(_layers.getColorFromImageAtPosition(normPos: right, selectionReference: _ramp[0], rawMode: true), _ramp[0]);

        bottom.settings.outerStrokeStyle.value = OuterStrokeStyle.off;
        await settle();
      });

      _test("from nothing where there is nothing", (final DrawingLayerState bottom) async
      {
        expect(_layers.getColorFromImageAtPosition(normPos: _pixel, selectionReference: null, rawMode: false), isNull);
      });
    });
  });
}
