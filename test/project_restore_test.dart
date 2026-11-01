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
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/grid_layer_constraints.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/symmetry_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/project_files.dart';
import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 8, y: 6);
final CoordinateSetI _dot = CoordinateSetI(x: 5, y: 2);

Future<LoadFileSet> _savedAndLoaded({final String path = "folder/saved.kpix"}) async
{
  final LoadFileSet loaded = await loadProjectBytes(bytes: await projectBytes(), path: path);
  expect(loaded.historyState, isNotNull, reason: "setup: ${loaded.status}");
  return loaded;
}

void _expectFreshHistory()
{
  final HistoryManager history = GetIt.I.get<HistoryManager>();
  expect(history.hasUndo.value, isFalse);
  expect(history.hasRedo.value, isFalse);
  expect(history.getCurrentIdentifier(), HistoryStateTypeIdentifier.initial);
  expect(history.isAtSavedState, isTrue);
}

void main()
{
  group("restoreFromFile", ()
  {
    testWidgets("brings back the canvas, palette, frames and layers", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final PaletteState palette = GetIt.I.get<PaletteState>();
        final Timeline timeline = GetIt.I.get<DocumentState>().timeline;
        final List<KPalRampData> ramps = <KPalRampData>[
          KPalRampData(uuid: "first", settings: KPalRampSettings()..colorCount = 5..baseHue = 40),
          KPalRampData(uuid: "second", settings: KPalRampSettings()..colorCount = 7..baseHue = 200),
        ];
        palette.colorRamps = ramps;
        palette.selectedColor = ramps[1].references[3];
        await paintPixels(projectSession: projectSession, pixels: <CoordinateSetI, ColorReference>{_dot: ramps[1].references[2]});
        final ShadingLayerState shading = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.shading, select: true).$2! as ShadingLayerState;
        final GridLayerState grid = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.grid, select: true).$2! as GridLayerState;
        grid.intervalXNotifier.value = 5;
        grid.gridTypeNotifier.value = GridType.diagonal;
        await settle();
        expect(shading.visibilityState.value, LayerVisibilityState.visible, reason: "setup");
        expect(timeline.addNewFrameRight(), LayerActionResult.success);
        await settle();
        final LoadFileSet loaded = await _savedAndLoaded();

        projectSession.init(dimensions: CoordinateSetI(x: 3, y: 3));
        await settle();
        expect(timeline.frames.value.length, 1, reason: "setup: the session moved on to another project");

        final ProjectLoadResult result = await projectSession.restoreFromFile(loadFileSet: loaded);
        await settle();

        expect(result.restore, HistoryRestoreResult.success);
        expect(GetIt.I.get<CanvasState>().canvasSize, _canvasSize);
        expect(palette.colorRamps.map((final KPalRampData ramp) => ramp.settings.baseHue), <int>[40, 200]);
        expect(palette.colorRamps.map((final KPalRampData ramp) => ramp.settings.colorCount), <int>[5, 7]);
        //a file does not store the selected color, it starts at the first one
        expect(palette.selectedColor, palette.colorRamps[0].references[0]);
        expect(timeline.frames.value.length, 2);

        final LayerCollection firstFrame = timeline.frames.value.first.layerList;
        expect(firstFrame.getAllLayers().map((final LayerState layer) => layer.kind), <LayerKind>[LayerKind.grid, LayerKind.shading, LayerKind.drawing]);
        final GridLayerState restoredGrid = firstFrame.getLayer(index: 0) as GridLayerState;
        expect(restoredGrid.intervalX, 5);
        expect(restoredGrid.gridType, GridType.diagonal);
        final ColorReference? restored = (firstFrame.getLayer(index: 2) as DrawingLayerState).getDataEntry(coord: _dot);
        expect(restored, isNotNull);
        expect(restored!.ramp, palette.colorRamps[1]);
        expect(restored.colorIndex, 2);
      },);
    });

    testWidgets("names the project after the file and starts a clean history", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final LoadFileSet loaded = await _savedAndLoaded(path: "folder/my drawing.$fileExtensionKpix");
        GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerOrderChange);
        expect(GetIt.I.get<HistoryManager>().hasUndo.value, isTrue, reason: "setup");

        await projectSession.restoreFromFile(loadFileSet: loaded);

        expect(projectSession.projectName.value, "my drawing");
        expect(projectSession.hasChanges.value, isFalse);
        expect(projectSession.hasProject, isTrue);
        _expectFreshHistory();
      },);
    });

    testWidgets("keeps unsaved work marked as changed when asked to", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final LoadFileSet loaded = await _savedAndLoaded();

        await projectSession.restoreFromFile(loadFileSet: loaded, setHasChanges: true);

        expect(projectSession.hasChanges.value, isTrue);
        _expectFreshHistory();
      },);
    });

    testWidgets("does not name the project after the recovery file", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        projectSession.projectName.value = "previous";
        final LoadFileSet loaded = await _savedAndLoaded(path: "recover/$recoverFileName.$fileExtensionKpix");

        await projectSession.restoreFromFile(loadFileSet: loaded, setHasChanges: true);

        expect(projectSession.projectName.value, isNull);
      },);
    });

    testWidgets("drops the clipboard of the previous palette and resets symmetry", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final LoadFileSet loaded = await _savedAndLoaded();
        final SelectionState selectionState = GetIt.I.get<DocumentState>().selectionState;
        final SymmetryState symmetry = GetIt.I.get<SymmetryState>();
        await paintPixels(projectSession: projectSession, pixels: <CoordinateSetI, ColorReference>{_dot: GetIt.I.get<PaletteState>().colorRamps.first.references.first});
        selectionState.newSelectionFromShape(start: CoordinateSetI(x: 0, y: 0), end: CoordinateSetI(x: 7, y: 5), selectShape: SelectShape.rectangle);
        expect(selectionState.copy(), SelectionActionResult.success, reason: "setup");
        expect(selectionState.hasClipboard, isTrue, reason: "setup");
        symmetry.horizontalActivated.value = true;
        symmetry.horizontalValue.value = 1.0;

        await projectSession.restoreFromFile(loadFileSet: loaded);

        expect(selectionState.hasClipboard, isFalse);
        expect(symmetry.horizontalActivated.value, isFalse);
        expect(symmetry.horizontalValue.value, _canvasSize.x / 2.0);
      },);
    });

    testWidgets("hands back what the file reader had to report", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final LoadFileSet loaded = await _savedAndLoaded();

        final ProjectLoadResult result = await projectSession.restoreFromFile(loadFileSet: LoadFileSet(status: "worked around something", historyState: loaded.historyState, path: loaded.path));

        expect(result.restore, HistoryRestoreResult.success);
        expect(result.status, "worked around something");
      },);
    });

    for (final (String condition, bool withState, bool withPath) broken in <(String, bool, bool)>[
      ("no state", false, true),
      ("no path", true, false),
      ("neither", false, false),
    ])
    {
      testWidgets("leaves the session alone when the file gave ${broken.$1}", (final WidgetTester tester) async
      {
        await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
        {
          final LoadFileSet loaded = await _savedAndLoaded();
          await paintPixels(projectSession: projectSession, pixels: <CoordinateSetI, ColorReference>{_dot: GetIt.I.get<PaletteState>().colorRamps.first.references.first});
          projectSession.projectName.value = "current";
          GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerOrderChange);

          final ProjectLoadResult result = await projectSession.restoreFromFile(
            loadFileSet: LoadFileSet(status: "broken", historyState: broken.$2 ? loaded.historyState : null, path: broken.$3 ? loaded.path : null),
          );

          expect(result.restore, isNull);
          expect(result.status, "broken");
          expect(projectSession.projectName.value, "current");
          expect(projectSession.hasChanges.value, isTrue);
          expect(GetIt.I.get<HistoryManager>().hasUndo.value, isTrue);
          expect(layerAt(projectSession: projectSession, index: 0).getDataEntry(coord: _dot), isNotNull);
        },);
      });
    }
  });

  group("importFile", ()
  {
    /// What importing an image hands over, in a palette the session does not use yet.
    ImportResult importResult({required final bool withReference})
    {
      final List<KPalRampData> ramps = <KPalRampData>[KPalRampData(uuid: "imported", settings: KPalRampSettings()..colorCount = 4)];
      return ImportResult(
        result: ImageImportResult.success,
        data: ImportDataSet(
          drawingLayer: DrawingLayerState(size: CoordinateSetI(x: 10, y: 9), ramps: ramps, content: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{_dot: ramps[0].references[1]})),
          referenceLayer: withReference ? GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.reference, addToHistoryStack: false).$2! as ReferenceLayerState : null,
          rampDataList: ramps,
          canvasSize: CoordinateSetI(x: 10, y: 9),
        ),
      );
    }

    testWidgets("replaces the project with a single frame of the imported layer", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final Timeline timeline = GetIt.I.get<DocumentState>().timeline;
        expect(timeline.addNewFrameRight(), LayerActionResult.success, reason: "setup");
        projectSession.projectName.value = "previous";
        GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerOrderChange);
        final ImportResult import = importResult(withReference: false);

        projectSession.importFile(importResult: import);
        await settle();

        expect(GetIt.I.get<CanvasState>().canvasSize, CoordinateSetI(x: 10, y: 9));
        expect(GetIt.I.get<PaletteState>().colorRamps, import.data!.rampDataList);
        expect(GetIt.I.get<PaletteState>().selectedColor, import.data!.rampDataList[0].references[0]);
        expect(timeline.frames.value.length, 1);
        expect(timeline.selectedFrame!.fps.value, GetIt.I.get<PreferenceManager>().frameConstraints.defaultFps);
        final LayerCollection layers = timeline.selectedFrame!.layerList;
        expect(layers.getAllLayers(), <LayerState>[import.data!.drawingLayer]);
        expect((layers.getLayer(index: 0) as DrawingLayerState).getDataEntry(coord: _dot)!.colorIndex, 1);
        expect(projectSession.projectName.value, isNull);
        expect(projectSession.hasChanges.value, isFalse);
        expect(GetIt.I.get<HistoryManager>().hasUndo.value, isFalse);
        expect(GetIt.I.get<HistoryManager>().getCurrentIdentifier(), HistoryStateTypeIdentifier.initial);
      },);
    });

    testWidgets("puts the reference layer below the imported one", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final ImportResult import = importResult(withReference: true);

        projectSession.importFile(importResult: import);
        await settle();

        expect(GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.getAllLayers(), <LayerState>[import.data!.drawingLayer, import.data!.referenceLayer!]);
      },);
    });

    testWidgets("drops the clipboard of the previous palette", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final SelectionState selectionState = GetIt.I.get<DocumentState>().selectionState;
        await paintPixels(projectSession: projectSession, pixels: <CoordinateSetI, ColorReference>{_dot: GetIt.I.get<PaletteState>().colorRamps.first.references.first});
        selectionState.newSelectionFromShape(start: CoordinateSetI(x: 0, y: 0), end: CoordinateSetI(x: 7, y: 5), selectShape: SelectShape.rectangle);
        expect(selectionState.copy(), SelectionActionResult.success, reason: "setup");

        projectSession.importFile(importResult: importResult(withReference: false));
        await settle();

        expect(selectionState.hasClipboard, isFalse);
      },);
    });

    testWidgets("leaves the session alone when the conversion failed", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        projectSession.projectName.value = "current";
        final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);

        projectSession.importFile(importResult: ImportResult(result: ImageImportResult.conversionFailed));

        expect(projectSession.projectName.value, "current");
        expect(GetIt.I.get<CanvasState>().canvasSize, _canvasSize);
        expect(layerAt(projectSession: projectSession, index: 0), layer);
      },);
    });
  });
}
