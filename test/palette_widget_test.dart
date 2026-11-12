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
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/models/tool_type.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/controls/kpix_range_slider.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/palette/color_entry_widget.dart';
import 'package:kpix/widgets/palette/color_ramp_row_widget.dart';
import 'package:kpix/widgets/palette/palette_adjustment_widget.dart';
import 'package:kpix/widgets/palette/palette_manager_widget.dart';
import 'package:kpix/widgets/palette/palette_widget.dart';
import 'package:material_ui/material_ui.dart';

import 'support/widget_harness.dart';

PaletteState get _palette => GetIt.I.get<PaletteState>();
HistoryManager get _history => GetIt.I.get<HistoryManager>();

Widget _column() => const Center(child: SizedBox(width: 420, height: 800, child: Column(children: <Widget>[PaletteWidget()])));

Future<void> _openEditor(final WidgetTester tester, {final int ramp = 0}) async
{
  await tester.tap(find.byTooltip(testL10n.editColorRamp).at(ramp));
  await settleUi(tester);
  expect(find.byType(KPal), findsOneWidget, reason: "setup");
}

/// The sliders of the ramp editor from top to bottom.
KPixSlider _slider(final WidgetTester tester, final int index) => tester.widget<KPixSlider>(find.descendant(of: find.byType(KPalRamp), matching: find.byType(KPixSlider)).at(index));

void main()
{
  group("the palette", ()
  {
    projectWidgetTest("shows a row with an entry per color for every ramp", _column, (final WidgetTester tester) async
    {
      expect(find.byType(ColorRampRowWidget), findsNWidgets(_palette.colorRamps.length));
      final int colors = _palette.colorRamps.fold(0, (final int sum, final KPalRampData ramp) => sum + ramp.references.length);
      expect(find.byType(ColorEntryWidget), findsNWidgets(colors));
    });

    projectWidgetTest("selects the color that is tapped", _column, (final WidgetTester tester) async
    {
      final ColorReference expected = _palette.colorRamps[1].references[2];
      final int before = _palette.colorRamps[0].references.length + 2;

      await tester.tap(find.byType(ColorEntryWidget).at(before));
      await tester.pump();

      expect(_palette.selectedColor, expected);
    });

    projectWidgetTest("follows changes of the ramps", _column, (final WidgetTester tester) async
    {
      final int count = _palette.colorRamps.length;

      await _palette.addNewRamp(addToHistoryStack: false);
      await tester.pump();

      expect(find.byType(ColorRampRowWidget), findsNWidgets(count + 1));
    });

    projectWidgetTest("adds a ramp with its button and opens it in the editor", _column, (final WidgetTester tester) async
    {
      final int count = _palette.colorRamps.length;

      await tapTooltip(tester, testL10n.addNewColorRamp);

      expect(_palette.colorRamps, hasLength(count + 1));
      expect(find.byType(KPal), findsOneWidget);
    });

    projectWidgetTest("says so when there are too many ramps", _column, (final WidgetTester tester) async
    {
      final List<KPalRampData> ramps = <KPalRampData>[
        for (int i = 0; i < KPalConstraints.rampCountMax; i++) KPalRampData(uuid: "ramp $i", settings: KPalRampSettings()),
      ];
      _palette.colorRamps = ramps;
      await tester.pump();

      await tapTooltip(tester, testL10n.addNewColorRamp);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(KPal), findsNothing);
      expect(find.text(testL10n.notMoreThanColorRampsAllowed(count: KPalConstraints.rampCountMax)), findsOneWidget);
    });

    projectWidgetTest("moves a ramp when it is dragged to another place", _column, (final WidgetTester tester) async
    {
      final List<KPalRampData> ramps = List<KPalRampData>.of(_palette.colorRamps);
      final Finder grip = find.byIcon(TablerIcons.grip_vertical).first;
      final Offset from = tester.getCenter(grip);
      final Offset to = tester.getCenter(find.byType(ColorRampRowWidget).at(2)) + Offset(0, tester.getSize(find.byType(ColorRampRowWidget).at(2)).height / 2 + 2);

      final TestGesture gesture = await tester.startGesture(from);
      await tester.pump();
      await gesture.moveTo(to);
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.up();
      await settleUi(tester);

      expect(_palette.colorRamps[2], same(ramps[0]));
      expect(_palette.colorRamps[0], same(ramps[1]));
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.kPalOrderChange);
    });

    projectWidgetTest("opens the palette manager", _column, (final WidgetTester tester) async
    {
      await tapTooltip(tester, testL10n.paletteManager);

      expect(find.byType(PaletteManagerWidget), findsOneWidget);
    });

    projectWidgetTest("opens the palette adjustments", _column, (final WidgetTester tester) async
    {
      await tapTooltip(tester, testL10n.paletteAdjustments);

      expect(find.byType(PaletteAdjustmentWidget), findsOneWidget);
    });
  });

  group("the ramp editor", ()
  {
    projectWidgetTest("changes the colors of the ramp with its sliders", _column, (final WidgetTester tester) async
    {
      await _openEditor(tester);
      final KPalRampData ramp = _palette.colorRamps[0];
      final KPalRampSettings settings = ramp.settings;

      _slider(tester, 1).onChanged!(200);
      await tester.pump();
      expect(settings.baseHue, 200);

      final Color before = ramp.shiftedColors.first.value.color;
      _slider(tester, 2).onChanged!(KPalConstraints.hueShiftMax.toDouble());
      await tester.pump();
      expect(settings.hueShift, KPalConstraints.hueShiftMax);
      expect(ramp.shiftedColors.first.value.color, isNot(before));

      _slider(tester, 3).onChanged!(KPalConstraints.hueShiftExpMax);
      _slider(tester, 4).onChanged!(50);
      _slider(tester, 5).onChanged!(KPalConstraints.satShiftMax.toDouble());
      _slider(tester, 6).onChanged!(KPalConstraints.satShiftExpMax);
      await tester.pump();

      expect(settings.hueShiftExp, KPalConstraints.hueShiftExpMax);
      expect(settings.baseSat, 50);
      expect(settings.satShift, KPalConstraints.satShiftMax);
      expect(settings.satShiftExp, KPalConstraints.satShiftExpMax);
      await tapTooltip(tester, testL10n.cancel);
    });

    projectWidgetTest("adds cards when the number of colors goes up", _column, (final WidgetTester tester) async
    {
      await _openEditor(tester);
      final KPalRampData ramp = _palette.colorRamps[0];
      expect(find.byType(KPalColorCardWidget), findsNWidgets(ramp.references.length));

      _slider(tester, 0).onChanged!(KPalConstraints.colorCountMax.toDouble());
      await tester.pump();
      await tester.pump();

      expect(ramp.settings.colorCount, KPalConstraints.colorCountMax);
      expect(find.byType(KPalColorCardWidget), findsNWidgets(KPalConstraints.colorCountMax));
      await tapTooltip(tester, testL10n.cancel);
    });

    projectWidgetTest("puts the value range in order", _column, (final WidgetTester tester) async
    {
      await _openEditor(tester);
      final KPalRampSettings settings = _palette.colorRamps[0].settings;
      final KPixRangeSlider slider = tester.widget<KPixRangeSlider>(find.byType(KPixRangeSlider));

      slider.onChanged!(const RangeValues(70, 30));
      await tester.pump();

      expect(settings.valueRangeMin, 30);
      expect(settings.valueRangeMax, 70);

      slider.onChanged!(const RangeValues(20, 60));
      await tester.pump();

      expect(settings.valueRangeMin, 20);
      expect(settings.valueRangeMax, 60);
      await tapTooltip(tester, testL10n.cancel);
    });

    projectWidgetTest("changes the saturation curve", _column, (final WidgetTester tester) async
    {
      await _openEditor(tester);
      final KPalRampSettings settings = _palette.colorRamps[0].settings;
      final SatCurve other = SatCurve.values.firstWhere((final SatCurve c) => c != settings.satCurve);

      tester.widget<SegmentedButton<SatCurve>>(find.byType(SegmentedButton<SatCurve>)).onSelectionChanged!(<SatCurve>{other});
      await tester.pump();

      expect(settings.satCurve, other);
      await tapTooltip(tester, testL10n.cancel);
    });

    projectWidgetTest("goes back to the default of a setting when its label is tapped", _column, (final WidgetTester tester) async
    {
      await _openEditor(tester);
      final KPalRampSettings settings = _palette.colorRamps[0].settings;

      _slider(tester, 1).onChanged!(KPalConstraints.baseHueDefault + 50.0);
      _slider(tester, 2).onChanged!(KPalConstraints.hueShiftDefault + 2.0);
      _slider(tester, 4).onChanged!(KPalConstraints.baseSatDefault + 5.0);
      _slider(tester, 5).onChanged!(KPalConstraints.satShiftDefault + 2.0);
      await tester.pump();

      for (final String label in <String>[testL10n.baseHue, testL10n.hueShift, testL10n.baseSat, testL10n.satShift, testL10n.valueRange])
      {
        await tester.tap(find.text(label));
      }
      await tester.tap(find.text("↳ ${testL10n.exponent}").first);
      await tester.tap(find.text("↳ ${testL10n.exponent}").last);
      await tester.tap(find.text(testL10n.colorCount));
      await tester.pump();
      await tester.pump();

      expect(settings.baseHue, KPalConstraints.baseHueDefault);
      expect(settings.hueShift, KPalConstraints.hueShiftDefault);
      expect(settings.baseSat, KPalConstraints.baseSatDefault);
      expect(settings.satShift, KPalConstraints.satShiftDefault);
      expect(settings.hueShiftExp, KPalConstraints.hueShiftExpDefault);
      expect(settings.satShiftExp, KPalConstraints.satShiftExpDefault);
      expect(settings.valueRangeMin, KPalConstraints.valueRangeMinDefault);
      expect(settings.valueRangeMax, KPalConstraints.valueRangeMaxDefault);
      expect(settings.colorCount, KPalConstraints.colorCountDefault);
      await tapTooltip(tester, testL10n.cancel);
    });

    projectWidgetTest("keeps the changes when accepted, as an undo step", _column, (final WidgetTester tester) async
    {
      await _openEditor(tester);
      final KPalRampData ramp = _palette.colorRamps[0];

      _slider(tester, 1).onChanged!(200);
      await tester.pump();
      await tapTooltip(tester, testL10n.apply);

      expect(find.byType(KPal), findsNothing);
      expect(ramp.settings.baseHue, 200);
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.kPalChange);
    });

    projectWidgetTest("puts everything back when cancelled", _column, (final WidgetTester tester) async
    {
      await _openEditor(tester);
      final KPalRampData ramp = _palette.colorRamps[0];
      final int hue = ramp.settings.baseHue;
      final Color color = ramp.shiftedColors.first.value.color;

      _slider(tester, 1).onChanged!(hue == 100 ? 200 : 100);
      await tester.pump();
      expect(ramp.shiftedColors.first.value.color, isNot(color), reason: "setup");
      await tapTooltip(tester, testL10n.cancel);

      expect(find.byType(KPal), findsNothing);
      expect(ramp.settings.baseHue, hue);
      expect(ramp.shiftedColors.first.value.color, color);
    });

    for (final (String, int) change in <(String, int)>[("up", 2), ("down", -2)])
    {
      projectWidgetTest("puts the colors back when cancelled after the number of colors went ${change.$1}", _column, (final WidgetTester tester) async
      {
        await _openEditor(tester);
        final KPalRampData ramp = _palette.colorRamps[0];
        final int count = ramp.references.length;
        final List<Color> colors = <Color>[for (final ValueNotifier<IdColor> color in ramp.shiftedColors) color.value.color];

        _slider(tester, 0).onChanged!(count + change.$2.toDouble());
        await tester.pump();
        expect(ramp.references, hasLength(count + change.$2), reason: "setup");
        await tapTooltip(tester, testL10n.cancel);

        expect(find.byType(KPal), findsNothing);
        expect(ramp.references, hasLength(count));
        expect(<Color>[for (final ValueNotifier<IdColor> color in ramp.shiftedColors) color.value.color], colors);
      });
    }

    projectWidgetTest("adds no undo step when cancelled", _column, (final WidgetTester tester) async
    {
      final HistoryState? before = _history.getCurrentState();
      GetIt.I.get<ProjectSession>().hasChanges.value = false;
      await _openEditor(tester);

      await tapTooltip(tester, testL10n.cancel);

      expect(_history.getCurrentState(), same(before));
      expect(GetIt.I.get<ProjectSession>().hasChanges.value, isFalse);
    });

    projectWidgetTest("names what deleting a ramp would take with it", _column, (final WidgetTester tester) async
    {
      final KPalRampData ramp = _palette.colorRamps[0];
      final DrawingLayerState layer = GetIt.I.get<DocumentState>().timeline.getCurrentLayer()! as DrawingLayerState;
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 1, y: 1): ramp.references[0], CoordinateSetI(x: 2, y: 2): ramp.references[1]}));
      await settleUi(tester);
      await _openEditor(tester);

      await tapTooltip(tester, testL10n.delete);

      expect(find.textContaining(testL10n.deleteColorRampQuestion(amount: 2)), findsOneWidget);

      await tapTooltip(tester, testL10n.no);
      expect(_palette.colorRamps.first, same(ramp), reason: "no deletes nothing");
      expect(find.byType(KPal), findsOneWidget);
      await tapTooltip(tester, testL10n.cancel);
    });

    projectWidgetTest("deletes the ramp when confirmed", _column, (final WidgetTester tester) async
    {
      final KPalRampData ramp = _palette.colorRamps[0];
      final int count = _palette.colorRamps.length;
      await _openEditor(tester);

      await tapTooltip(tester, testL10n.delete);
      await tapTooltip(tester, testL10n.yes);

      expect(find.byType(KPal), findsNothing);
      expect(_palette.colorRamps, hasLength(count - 1));
      expect(_palette.colorRamps, isNot(contains(ramp)));
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.kPalDelete);
    });

    projectWidgetTest("says so when the last ramp cannot be deleted", _column, (final WidgetTester tester) async
    {
      _palette.colorRamps = <KPalRampData>[_palette.colorRamps.first];
      await tester.pump();
      await _openEditor(tester);

      await tapTooltip(tester, testL10n.delete);
      await tapTooltip(tester, testL10n.yes);
      await tester.pump(const Duration(milliseconds: 300));

      expect(_palette.colorRamps, hasLength(1));
      expect(find.text(testL10n.needAtLeastColorRamps(count: KPalConstraints.rampCountMin)), findsOneWidget);
    });

    group("preview", ()
    {
      Future<ByteData> bytesOf(final WidgetTester tester, final ui.Image image) async
      {
        return (await tester.runAsync(() => image.toByteData()))!;
      }

      Future<void> waitForPreview(final WidgetTester tester) async
      {
        for (int i = 0; i < 12; i++)
        {
          await tester.pump(const Duration(milliseconds: 150));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        }
        await tester.pump();
      }

      projectWidgetTest("shows the image", _column, (final WidgetTester tester) async
      {
        final DrawingLayerState layer = GetIt.I.get<DocumentState>().timeline.getCurrentLayer()! as DrawingLayerState;
        layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 1, y: 1): _palette.colorRamps[0].references[0]}));
        await settleUi(tester);
        await _openEditor(tester);

        await waitForPreview(tester);

        final ui.Image? image = tester.widget<RawImage>(find.byType(RawImage).last).image;
        expect(image, isNotNull);
        final ByteData bytes = await bytesOf(tester, image!);
        final CoordinateSetI size = GetIt.I.get<CanvasState>().canvasSize;
        expect(bytes.getUint8((1 * size.x + 1) * 4 + 3), 255, reason: "the pixel is there");
        expect(bytes.getUint8(3), 0, reason: "and nothing else");
        await tapTooltip(tester, testL10n.cancel);
        await tester.pump(const Duration(seconds: 1));
      });

      projectWidgetTest("shows dither as dither", _column, (final WidgetTester tester) async
      {
        final DrawingLayerState layer = GetIt.I.get<DocumentState>().timeline.getCurrentLayer()! as DrawingLayerState;
        final List<ColorReference> references = _palette.colorRamps[0].references;
        final Set<CoordinateSetI> block = <CoordinateSetI>{
          for (int x = 0; x < 8; x++)
            for (int y = 0; y < 8; y++) CoordinateSetI(x: x, y: y),
        };
        layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{for (final CoordinateSetI c in block) c: references[2]}));
        final DitherLayerState dither = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.dither, addToHistoryStack: false).$2! as DitherLayerState;
        dither.addCoords(coords: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{for (final CoordinateSetI c in block) c: 2}));
        await waitForPreview(tester);
        final Set<int> pattern = <int>{for (final CoordinateSetI c in block) dither.getDisplayValueAt(coord: c)};
        expect(pattern.length, greaterThan(1), reason: "setup: a real dither pattern");
        await _openEditor(tester);

        await waitForPreview(tester);

        final ByteData preview = await bytesOf(tester, tester.widget<RawImage>(find.byType(RawImage).last).image!);
        final Set<int> colors = <int>{for (int i = 0; i < 64; i++) preview.getUint32(i * 4)};
        expect(colors.length, greaterThan(1), reason: "the pattern shows");
        await tapTooltip(tester, testL10n.cancel);
        await tester.pump(const Duration(seconds: 1));
      });
    });
  });

  group("the tool under the palette", ()
  {
    projectWidgetTest("comes back when a color is picked", _column, (final WidgetTester tester) async
    {
      final ToolState tools = GetIt.I.get<ToolState>();
      tools.setToolSelection(tool: ToolType.line);
      tools.setToolSelection(tool: ToolType.select);

      await tester.tap(find.byType(ColorEntryWidget).at(1));
      await tester.pump();

      expect(tools.selectedTool, ToolType.line);
    });
  });
}
