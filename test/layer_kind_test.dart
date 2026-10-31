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
    test("each read their own value and limits", () async {
      //every preference gets numbers of its own, since many of the defaults are the same
      final Map<String, Object> stored = <String, Object>{};
      void storeInt(final int base, final PreferenceInt value, final PreferenceInt min, final PreferenceInt max)
      {
        stored[min.name] = base;
        stored[value.name] = base + 1;
        stored[max.name] = base + 2;
      }
      void storeDouble(final double base, final PreferenceDouble value, final PreferenceDouble min, final PreferenceDouble max)
      {
        stored[min.name] = base;
        stored[value.name] = base + 1;
        stored[max.name] = base + 2;
      }
      void expectInt(final RangedPref<int> pref, final int base)
      {
        expect(<int>[pref.min, pref.value, pref.max], <int>[base, base + 1, base + 2]);
      }
      void expectDouble(final RangedPref<double> pref, final double base)
      {
        expect(<double>[pref.min, pref.value, pref.max], <double>[base, base + 1, base + 2]);
      }

      storeInt(100, PreferenceInt.HistoryOptions_Steps, PreferenceInt.HistoryOptions_StepsMin, PreferenceInt.HistoryOptions_StepsMax);
      storeInt(200, PreferenceInt.StylusOptions_LongPressDelay, PreferenceInt.StylusOptions_LongPressDelayMin, PreferenceInt.StylusOptions_LongPressDelayMax);
      storeInt(300, PreferenceInt.StylusOptions_PickMaxDuration, PreferenceInt.StylusOptions_PickMaxDurationMin, PreferenceInt.StylusOptions_PickMaxDurationMax);
      storeInt(400, PreferenceInt.TouchOptions_SingleTouchDelay, PreferenceInt.TouchOptions_SingleTouchDelayMin, PreferenceInt.TouchOptions_SingleTouchDelayMax);
      storeDouble(10.0, PreferenceDouble.StylusOptions_LongPressCancelDistance, PreferenceDouble.StylusOptions_LongPressCancelDistanceMin, PreferenceDouble.StylusOptions_LongPressCancelDistanceMax);
      storeDouble(20.0, PreferenceDouble.StylusOptions_ZoomStepDistance, PreferenceDouble.StylusOptions_ZoomStepDistanceMin, PreferenceDouble.StylusOptions_ZoomStepDistanceMax);
      storeDouble(30.0, PreferenceDouble.StylusOptions_SizeStepDistance, PreferenceDouble.StylusOptions_SizeStepDistanceMin, PreferenceDouble.StylusOptions_SizeStepDistanceMax);
      storeDouble(40.0, PreferenceDouble.TouchOptions_ZoomStepDistance, PreferenceDouble.TouchOptions_ZoomStepDistanceMin, PreferenceDouble.TouchOptions_ZoomStepDistanceMax);
      SharedPreferences.setMockInitialValues(stored);

      final PreferenceManager prefs = PreferenceManager(await SharedPreferences.getInstance());
      expectInt(prefs.behaviorPreferenceContent.undoSteps, 100);
      expectInt(prefs.stylusPreferenceContent.stylusLongPressDelay, 200);
      expectInt(prefs.stylusPreferenceContent.stylusPickMaxDuration, 300);
      expectInt(prefs.touchPreferenceContent.singleTouchDelay, 400);
      expectDouble(prefs.stylusPreferenceContent.stylusLongPressCancelDistance, 10.0);
      expectDouble(prefs.stylusPreferenceContent.stylusZoomStepDistance, 20.0);
      expectDouble(prefs.stylusPreferenceContent.stylusSizeStepDistance, 30.0);
      expectDouble(prefs.touchPreferenceContent.zoomStepDistance, 40.0);
    });
  });
}
