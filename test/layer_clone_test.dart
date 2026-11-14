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

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/reference_image_manager.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/models/constraints/grid_layer_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:material_ui/material_ui.dart';

import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 8, y: 8);

LayerCollection _layers() => GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList;

Future<void> _undo() async
{
  await GetIt.I.get<HistoryController>().undoPressed()!.restore;
  await settle();
}

GridLayerState _grid()
{
  final GridLayerState grid = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.grid, select: true).$2! as GridLayerState;
  grid.opacityNotifier.value = 33;
  grid.brightnessNotifier.value = 44;
  grid.gridTypeNotifier.value = GridType.isometric;
  grid.intervalXNotifier.value = 5;
  grid.intervalYNotifier.value = 7;
  grid.horizonPositionNotifier.value = 0.25;
  grid.vanishingPoint1Notifier.value = 0.2;
  grid.vanishingPoint2Notifier.value = 0.6;
  grid.vanishingPoint3Notifier.value = 0.8;
  return grid;
}

void _expectGridSettings({required final GridLayerState grid})
{
  expect(grid.opacity, 33);
  expect(grid.brightness, 44);
  expect(grid.gridType, GridType.isometric);
  expect(grid.intervalX, 5);
  expect(grid.intervalY, 7);
  expect(grid.horizonPosition, 0.25);
  expect(grid.vanishingPoint1, 0.2);
  expect(grid.vanishingPoint2, 0.6);
  expect(grid.vanishingPoint3, 0.8);
}

ReferenceLayerState _reference({required final ReferenceImage? image})
{
  final ReferenceLayerState reference = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.reference, select: true).$2! as ReferenceLayerState;
  reference.imageNotifier.value = image;
  reference.opacityNotifier.value = 33;
  reference.aspectRatioNotifier.value = 1.5;
  reference.zoomNotifier.value = 700;
  reference.offsetXNotifier.value = 3.0;
  reference.offsetYNotifier.value = -4.0;
  reference.brightnessNotifier.value = 0.25;
  reference.contrastNotifier.value = 1.25;
  reference.saturationNotifier.value = 0.75;
  reference.warmthNotifier.value = -0.5;
  return reference;
}

void _expectReferenceSettings({required final ReferenceLayerState reference})
{
  expect(reference.opacity, 33);
  expect(reference.aspectRatioNotifier.value, 1.5);
  expect(reference.zoomNotifier.value, 700);
  expect(reference.offsetX, 3.0);
  expect(reference.offsetY, -4.0);
  expect(reference.brightnessNotifier.value, 0.25);
  expect(reference.contrastNotifier.value, 1.25);
  expect(reference.saturationNotifier.value, 0.75);
  expect(reference.warmthNotifier.value, -0.5);
}

Future<ui.Image> _picture() async
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 4, 4), Paint()..color = const Color(0xFFCC3333));
  return recorder.endRecording().toImage(4, 4);
}

void main()
{
  group("grid layer", ()
  {
    testWidgets("a copy has every setting and does not follow the original", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final GridLayerState grid = _grid();

        final GridLayerState copy = grid.copy();
        addTearDown(copy.dispose);

        _expectGridSettings(grid: copy);
        grid.intervalXNotifier.value = 9;
        expect(copy.intervalX, 5);
      },);
    });

    testWidgets("duplicating adds an equal layer above the original and is a history step", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final GridLayerState grid = _grid();
        final int position = _layers().getLayerPosition(state: grid)!;

        final (LayerActionResult result, LayerState? duplicate) = GetIt.I.get<LayerManager>().layerDuplicateSelected(duplicateLayer: grid);

        expect(result, LayerActionResult.success);
        expect(duplicate, isA<GridLayerState>());
        expect(duplicate, isNot(same(grid)));
        _expectGridSettings(grid: duplicate! as GridLayerState);
        expect(_layers().getLayerPosition(state: duplicate), position);
        expect(_layers().getLayerPosition(state: grid), position + 1);
        expect(GetIt.I.get<HistoryManager>().getCurrentIdentifier(), HistoryStateTypeIdentifier.layerDuplicate);
      },);
    });

    testWidgets("undoing its deletion brings back every setting", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final GridLayerState grid = _grid();
        grid.visibilityState.value = LayerVisibilityState.hidden;
        GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerSettingsChange, originLayer: grid);
        final int position = _layers().getLayerPosition(state: grid)!;
        expect(GetIt.I.get<LayerManager>().layerDeletedSelected(deleteLayer: grid), LayerActionResult.success);
        await settle();
        expect(_layers().length, 1, reason: "setup: only the drawing layer is left");

        await _undo();

        expect(_layers().length, 2);
        final GridLayerState restored = _layers().getLayer(index: position) as GridLayerState;
        expect(restored, isNot(same(grid)));
        _expectGridSettings(grid: restored);
        expect(restored.visibilityState.value, LayerVisibilityState.hidden);
      },);
    });
  });

  group("reference layer", ()
  {
    testWidgets("a copy has every setting and the image, and does not follow the original", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final ui.Image picture = await _picture();
        final ReferenceImage image = ReferenceImage(path: "folder/picture.png", image: picture);
        final ReferenceLayerState reference = _reference(image: image);

        final ReferenceLayerState copy = reference.copy();

        _expectReferenceSettings(reference: copy);
        expect(copy.image, image);
        reference.offsetXNotifier.value = 9.0;
        expect(copy.offsetX, 3.0);
      },);
    });

    testWidgets("a copy without an image stays without one", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final ReferenceLayerState copy = _reference(image: null).copy();

        expect(copy.image, isNull);
        expect(copy.thumbnail.value, isNull);
      },);
    });

    testWidgets("duplicating adds an equal layer above the original", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final ReferenceLayerState reference = _reference(image: null);
        final int position = _layers().getLayerPosition(state: reference)!;

        final (LayerActionResult result, LayerState? duplicate) = GetIt.I.get<LayerManager>().layerDuplicateSelected(duplicateLayer: reference);

        expect(result, LayerActionResult.success);
        expect(duplicate, isA<ReferenceLayerState>());
        expect(duplicate, isNot(same(reference)));
        _expectReferenceSettings(reference: duplicate! as ReferenceLayerState);
        expect(_layers().getLayerPosition(state: duplicate), position);
      },);
    });

    testWidgets("undoing its deletion brings back every setting", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final ReferenceLayerState reference = _reference(image: null);
        GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerSettingsChange, originLayer: reference);
        final int position = _layers().getLayerPosition(state: reference)!;
        expect(GetIt.I.get<LayerManager>().layerDeletedSelected(deleteLayer: reference), LayerActionResult.success);
        await settle();

        await _undo();

        final ReferenceLayerState restored = _layers().getLayer(index: position) as ReferenceLayerState;
        expect(restored, isNot(same(reference)));
        _expectReferenceSettings(reference: restored);
      },);
    });
  });
}
