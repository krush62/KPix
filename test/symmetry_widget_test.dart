import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/symmetry_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/main/symmetry_widget.dart';
import 'package:toastification/toastification.dart';

import 'support/selection_harness.dart';

class _Scene
{
  final WidgetTester tester;
  final SymmetryState state;
  _Scene(this.tester, this.state);

  AppLocalizations get l10n => AppLocalizations.of(tester.element(find.byType(SymmetryWidget)))!;

  Future<void> settle() async
  {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Switch switchAt(final int index) => tester.widget<Switch>(find.byType(Switch).at(index));
  KPixSlider sliderAt(final int index) => tester.widget<KPixSlider>(find.byType(KPixSlider).at(index));
  IconButton center(final String tooltip) => tester.widget<IconButton>(find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton)));
}

void main()
{
  void symmetryTest(final String description, final Future<void> Function(_Scene scene) body)
  {
    testWidgets(description, (final WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        await bootProject(canvasSize: CoordinateSetI(x: 8, y: 32));
      });
      final SymmetryState state = GetIt.I.get<SymmetryState>();
      await tester.pumpWidget(ToastificationWrapper(child: MaterialApp(
        theme: monochromeTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Material(child: Center(child: SizedBox(width: 900, height: 500, child: Align(alignment: Alignment.bottomCenter, child: SymmetryWidget(state: state))))),
      ),),);
      final _Scene scene = _Scene(tester, state);
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up));
      await scene.settle();

      await body(scene);

      await tester.pumpWidget(const SizedBox.shrink());
      for (final Frame frame in GetIt.I.get<DocumentState>().timeline.frames.value)
      {
        for (int i = 0; i < frame.layerList.length; i++)
        {
          frame.layerList.getLayer(index: i).dispose();
        }
      }
      await tester.pump(const Duration(seconds: 1));
    });
  }

  group("each ruler has its own controls", () {
    symmetryTest("the switches write their own activation", (final _Scene scene) async {
      await scene.tester.tap(find.byType(Switch).at(0));
      await scene.settle();
      expect(scene.state.horizontalActivated.value, true);
      expect(scene.state.verticalActivated.value, false);
      expect(scene.switchAt(0).value, true);
      expect(scene.switchAt(1).value, false);

      await scene.tester.tap(find.byType(Switch).at(1));
      await scene.settle();
      expect(scene.state.verticalActivated.value, true);
      expect(scene.switchAt(1).value, true);

      await scene.tester.tap(find.byType(Switch).at(0));
      await scene.settle();
      expect(scene.state.horizontalActivated.value, false);
      expect(scene.state.verticalActivated.value, true);
    });

    symmetryTest("the sliders only work while their ruler is on", (final _Scene scene) async {
      expect(scene.sliderAt(0).onChanged, isNull);
      expect(scene.sliderAt(1).onChanged, isNull);

      scene.state.horizontalActivated.value = true;
      await scene.settle();
      expect(scene.sliderAt(0).onChanged, isNotNull);
      expect(scene.sliderAt(1).onChanged, isNull);

      scene.state.horizontalActivated.value = false;
      scene.state.verticalActivated.value = true;
      await scene.settle();
      expect(scene.sliderAt(0).onChanged, isNull);
      expect(scene.sliderAt(1).onChanged, isNotNull);
    });

    symmetryTest("the center buttons only work while their ruler is on", (final _Scene scene) async {
      final AppLocalizations l10n = scene.l10n;
      expect(scene.center(l10n.centerHorizontalRuler).onPressed, isNull);
      expect(scene.center(l10n.centerVerticalRuler).onPressed, isNull);

      scene.state.horizontalActivated.value = true;
      await scene.settle();
      expect(scene.center(l10n.centerHorizontalRuler).onPressed, isNotNull);
      expect(scene.center(l10n.centerVerticalRuler).onPressed, isNull);
    });

    symmetryTest("the center buttons center their ruler on its axis", (final _Scene scene) async {
      final AppLocalizations l10n = scene.l10n;
      scene.state.horizontalActivated.value = true;
      scene.state.verticalActivated.value = true;
      scene.state.horizontalValue.value = 1.0;
      scene.state.verticalValue.value = 1.0;
      await scene.settle();

      await scene.tester.tap(find.byTooltip(l10n.centerHorizontalRuler));
      await scene.settle();
      expect(scene.state.horizontalValue.value, 4.0);
      expect(scene.state.verticalValue.value, 1.0);

      await scene.tester.tap(find.byTooltip(l10n.centerVerticalRuler));
      await scene.settle();
      expect(scene.state.verticalValue.value, 16.0);
      expect(scene.state.horizontalValue.value, 4.0);
    });

    symmetryTest("the sliders reach as far as their axis", (final _Scene scene) async {
      expect(scene.sliderAt(0).min, 1.0);
      expect(scene.sliderAt(0).max, 7.0);
      expect(scene.sliderAt(1).min, 1.0);
      expect(scene.sliderAt(1).max, 31.0);
      expect(GetIt.I.get<CanvasState>().canvasSize.x, 8);
    });

    symmetryTest("the sliders follow their own value", (final _Scene scene) async {
      scene.state.horizontalValue.value = 2.5;
      await scene.settle();
      expect(scene.sliderAt(0).value, 2.5);
      expect(scene.sliderAt(0).label, "2.5");
      expect(scene.sliderAt(1).label, isNot("2.5"));

      scene.state.verticalValue.value = 3.5;
      await scene.settle();
      expect(scene.sliderAt(1).value, 3.5);
      expect(scene.sliderAt(1).label, "3.5");
      expect(scene.sliderAt(0).value, 2.5);
    });

    symmetryTest("the sliders write half steps to their own value", (final _Scene scene) async {
      scene.state.horizontalActivated.value = true;
      scene.state.verticalActivated.value = true;
      await scene.settle();
      final double vertical = scene.state.verticalValue.value;

      scene.sliderAt(0).onChanged!(2.7);
      expect(scene.state.horizontalValue.value, 2.5);
      expect(scene.state.verticalValue.value, vertical);

      scene.sliderAt(1).onChanged!(3.8);
      expect(scene.state.verticalValue.value, 4.0);
      expect(scene.state.horizontalValue.value, 2.5);
    });

    symmetryTest("the icons sit on the side of their ruler", (final _Scene scene) async {
      final WidgetTester tester = scene.tester;
      final double middle = tester.getCenter(find.byType(SymmetryWidget)).dx;
      final Finder horizontal = find.byIcon(TablerIcons.flip_vertical).last;
      expect(tester.getCenter(horizontal).dx, lessThan(middle));
      expect(tester.getCenter(find.byIcon(TablerIcons.flip_horizontal)).dx, greaterThan(middle));
      expect(tester.getCenter(find.byIcon(TablerIcons.layout_align_middle)).dx, lessThan(middle));
      expect(tester.getCenter(find.byIcon(TablerIcons.layout_align_center)).dx, greaterThan(middle));
      final Icon icon = tester.widget<Icon>(horizontal);
      expect(icon.color, Theme.of(tester.element(find.byType(SymmetryWidget))).primaryColorDark);
    });
  });

  group("rebuilds", () {
    symmetryTest("a value only touches its own slider", (final _Scene scene) async {
      final KPixSlider horizontal = scene.sliderAt(0);
      final KPixSlider vertical = scene.sliderAt(1);
      final Switch toggle = scene.switchAt(0);

      scene.state.horizontalValue.value = 2.5;
      await scene.settle();
      expect(identical(scene.sliderAt(0), horizontal), false);
      expect(identical(scene.sliderAt(1), vertical), true);
      expect(identical(scene.switchAt(0), toggle), true);
    });

    symmetryTest("an activation does not touch the other ruler", (final _Scene scene) async {
      final KPixSlider vertical = scene.sliderAt(1);
      final Switch toggle = scene.switchAt(1);

      scene.state.horizontalActivated.value = true;
      await scene.settle();
      expect(identical(scene.sliderAt(1), vertical), true);
      expect(identical(scene.switchAt(1), toggle), true);
    });
  });
}
