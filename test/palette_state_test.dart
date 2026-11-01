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

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/models/tool_type.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

final CoordinateSetI _pixel = CoordinateSetI(x: 1, y: 1);

PaletteState get _palette => GetIt.I.get<PaletteState>();
HistoryManager get _history => GetIt.I.get<HistoryManager>();
Timeline get _timeline => GetIt.I.get<DocumentState>().timeline;
ToolState get _tools => GetIt.I.get<ToolState>();

void _test(final String description, final Future<void> Function(DrawingLayerState layer) body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 4, y: 4), body: (final ProjectSession projectSession) async
    {
      await body(layerAt(projectSession: projectSession, index: 0));
    },);
  });
}

void _paint({required final DrawingLayerState layer, required final ColorReference color})
{
  layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{_pixel: color}));
}

List<KPalRampData> _newRamps({required final int count})
{
  return <KPalRampData>[
    for (int i = 0; i < count; i++) KPalRampData(uuid: "new ramp $i", settings: KPalRampSettings()),
  ];
}

void main()
{
  group("whether the project has pixels", ()
  {
    _test("is no on an empty canvas", (final DrawingLayerState layer) async
    {
      expect(_palette.projectHasPixels(), isFalse);
    });

    _test("is yes with a single pixel", (final DrawingLayerState layer) async
    {
      _paint(layer: layer, color: _palette.colorRamps.last.references.last);
      await settle();

      expect(_palette.projectHasPixels(), isTrue);
    });

    _test("counts hidden layers, whose pixels a palette change affects as well", (final DrawingLayerState layer) async
    {
      _paint(layer: layer, color: _palette.colorRamps[0].references[0]);
      await settle();
      layer.visibilityState.value = LayerVisibilityState.hidden;

      expect(_palette.projectHasPixels(), isTrue);
    });

    _test("counts the frames that are not selected", (final DrawingLayerState layer) async
    {
      _paint(layer: layer, color: _palette.colorRamps[0].references[0]);
      await settle();
      _timeline.addNewFrameRight();
      await settle();

      expect(_timeline.selectedFrame!.layerList.contains(layer: layer), isFalse, reason: "setup: another frame is selected");
      expect(_palette.projectHasPixels(), isTrue);
    });

    _test("does not count shading, which has no colors of its own", (final DrawingLayerState layer) async
    {
      GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.shading);
      await settle();

      expect(_palette.projectHasPixels(), isFalse);
    });
  });

  group("counting the pixels of a ramp", ()
  {
    _test("can leave out the hidden layers", (final DrawingLayerState layer) async
    {
      final KPalRampData ramp = _palette.colorRamps[0];
      _paint(layer: layer, color: ramp.references[0]);
      await settle();
      layer.visibilityState.value = LayerVisibilityState.hidden;

      expect(_palette.getPixelCountForRamp(ramp: ramp), 1);
      expect(_palette.getPixelCountForRamp(ramp: ramp, includeInvisible: false), 0);
    });
  });

  group("appending a palette", ()
  {
    _test("adds its ramps behind the others and leaves everything else alone", (final DrawingLayerState layer) async
    {
      final List<KPalRampData> before = List<KPalRampData>.of(_palette.colorRamps);
      final ColorReference color = before[1].references[2];
      _paint(layer: layer, color: color);
      await settle();
      _palette.colorSelected(color: color, addToHistory: false);
      final List<KPalRampData> added = _newRamps(count: 2);
      int notifications = 0;
      void listener() {notifications++;}
      _palette.colorRampNotifier.addListener(listener);
      addTearDown(() {_palette.colorRampNotifier.removeListener(listener);});

      expect(_palette.appendPalette(loadPaletteSet: LoadPaletteSet(status: "", rampData: added)), PaletteActionResult.success);

      expect(_palette.colorRamps, <KPalRampData>[...before, ...added]);
      expect(_palette.selectedColor, color);
      expect(layer.getDataEntry(coord: _pixel), color);
      expect(notifications, 1);
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.kPalAdd);
    });

    _test("can be undone", (final DrawingLayerState layer) async
    {
      final int rampCount = _palette.colorRamps.length;
      _history.addState(identifier: HistoryStateTypeIdentifier.generic);

      _palette.appendPalette(loadPaletteSet: LoadPaletteSet(status: "", rampData: _newRamps(count: 2)));
      await settle();
      await GetIt.I.get<HistoryController>().undoPressed()!.restore;
      await settle();

      expect(_palette.colorRamps, hasLength(rampCount));
    });

    for (final (String, List<KPalRampData>?) nothing in <(String, List<KPalRampData>?)>[("no ramp list", null), ("an empty ramp list", <KPalRampData>[])])
    {
      _test("fails with ${nothing.$1}", (final DrawingLayerState layer) async
      {
        final HistoryState? before = _history.getCurrentState();
        final int rampCount = _palette.colorRamps.length;

        expect(_palette.appendPalette(loadPaletteSet: LoadPaletteSet(status: "broken", rampData: nothing.$2)), PaletteActionResult.loadingFailed);

        expect(_palette.colorRamps, hasLength(rampCount));
        expect(_history.getCurrentState(), same(before));
      });
    }

    _test("stops at the most ramps a palette may have", (final DrawingLayerState layer) async
    {
      final int rampCount = _palette.colorRamps.length;
      final int free = KPalConstraints.rampCountMax - rampCount;
      final HistoryState? before = _history.getCurrentState();

      expect(_palette.appendPalette(loadPaletteSet: LoadPaletteSet(status: "", rampData: _newRamps(count: free + 1))), PaletteActionResult.rampCountMaxReached);

      expect(_palette.colorRamps, hasLength(rampCount), reason: "all or nothing");
      expect(_history.getCurrentState(), same(before));
    });

    _test("may fill up the palette exactly", (final DrawingLayerState layer) async
    {
      final int free = KPalConstraints.rampCountMax - _palette.colorRamps.length;

      expect(_palette.appendPalette(loadPaletteSet: LoadPaletteSet(status: "", rampData: _newRamps(count: free))), PaletteActionResult.success);

      expect(_palette.colorRamps, hasLength(KPalConstraints.rampCountMax));
    });
  });

  group("replacing the palette", ()
  {
    for (final (String, List<KPalRampData>?) nothing in <(String, List<KPalRampData>?)>[("no ramp list", null), ("an empty ramp list", <KPalRampData>[])])
    {
      _test("fails with ${nothing.$1}", (final DrawingLayerState layer) async
      {
        final HistoryState? before = _history.getCurrentState();

        expect(_palette.replacePalette(loadPaletteSet: LoadPaletteSet(status: "broken", rampData: nothing.$2), paletteReplaceBehavior: PaletteReplaceBehavior.replace), PaletteActionResult.loadingFailed);

        expect(_history.getCurrentState(), same(before));
      });
    }

    _test("is named as such in the history", (final DrawingLayerState layer) async
    {
      _palette.replacePalette(loadPaletteSet: LoadPaletteSet(status: "", rampData: _newRamps(count: 2)), paletteReplaceBehavior: PaletteReplaceBehavior.replace);
      await settle();

      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.kPalPaletteReplace);
    });
  });

  group("stepping through the colors", ()
  {
    _test("goes on within a ramp", (final DrawingLayerState layer) async
    {
      final List<ColorReference> ramp = _palette.colorRamps[0].references;
      _palette.colorSelected(color: ramp[1], addToHistory: false);

      _palette.incrementColorSelection();
      expect(_palette.selectedColor, ramp[2]);

      _palette.decrementColorSelection();
      _palette.decrementColorSelection();
      expect(_palette.selectedColor, ramp[0]);
    });

    _test("goes on across ramps", (final DrawingLayerState layer) async
    {
      final List<KPalRampData> ramps = _palette.colorRamps;
      _palette.colorSelected(color: ramps[0].references.last, addToHistory: false);

      _palette.incrementColorSelection();
      expect(_palette.selectedColor, ramps[1].references.first);

      _palette.decrementColorSelection();
      expect(_palette.selectedColor, ramps[0].references.last);
    });

    _test("wraps around at both ends of the palette", (final DrawingLayerState layer) async
    {
      final List<KPalRampData> ramps = _palette.colorRamps;
      _palette.colorSelected(color: ramps.last.references.last, addToHistory: false);

      _palette.incrementColorSelection();
      expect(_palette.selectedColor, ramps.first.references.first);

      _palette.decrementColorSelection();
      expect(_palette.selectedColor, ramps.last.references.last);
    });

    _test("is an undo step", (final DrawingLayerState layer) async
    {
      _palette.incrementColorSelection();

      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.colorChange);
    });

    _test("does nothing while the color is not in the palette", (final DrawingLayerState layer) async
    {
      final ColorReference foreign = _newRamps(count: 1).first.references.first;
      _palette.selectedColor = foreign;
      final HistoryState? before = _history.getCurrentState();

      _palette.incrementColorSelection();
      _palette.decrementColorSelection();

      expect(_palette.selectedColor, same(foreign));
      expect(_history.getCurrentState(), same(before));
    });
  });

  group("selecting a color", ()
  {
    _test("does nothing if it is selected already", (final DrawingLayerState layer) async
    {
      final HistoryState? before = _history.getCurrentState();

      _palette.colorSelected(color: _palette.selectedColor);

      expect(_history.getCurrentState(), same(before));
    });

    _test("brings back the drawing tool", (final DrawingLayerState layer) async
    {
      _tools.setToolSelection(tool: ToolType.line);
      _tools.setToolSelection(tool: ToolType.select);

      _palette.colorSelected(color: _palette.colorRamps[1].references[1]);

      expect(_tools.selectedTool, ToolType.line);
    });

    _test("keeps a drawing tool that is selected", (final DrawingLayerState layer) async
    {
      _tools.setToolSelection(tool: ToolType.line);
      _tools.setToolSelection(tool: ToolType.fill);

      _palette.colorSelected(color: _palette.colorRamps[1].references[1]);

      expect(_tools.selectedTool, ToolType.fill);
    });
  });

  group("adjusting the palette", ()
  {
    _test("tells everybody, rasters the layers and is an undo step", (final DrawingLayerState layer) async
    {
      int notifications = 0;
      void listener() {notifications++;}
      _palette.colorRampNotifier.addListener(listener);
      addTearDown(() {_palette.colorRampNotifier.removeListener(listener);});

      _palette.paletteAdjusted();

      expect(notifications, 1);
      expect(layer.doManualRaster, isTrue);
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.kPalAdjust);
      await settle();
    });

    _test("leaves the history alone during a preview", (final DrawingLayerState layer) async
    {
      final HistoryState? before = _history.getCurrentState();

      _palette.paletteAdjusted(addToHistoryStack: false);

      expect(_history.getCurrentState(), same(before));
      await settle();
    });
  });

  group("adding a ramp", ()
  {
    _test("puts it last, selects its first color and is an undo step", (final DrawingLayerState layer) async
    {
      final List<KPalRampData> before = List<KPalRampData>.of(_palette.colorRamps);

      final (PaletteActionResult, KPalRampData?) result = await _palette.addNewRamp();

      expect(result.$1, PaletteActionResult.success);
      expect(_palette.colorRamps, <KPalRampData>[...before, result.$2!]);
      expect(_palette.selectedColor, result.$2!.references.first);
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.kPalAdd);
    });

    _test("leaves the history alone when asked to", (final DrawingLayerState layer) async
    {
      final HistoryState? before = _history.getCurrentState();

      await _palette.addNewRamp(addToHistoryStack: false);

      expect(_history.getCurrentState(), same(before));
    });
  });

  group("changing the colors of a ramp", ()
  {
    void changeColorCount({required final KPalRampData ramp, required final int colorCount})
    {
      final KPalRampData original = KPalRampData.from(other: ramp);
      ramp.settings.colorCount = colorCount;
      ramp.updateColors(colorCountChanged: true);
      _palette.updateRamp(ramp: ramp, originalData: original);
    }

    _test("keeps the selected color in that ramp, at its new place", (final DrawingLayerState layer) async
    {
      final KPalRampData ramp = _palette.colorRamps[0];
      final int count = ramp.references.length;
      _palette.colorSelected(color: ramp.references.last, addToHistory: false);

      changeColorCount(ramp: ramp, colorCount: count - 2);

      expect(ramp.references, hasLength(count - 2));
      expect(_palette.selectedColor, ramp.references.last);
      await settle();
    });

    _test("leaves a selected color of another ramp alone", (final DrawingLayerState layer) async
    {
      final KPalRampData other = _palette.colorRamps[1];
      _palette.colorSelected(color: other.references[1], addToHistory: false);

      changeColorCount(ramp: _palette.colorRamps[0], colorCount: _palette.colorRamps[0].references.length - 1);

      expect(_palette.selectedColor, other.references[1]);
      await settle();
    });
  });

  group("the ramp limits", ()
  {
    _test("stop adding ramps", (final DrawingLayerState layer) async
    {
      _palette.colorRamps = _newRamps(count: KPalConstraints.rampCountMax);
      final HistoryState? before = _history.getCurrentState();

      final (PaletteActionResult, KPalRampData?) result = await _palette.addNewRamp();

      expect(result.$1, PaletteActionResult.rampCountMaxReached);
      expect(result.$2, isNull);
      expect(_palette.colorRamps, hasLength(KPalConstraints.rampCountMax));
      expect(_history.getCurrentState(), same(before));
    });

    _test("stop deleting ramps", (final DrawingLayerState layer) async
    {
      final List<KPalRampData> last = _newRamps(count: KPalConstraints.rampCountMin);
      _palette.colorRamps = last;
      final HistoryState? before = _history.getCurrentState();

      expect(_palette.deleteRamp(ramp: last.first), PaletteActionResult.rampCountMinReached);

      expect(_palette.colorRamps, hasLength(KPalConstraints.rampCountMin));
      expect(_history.getCurrentState(), same(before));
    });
  });

  group("changing the order of the ramps", ()
  {
    _test("moves a ramp up and down", (final DrawingLayerState layer) async
    {
      final List<KPalRampData> ramps = List<KPalRampData>.of(_palette.colorRamps);

      _palette.changeColorOrder(ramp: ramps[0], newPosition: 3);
      expect(_palette.colorRamps.sublist(0, 3), <KPalRampData>[ramps[1], ramps[2], ramps[0]]);
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.kPalOrderChange);

      _palette.changeColorOrder(ramp: ramps[0], newPosition: 0);
      expect(_palette.colorRamps, ramps);
    });

    _test("stays put when dropped where it is, on either side", (final DrawingLayerState layer) async
    {
      final List<KPalRampData> ramps = List<KPalRampData>.of(_palette.colorRamps);

      _palette.changeColorOrder(ramp: ramps[2], newPosition: 2, addToHistoryStack: false);
      _palette.changeColorOrder(ramp: ramps[2], newPosition: 3, addToHistoryStack: false);

      expect(_palette.colorRamps, ramps);
    });

    _test("adds no undo step when dropped where it is", (final DrawingLayerState layer) async
    {
      final HistoryState? before = _history.getCurrentState();

      _palette.changeColorOrder(ramp: _palette.colorRamps[2], newPosition: 2);

      expect(_history.getCurrentState(), same(before));
    });
  });
}
