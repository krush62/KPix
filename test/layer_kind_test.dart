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

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/preferences/preference_values.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/selection_harness.dart';

void main()
{
  final Map<LayerKind, ({Type type, HistoryStateTypeIdentifier identifier})> kinds = <LayerKind, ({Type type, HistoryStateTypeIdentifier identifier})>{
    LayerKind.drawing: (type: DrawingLayerState, identifier: HistoryStateTypeIdentifier.layerNewDrawing),
    LayerKind.reference: (type: ReferenceLayerState, identifier: HistoryStateTypeIdentifier.layerNewReference),
    LayerKind.grid: (type: GridLayerState, identifier: HistoryStateTypeIdentifier.layerNewGrid),
    LayerKind.shading: (type: ShadingLayerState, identifier: HistoryStateTypeIdentifier.layerNewShading),
    LayerKind.dither: (type: DitherLayerState, identifier: HistoryStateTypeIdentifier.layerNewDither),
  };

  for (final MapEntry<LayerKind, ({Type type, HistoryStateTypeIdentifier identifier})> kind in kinds.entries)
  {
    testWidgets("adding a ${kind.key.name} layer gives a layer that says so", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async {
        final LayerState layer = GetIt.I.get<LayerManager>().addNewLayer(layerType: kind.key, select: true).$2!;
        await settle();
        expect(layer.runtimeType, kind.value.type);
        expect(layer.kind, kind.key);
        expect(GetIt.I.get<HistoryManager>().getCurrentIdentifier(), kind.value.identifier);
      },);
    });
  }

  testWidgets("a dither layer does not count as a shading layer", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async {
      final LayerState dither = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.dither, select: true).$2!;
      await settle();
      expect(dither, isA<ShadingLayerState>());
      expect(dither.kind, isNot(LayerKind.shading));
    },);
  });

  testWidgets("the first layer of a project is a drawing layer", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async {
      expect(GetIt.I.get<DocumentState>().timeline.getCurrentLayer()!.kind, LayerKind.drawing);
    },);
  });

  group("the ranged preferences of the manager", () {
    test("each read their own value, but take their limits from the defaults", () async {
      //every preference gets a value of its own, since many of the defaults are the same;
      //the stored limits narrow the range around it, like the stale touch zoom max that 8a09051c stored
      final Map<String, Object> stored = <String, Object>{};
      final List<void Function(PreferenceManager prefs)> checks = <void Function(PreferenceManager prefs)>[];
      void rangedInt(final int value, final PreferenceInt pref, final PreferenceInt min, final PreferenceInt max, final RangedPref<int> Function(PreferenceManager prefs) of)
      {
        stored[min.name] = value - 1;
        stored[pref.name] = value;
        stored[max.name] = value + 1;
        checks.add((final PreferenceManager prefs) {
          expect(<int>[of(prefs).min, of(prefs).value, of(prefs).max], <int>[min.defaultValue, value, max.defaultValue]);
          expect(pref.defaultValue, inInclusiveRange(min.defaultValue, max.defaultValue));
        });
      }
      void rangedDouble(final double value, final PreferenceDouble pref, final PreferenceDouble min, final PreferenceDouble max, final RangedPref<double> Function(PreferenceManager prefs) of)
      {
        stored[min.name] = value - 1;
        stored[pref.name] = value;
        stored[max.name] = value + 1;
        checks.add((final PreferenceManager prefs) {
          expect(<double>[of(prefs).min, of(prefs).value, of(prefs).max], <double>[min.defaultValue, value, max.defaultValue]);
          expect(pref.defaultValue, inInclusiveRange(min.defaultValue, max.defaultValue));
        });
      }

      rangedInt(101, PreferenceInt.HistoryOptions_Steps, PreferenceInt.HistoryOptions_StepsMin, PreferenceInt.HistoryOptions_StepsMax, (final PreferenceManager p) => p.behaviorPreferenceContent.undoSteps);
      rangedInt(201, PreferenceInt.StylusOptions_LongPressDelay, PreferenceInt.StylusOptions_LongPressDelayMin, PreferenceInt.StylusOptions_LongPressDelayMax, (final PreferenceManager p) => p.stylusPreferenceContent.stylusLongPressDelay);
      rangedInt(301, PreferenceInt.StylusOptions_PickMaxDuration, PreferenceInt.StylusOptions_PickMaxDurationMin, PreferenceInt.StylusOptions_PickMaxDurationMax, (final PreferenceManager p) => p.stylusPreferenceContent.stylusPickMaxDuration);
      rangedInt(41, PreferenceInt.TouchOptions_SingleTouchDelay, PreferenceInt.TouchOptions_SingleTouchDelayMin, PreferenceInt.TouchOptions_SingleTouchDelayMax, (final PreferenceManager p) => p.touchPreferenceContent.singleTouchDelay);
      rangedDouble(11.0, PreferenceDouble.StylusOptions_LongPressCancelDistance, PreferenceDouble.StylusOptions_LongPressCancelDistanceMin, PreferenceDouble.StylusOptions_LongPressCancelDistanceMax, (final PreferenceManager p) => p.stylusPreferenceContent.stylusLongPressCancelDistance);
      rangedDouble(21.0, PreferenceDouble.StylusOptions_ZoomStepDistance, PreferenceDouble.StylusOptions_ZoomStepDistanceMin, PreferenceDouble.StylusOptions_ZoomStepDistanceMax, (final PreferenceManager p) => p.stylusPreferenceContent.stylusZoomStepDistance);
      rangedDouble(31.0, PreferenceDouble.StylusOptions_SizeStepDistance, PreferenceDouble.StylusOptions_SizeStepDistanceMin, PreferenceDouble.StylusOptions_SizeStepDistanceMax, (final PreferenceManager p) => p.stylusPreferenceContent.stylusSizeStepDistance);
      rangedDouble(41.0, PreferenceDouble.TouchOptions_ZoomStepDistance, PreferenceDouble.TouchOptions_ZoomStepDistanceMin, PreferenceDouble.TouchOptions_ZoomStepDistanceMax, (final PreferenceManager p) => p.touchPreferenceContent.zoomStepDistance);
      SharedPreferences.setMockInitialValues(stored);

      final PreferenceManager prefs = PreferenceManager(await SharedPreferences.getInstance());
      for (final void Function(PreferenceManager prefs) check in checks)
      {
        check(prefs);
      }
    });
  });
}
