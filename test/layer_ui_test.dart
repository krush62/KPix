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

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_settings.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/widgets/controls/kpix_color_picker_widget.dart';
import 'package:kpix/widgets/controls/kpix_direction_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/layer_settings/drawing_layer_settings_widget.dart';
import 'package:kpix/widgets/layer_settings/shading_layer_settings_widget.dart';
import 'package:kpix/widgets/main/layer_widget.dart';
import 'package:kpix/widgets/main/right_bar_widget.dart';
import 'package:kpix/widgets/timeline/timeline_drag_target_widget.dart';
import 'package:kpix/widgets/timeline/timeline_widget.dart';

import 'support/widget_harness.dart';

Timeline get _timeline => GetIt.I.get<DocumentState>().timeline;
LayerCollection get _layers => _timeline.selectedFrame!.layerList;
LayerManager get _manager => GetIt.I.get<LayerManager>();
HistoryManager get _history => GetIt.I.get<HistoryManager>();
HotkeyManager get _hotkeys => GetIt.I.get<HotkeyManager>();

Widget _rightBar() => const Center(child: SizedBox(width: 340, height: 800, child: RightBarWidget()));

Future<void> _tapTooltipStarting(final WidgetTester tester, final String start) async
{
  await tester.tap(findTooltipStarting(start).first);
  await settleUi(tester);
}

/// Opens the actions of the layer row of [layer].
Future<void> _openActions(final WidgetTester tester, final LayerState layer) async
{
  final Finder row = find.byWidgetPredicate((final Widget w) => w is LayerWidget && w.layerState == layer);
  await tester.tap(find.descendant(of: row, matching: find.byIcon(TablerIcons.menu_2)).first);
  await settleUi(tester);
}

void main()
{
  group("the layer list", ()
  {
    projectWidgetTest("shows a row for every layer and follows along", _rightBar, (final WidgetTester tester) async
    {
      expect(find.byType(LayerWidget), findsOneWidget);

      _manager.addNewLayer(layerType: LayerKind.drawing, addToHistoryStack: false);
      await tester.pump();
      await tester.pump();

      expect(find.byType(LayerWidget), findsNWidgets(2));
    });

    for (final (String Function(), Type) entry in <(String Function(), Type)>[
      (() => testL10n.addNewDrawingLayer, DrawingLayerState),
      (() => testL10n.addNewShadingLayer, ShadingLayerState),
      (() => testL10n.addNewDitherLayer, DitherLayerState),
      (() => testL10n.addNewReferenceLayer, ReferenceLayerState),
      (() => testL10n.addNewGridLayer, GridLayerState),
    ])
    {
      projectWidgetTest("adds a layer from its menu: ${entry.$2}", _rightBar, (final WidgetTester tester) async
      {
        await _tapTooltipStarting(tester, testL10n.addNewLayerDot);

        await _tapTooltipStarting(tester, entry.$1());

        expect(_layers.length, 2);
        expect(_timeline.selectedFrame!.layerList.getLayer(index: 0).runtimeType, entry.$2);
        expect(findTooltipStarting(entry.$1()), findsNothing, reason: "the menu closed");
      });
    }

    for (final (HotkeyAction, Type) entry in <(HotkeyAction, Type)>[
      (HotkeyAction.layersNewDrawing, DrawingLayerState),
      (HotkeyAction.layersNewReference, ReferenceLayerState),
      (HotkeyAction.layersNewShading, ShadingLayerState),
      (HotkeyAction.layersNewGrid, GridLayerState),
    ])
    {
      projectWidgetTest("adds a layer with a hotkey: ${entry.$1.name}", _rightBar, (final WidgetTester tester) async
      {
        _hotkeys.triggerShortcut(action: entry.$1);
        await settleUi(tester);

        expect(_layers.length, 2);
        expect(_layers.getLayer(index: 0).runtimeType, entry.$2);
      });
    }

    projectWidgetTest("duplicates, merges and deletes the selected layer with hotkeys", _rightBar, (final WidgetTester tester) async
    {
      _hotkeys.triggerShortcut(action: HotkeyAction.layersDuplicate);
      await settleUi(tester);
      expect(_layers.length, 2);

      _hotkeys.triggerShortcut(action: HotkeyAction.layersMerge);
      await settleUi(tester);
      expect(_layers.length, 1);

      _hotkeys.triggerShortcut(action: HotkeyAction.layersDuplicate);
      await settleUi(tester);
      _hotkeys.triggerShortcut(action: HotkeyAction.layersDelete);
      await settleUi(tester);
      expect(_layers.length, 1);
    });

    projectWidgetTest("says why when a hotkey cannot do its job", _rightBar, (final WidgetTester tester) async
    {
      _hotkeys.triggerShortcut(action: HotkeyAction.layersDelete);
      await settleUi(tester);
      expect(find.text(testL10n.cannotDeleteLastLayer), findsOneWidget);

      _hotkeys.triggerShortcut(action: HotkeyAction.layersMerge);
      await settleUi(tester);
      expect(find.text(testL10n.noLayerBelow), findsOneWidget);
    });

    projectWidgetTest("says so when a frame is full", _rightBar, (final WidgetTester tester) async
    {
      while (_layers.length < LayerCollection.maxLayers)
      {
        _layers.addNewReferenceLayer();
      }
      await tester.pump();

      _hotkeys.triggerShortcut(action: HotkeyAction.layersNewDrawing);
      await settleUi(tester);

      expect(find.text(testL10n.couldNotAddMoreLayers), findsOneWidget);
    });

    projectWidgetTest("takes a layer dropped between the others", _rightBar, (final WidgetTester tester) async
    {
      final LayerState lower = _timeline.getCurrentLayer()!;
      final LayerState upper = _manager.addNewLayer(layerType: LayerKind.reference, addToHistoryStack: false).$2!;
      await tester.pump();
      await tester.pump();

      final List<DragTarget<LayerState>> targets = tester.widgetList<DragTarget<LayerState>>(find.byType(DragTarget<LayerState>)).toList();
      targets.last.onAcceptWithDetails!(DragTargetDetails<LayerState>(data: upper, offset: Offset.zero));
      await tester.pump();

      expect(_layers.getLayer(index: 0), same(lower));
      expect(_layers.getLayer(index: 1), same(upper));
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerOrderChange);

      targets.first.onAcceptWithDetails!(DragTargetDetails<LayerState>(data: upper, offset: Offset.zero));
      await tester.pump();

      expect(_layers.getLayer(index: 0), same(upper));
    });
  });

  group("a layer row", ()
  {
    projectWidgetTest("selects its layer when tapped", _rightBar, (final WidgetTester tester) async
    {
      final LayerState lower = _timeline.getCurrentLayer()!;
      _manager.addNewLayer(layerType: LayerKind.drawing, select: true, addToHistoryStack: false);
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byWidgetPredicate((final Widget w) => w is LayerWidget && w.layerState == lower));
      await tester.pump();

      expect(_timeline.getCurrentLayer(), same(lower));
    });

    projectWidgetTest("hides and locks its layer with its buttons", _rightBar, (final WidgetTester tester) async
    {
      final DrawingLayerState layer = _timeline.getCurrentLayer()! as DrawingLayerState;

      await _tapTooltipStarting(tester, layer.visibilityState.value.label(testL10n));
      expect(layer.visibilityState.value, LayerVisibilityState.hidden);

      await _tapTooltipStarting(tester, layer.lockState.value.label(testL10n));
      expect(layer.lockState.value, LayerLockState.transparency);
    });

    projectWidgetTest("opens the settings of its layer", _rightBar, (final WidgetTester tester) async
    {
      final ViewState view = GetIt.I.get<ViewState>();
      expect(view.layerSettingsVisible, isFalse);

      await tester.tap(find.descendant(of: find.byType(LayerWidget), matching: find.byIcon(TablerIcons.settings)));
      await settleUi(tester);

      expect(view.layerSettingsVisible, isTrue);
      expect(find.byType(DrawingLayerSettingsWidget), findsOneWidget);
    });

    group("offers", ()
    {
      projectWidgetTest("delete on a drawing layer", _rightBar, (final WidgetTester tester) async
      {
        final LayerState layer = _timeline.getCurrentLayer()!;
        _manager.addNewLayer(layerType: LayerKind.drawing, addToHistoryStack: false);
        await tester.pump();
        await tester.pump();
        await _openActions(tester, layer);

        await _tapTooltipStarting(tester, testL10n.deleteLayer);

        expect(_layers.length, 1);
        expect(_layers.contains(layer: layer), isFalse);
      });

      projectWidgetTest("duplicate on a drawing layer", _rightBar, (final WidgetTester tester) async
      {
        await _openActions(tester, _timeline.getCurrentLayer()!);

        await _tapTooltipStarting(tester, testL10n.duplicateLayer);

        expect(_layers.length, 2);
      });

      projectWidgetTest("merge on a drawing layer, and why it cannot", _rightBar, (final WidgetTester tester) async
      {
        await _openActions(tester, _timeline.getCurrentLayer()!);
        await _tapTooltipStarting(tester, testL10n.mergeDownLayer);
        expect(find.text(testL10n.noLayerBelow), findsOneWidget);

        final LayerState upper = _manager.addNewLayer(layerType: LayerKind.drawing, addToHistoryStack: false).$2!;
        await tester.pump();
        await tester.pump();
        await _openActions(tester, upper);
        await _tapTooltipStarting(tester, testL10n.mergeDownLayer);
        expect(_layers.length, 1);
      });

      projectWidgetTest("raster on a grid layer", _rightBar, (final WidgetTester tester) async
      {
        final LayerState grid = _manager.addNewLayer(layerType: LayerKind.grid, addToHistoryStack: false).$2!;
        await tester.pump();
        await tester.pump();
        await _openActions(tester, grid);

        await _tapTooltipStarting(tester, testL10n.rasterLayer);
        await settleUi(tester);

        expect(_layers.getLayer(index: 0), isA<DrawingLayerState>());
      });

      projectWidgetTest("raster on a shading layer", _rightBar, (final WidgetTester tester) async
      {
        final LayerState shading = _manager.addNewLayer(layerType: LayerKind.shading, addToHistoryStack: false).$2!;
        await tester.pump();
        await tester.pump();
        await _openActions(tester, shading);

        await _tapTooltipStarting(tester, testL10n.rasterLayer);
        await settleUi(tester);

        expect(_layers.length, 1);
        expect(_layers.getLayer(index: 0), isA<DrawingLayerState>());
      });

      projectWidgetTest("no raster and no merge on a reference layer", _rightBar, (final WidgetTester tester) async
      {
        final LayerState reference = _manager.addNewLayer(layerType: LayerKind.reference, addToHistoryStack: false).$2!;
        await tester.pump();
        await tester.pump();
        await _openActions(tester, reference);

        expect(findTooltipStarting(testL10n.rasterLayer), findsNothing);
        expect(findTooltipStarting(testL10n.mergeDownLayer), findsNothing);
        await _tapTooltipStarting(tester, testL10n.duplicateLayer);
        expect(_layers.length, 3);
      });

      projectWidgetTest("unlink on a linked layer, which gets a copy of its own", _rightBar, (final WidgetTester tester) async
      {
        final LayerState layer = _timeline.getCurrentLayer()!;
        _timeline.linkFrameRight();
        await settleUi(tester);
        expect(_timeline.isLayerLinked(layer: layer), isTrue, reason: "setup");
        await _openActions(tester, layer);

        await _tapTooltipStarting(tester, testL10n.unlinkLayer);

        expect(_timeline.isLayerLinked(layer: layer), isFalse);
        expect(_layers.length, 1);
        expect(_timeline.getCurrentLayer(), isNot(same(layer)));
        expect(_timeline.frames.value[0].layerList.getLayer(index: 0), same(layer), reason: "the other frame keeps it");
      });
    });
  });

  group("the layer settings panel", ()
  {
    projectWidgetTest("closes without an undo step when nothing changed", _rightBar, (final WidgetTester tester) async
    {
      GetIt.I.get<ViewState>().layerSettingsVisible = true;
      await settleUi(tester);
      final HistoryState? before = _history.getCurrentState();

      await tapTooltip(tester, testL10n.close);

      expect(GetIt.I.get<ViewState>().layerSettingsVisible, isFalse);
      expect(_history.getCurrentState(), same(before));
    });

    projectWidgetTest("closes with an undo step when something changed", _rightBar, (final WidgetTester tester) async
    {
      final DrawingLayerState layer = _timeline.getCurrentLayer()! as DrawingLayerState;
      GetIt.I.get<ViewState>().layerSettingsVisible = true;
      await settleUi(tester);
      layer.settings.outerStrokeStyle.value = OuterStrokeStyle.solid;
      await settleUi(tester);
      expect(layer.settings.hasChanges, isTrue, reason: "setup");

      await tapTooltip(tester, testL10n.close);

      expect(layer.settings.hasChanges, isFalse);
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerSettingsChange);
      layer.settings.outerStrokeStyle.value = OuterStrokeStyle.off;
      await settleUi(tester);
    });

    projectWidgetTest("shows the sliders of a shading layer", _rightBar, (final WidgetTester tester) async
    {
      _manager.addNewLayer(layerType: LayerKind.shading, select: true, addToHistoryStack: false);
      GetIt.I.get<ViewState>().layerSettingsVisible = true;
      await settleUi(tester);

      expect(find.byType(ShadingLayerSettingsWidget), findsOneWidget);
    });
  });

  group("the settings of a drawing layer", ()
  {
    DrawingLayerState layer() => _timeline.getCurrentLayer()! as DrawingLayerState;
    Widget settingsAt({required final double width}) => Center(child: SizedBox(width: width, height: 850, child: SingleChildScrollView(child: DrawingLayerSettingsWidget(layer: _timeline.getCurrentLayer()! as DrawingLayerState))));
    Widget settings() => settingsAt(width: 340);
    void settingsTest(final String description, final Future<void> Function(WidgetTester tester) body) => projectWidgetTest(description, settings, body, textScale: 0.5);

    SegmentedButton<T> styleButton<T>(final WidgetTester tester) => tester.widget<SegmentedButton<T>>(find.byType(SegmentedButton<T>));

    projectWidgetTest("fits its direction buttons into the widest panel of a 2560 wide window", () => settingsAt(width: 512), (final WidgetTester tester) async
    {
      layer().settings.outerStrokeStyle.value = OuterStrokeStyle.solid;
      await tester.pump();

      expect(tester.takeException(), isNull);
      layer().settings.outerStrokeStyle.value = OuterStrokeStyle.off;
      await settleUi(tester);
    });

    settingsTest("offers every outer stroke style", (final WidgetTester tester) async
    {
      for (final OuterStrokeStyle style in OuterStrokeStyle.values)
      {
        styleButton<OuterStrokeStyle>(tester).onSelectionChanged!(<OuterStrokeStyle>{style});
        await tester.pump();
        expect(layer().settings.outerStrokeStyle.value, style);
        expect(tester.takeException(), isNull, reason: style.name);
      }
      layer().settings.outerStrokeStyle.value = OuterStrokeStyle.off;
      await settleUi(tester);
    });

    settingsTest("offers every inner stroke style", (final WidgetTester tester) async
    {
      for (final InnerStrokeStyle style in InnerStrokeStyle.values)
      {
        styleButton<InnerStrokeStyle>(tester).onSelectionChanged!(<InnerStrokeStyle>{style});
        await tester.pump();
        expect(layer().settings.innerStrokeStyle.value, style);
        expect(tester.takeException(), isNull, reason: style.name);
      }
      layer().settings.innerStrokeStyle.value = InnerStrokeStyle.off;
      await settleUi(tester);
    });

    projectWidgetTest("fits the glow controls into their row", settings, (final WidgetTester tester) async
    {
      layer().settings.outerStrokeStyle.value = OuterStrokeStyle.glow;
      await tester.pump();

      expect(tester.takeException(), isNull);
      layer().settings.outerStrokeStyle.value = OuterStrokeStyle.off;
      await settleUi(tester);
    }, textScale: 0.5,);

    settingsTest("offers every drop shadow style", (final WidgetTester tester) async
    {
      for (final DropShadowStyle style in DropShadowStyle.values)
      {
        styleButton<DropShadowStyle>(tester).onSelectionChanged!(<DropShadowStyle>{style});
        await tester.pump();
        expect(layer().settings.dropShadowStyle.value, style);
        expect(tester.takeException(), isNull, reason: style.name);
      }
      layer().settings.dropShadowStyle.value = DropShadowStyle.off;
      await settleUi(tester);
    });

    projectWidgetTest("hands the direction of a stroke on", settings, (final WidgetTester tester) async
    {
      layer().settings.outerStrokeStyle.value = OuterStrokeStyle.solid;
      await tester.pump();
      final KPixDirectionWidget direction = tester.widget<KPixDirectionWidget>(find.byType(KPixDirectionWidget).first);

      direction.onChange(HashMap<Alignment, bool>.of(<Alignment, bool>{for (final Alignment a in layer().settings.outerSelectionMap.value.keys) a: a == Alignment.topLeft}));
      await tester.pump();

      expect(layer().settings.outerSelectionMap.value[Alignment.topLeft], isTrue);
      layer().settings.outerStrokeStyle.value = OuterStrokeStyle.off;
      await settleUi(tester);
    });

    projectWidgetTest("lets a color be chosen for a stroke", settings, (final WidgetTester tester) async
    {
      layer().settings.outerStrokeStyle.value = OuterStrokeStyle.solid;
      await tester.pump();
      final List<KPalRampData> ramps = GetIt.I.get<PaletteState>().colorRamps;

      await tester.tap(find.byTooltip(testL10n.chooseColor).first);
      await settleUi(tester);
      final Finder picker = find.byType(KPixColorPickerWidget);
      expect(picker, findsOneWidget);
      await tester.tap(find.descendant(of: picker, matching: find.byType(FilledButton)).at(ramps[0].references.length + 1));
      await settleUi(tester);

      expect(layer().settings.outerColorReference.value, ramps[1].references[1]);
      expect(picker, findsNothing, reason: "the picker closed");
      layer().settings.outerStrokeStyle.value = OuterStrokeStyle.off;
      await settleUi(tester);
    });

    projectWidgetTest("keeps the color when the picker is closed without one", settings, (final WidgetTester tester) async
    {
      layer().settings.outerStrokeStyle.value = OuterStrokeStyle.solid;
      await tester.pump();
      final ColorReference color = layer().settings.outerColorReference.value;

      await tester.tap(find.byTooltip(testL10n.chooseColor).first);
      await settleUi(tester);
      await tester.tap(find.descendant(of: find.byType(KPixColorPickerWidget), matching: find.byType(IconButton)).first);
      await settleUi(tester);

      expect(find.byType(KPixColorPickerWidget), findsNothing);
      expect(layer().settings.outerColorReference.value, color);
      layer().settings.outerStrokeStyle.value = OuterStrokeStyle.off;
      await settleUi(tester);
    });
  });

  group("the settings of a shading layer", ()
  {
    for (final bool dither in <bool>[false, true])
    {
      projectWidgetTest("hand their sliders on, ${dither ? "dithering" : "shading"}", () => Center(child: SizedBox(width: 400, height: 300, child: ShadingLayerSettingsWidget(settings: (_manager.addNewLayer(layerType: dither ? LayerKind.dither : LayerKind.shading, select: true, addToHistoryStack: false).$2! as ShadingLayerState).settings, isForDithering: dither))), (final WidgetTester tester) async
      {
        final ShadingLayerSettings settings = (_timeline.getCurrentLayer()! as ShadingLayerState).settings;
        final List<KPixSlider> sliders = tester.widgetList<KPixSlider>(find.byType(KPixSlider)).toList();
        expect(sliders, hasLength(2));

        sliders[0].onChanged!(2);
        sliders[1].onChanged!(3);
        await tester.pump();

        expect(settings.shadingStepsMinus.value, 2);
        expect(settings.shadingStepsPlus.value, 3);
      });
    }
  });

  group("a drag target of the timeline", ()
  {
    Future<Map<String, int>> pumpTarget({required final WidgetTester tester, required final Frame target, required final int layerIndex, required final LayerFrameDragData data}) async
    {
      final Map<String, int> calls = <String, int>{"move": 0, "copy": 0, "link": 0};
      await tester.pumpWidget(testApp(child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Draggable<LayerFrameDragData>(data: data, feedback: const SizedBox(width: 20, height: 20), child: const SizedBox(key: Key("source"), width: 40, height: 40, child: ColoredBox(color: Colors.red))),
          SizedBox(
            width: 200,
            height: 100,
            child: TimeLineDragTargetWidget(
              cellHeight: 100,
              cellWidth: 200,
              delayMs: 0,
              collapsedHeight: 100,
              frame: target,
              layerIndex: layerIndex,
              changeLayerOrderFn: (final LayerState layer, final int position) {calls["move"] = calls["move"]! + 1;},
              copyLayerToOtherFrameFn: (final Frame frame, final LayerState layer, final int position) {calls["copy"] = calls["copy"]! + 1;},
              linkLayerToOtherFrameFn: (final Frame frame, final LayerState layer, final int position) {calls["link"] = calls["link"]! + 1;},
            ),
          ),
        ],
      ),),);
      await tester.pump();
      return calls;
    }

    Future<void> dropOn({required final WidgetTester tester, required final Offset where}) async
    {
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key("source"))));
      await tester.pump();
      await gesture.moveTo(where);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(1, 0));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await settleUi(tester);
    }

    Offset targetCenter(final WidgetTester tester) => tester.getCenter(find.byType(TimeLineDragTargetWidget));

    projectWidgetTest("moves a layer inside of its own frame", () => const SizedBox.shrink(), (final WidgetTester tester) async
    {
      final Frame frame = _timeline.selectedFrame!;
      final Map<String, int> calls = await pumpTarget(tester: tester, target: frame, layerIndex: 0, data: LayerFrameDragData(layer: _timeline.getCurrentLayer()!, frame: frame));

      await dropOn(tester: tester, where: targetCenter(tester));

      expect(calls, <String, int>{"move": 1, "copy": 0, "link": 0});
    });

    projectWidgetTest("only copies to a frame that has the layer already", () => const SizedBox.shrink(), (final WidgetTester tester) async
    {
      final LayerState layer = _timeline.getCurrentLayer()!;
      final Frame source = _timeline.selectedFrame!;
      _timeline.linkFrameRight();
      await settleUi(tester);
      final Frame target = _timeline.frames.value[1];
      final Map<String, int> calls = await pumpTarget(tester: tester, target: target, layerIndex: 0, data: LayerFrameDragData(layer: layer, frame: source));

      await dropOn(tester: tester, where: targetCenter(tester) + const Offset(40, 0));

      expect(calls, <String, int>{"move": 0, "copy": 1, "link": 0});
    });

    for (final (String, double, String) side in <(String, double, String)>[("left", -40, "copy"), ("right", 40, "link")])
    {
      projectWidgetTest("does a ${side.$3} on its ${side.$1} half for a frame without the layer", () => const SizedBox.shrink(), (final WidgetTester tester) async
      {
        final LayerState layer = _timeline.getCurrentLayer()!;
        final Frame source = _timeline.selectedFrame!;
        _timeline.addNewFrameRight();
        await settleUi(tester);
        final Frame target = _timeline.frames.value[1];
        final Map<String, int> calls = await pumpTarget(tester: tester, target: target, layerIndex: 0, data: LayerFrameDragData(layer: layer, frame: source));

        await dropOn(tester: tester, where: targetCenter(tester) + Offset(side.$2, 0));

        expect(calls, <String, int>{"move": 0, "copy": side.$3 == "copy" ? 1 : 0, "link": side.$3 == "link" ? 1 : 0});
      });
    }

    projectWidgetTest("does nothing when the drag leaves again", () => const SizedBox.shrink(), (final WidgetTester tester) async
    {
      final Frame frame = _timeline.selectedFrame!;
      final Map<String, int> calls = await pumpTarget(tester: tester, target: frame, layerIndex: 0, data: LayerFrameDragData(layer: _timeline.getCurrentLayer()!, frame: frame));
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key("source"))));
      await tester.pump();
      await gesture.moveTo(targetCenter(tester));
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.moveTo(const Offset(5, 5));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await settleUi(tester);

      expect(calls, <String, int>{"move": 0, "copy": 0, "link": 0});
    });
  });
}
