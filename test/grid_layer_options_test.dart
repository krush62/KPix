import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/models/constraints/grid_layer_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/controls/kpix_range_slider.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/tools/grid_layer_options_widget.dart';
import 'package:toastification/toastification.dart';

import 'support/selection_harness.dart';

class _Scene
{
  final WidgetTester tester;
  final GridLayerState grid;
  _Scene(this.tester, this.grid);

  AppLocalizations get l10n => AppLocalizations.of(tester.element(find.byType(GridLayerOptionsWidget)))!;
  bool get committed => GetIt.I.get<HistoryManager>().hasUndo.value;

  Future<void> settle() async
  {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> type(final GridType type) async
  {
    grid.gridTypeNotifier.value = type;
    await settle();
  }

  /// The control that sits next to [label], so a mixed up row is noticed.
  Finder _inRowOf(final String label, final Type control) => find.descendant(of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first, matching: find.byType(control));
  Finder finderFor(final String label) => _inRowOf(label, KPixSlider);
  KPixSlider slider(final String label) => tester.widget<KPixSlider>(finderFor(label));
  KPixRangeSlider range(final String label) => tester.widget<KPixRangeSlider>(_inRowOf(label, KPixRangeSlider));
}

void main()
{
  void gridTest(final String description, final Future<void> Function(_Scene scene) body)
  {
    testWidgets(description, (final WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        await bootProject(canvasSize: CoordinateSetI(x: 8, y: 8));
      });
      final GridLayerState grid = GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.addNewGridLayer(select: true).$2!;
      await tester.pumpWidget(ToastificationWrapper(child: MaterialApp(
        theme: monochromeTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Material(child: Center(child: SizedBox(width: 400, height: 800, child: GridLayerOptionsWidget(gridState: grid)))),
      ),),);
      final _Scene scene = _Scene(tester, grid);
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

  group("the rows of a grid type", () {
    void expectLabels(final _Scene scene, {required final List<String> shown, required final List<String> hidden})
    {
      for (final String label in shown)
      {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      for (final String label in hidden)
      {
        expect(find.text(label), findsNothing, reason: label);
      }
    }

    gridTest("a normal grid has two intervals and no perspective", (final _Scene scene) async {
      final AppLocalizations l10n = scene.l10n;
      for (final GridType type in GridType.values.where((final GridType t) => !isPerspectiveGridType(gridType: t)))
      {
        await scene.type(type);
        expectLabels(scene,
          shown: <String>[l10n.opacity, l10n.brightness, l10n.intervalX, l10n.intervalY],
          hidden: <String>[l10n.interval, l10n.horizon, l10n.vanishingPoint, l10n.horPoints, l10n.verPoint],
        );
        expect(find.byType(KPixRangeSlider), findsNothing);
      }
    });

    gridTest("one point has a horizon and a vanishing point", (final _Scene scene) async {
      final AppLocalizations l10n = scene.l10n;
      await scene.type(GridType.onePointPerspective);
      expectLabels(scene,
        shown: <String>[l10n.opacity, l10n.brightness, l10n.interval, l10n.horizon, l10n.vanishingPoint],
        hidden: <String>[l10n.intervalX, l10n.intervalY, l10n.horPoints, l10n.verPoint],
      );
      expect(find.byType(KPixRangeSlider), findsNothing);
    });

    gridTest("two points have a range instead of a vanishing point", (final _Scene scene) async {
      final AppLocalizations l10n = scene.l10n;
      await scene.type(GridType.twoPointPerspective);
      expectLabels(scene,
        shown: <String>[l10n.opacity, l10n.brightness, l10n.interval, l10n.horizon, l10n.horPoints],
        hidden: <String>[l10n.intervalX, l10n.intervalY, l10n.vanishingPoint, l10n.verPoint],
      );
      expect(find.byType(KPixRangeSlider), findsOneWidget);
    });

    gridTest("three points add a vertical point", (final _Scene scene) async {
      final AppLocalizations l10n = scene.l10n;
      await scene.type(GridType.threePointPerspective);
      expectLabels(scene,
        shown: <String>[l10n.opacity, l10n.brightness, l10n.interval, l10n.horizon, l10n.horPoints, l10n.verPoint],
        hidden: <String>[l10n.intervalX, l10n.intervalY, l10n.vanishingPoint],
      );
      expect(find.byType(KPixRangeSlider), findsOneWidget);
    });

    gridTest("the sliders sit in the wide column", (final _Scene scene) async {
      final Expanded column = scene.tester.widget<Expanded>(find.ancestor(of: scene.finderFor(scene.l10n.opacity), matching: find.byType(Expanded)).first);
      expect(column.flex, ToolSettingsWidgetOptions.columnWidthRatio);
    });
  });

  group("the whole number rows", () {
    final List<({String name, String Function(AppLocalizations) label, ValueNotifier<int> Function(GridLayerState) notifier, int min, int max, GridType type})> rows = <({String name, String Function(AppLocalizations) label, ValueNotifier<int> Function(GridLayerState) notifier, int min, int max, GridType type})>[
      (name: "opacity", label: (final AppLocalizations l) => l.opacity, notifier: (final GridLayerState g) => g.opacityNotifier, min: GridLayerConstraints.opacityMin, max: GridLayerConstraints.opacityMax, type: GridType.rectangular),
      (name: "brightness", label: (final AppLocalizations l) => l.brightness, notifier: (final GridLayerState g) => g.brightnessNotifier, min: GridLayerConstraints.brightnessMin, max: GridLayerConstraints.brightnessMax, type: GridType.rectangular),
      (name: "interval x", label: (final AppLocalizations l) => l.intervalX, notifier: (final GridLayerState g) => g.intervalXNotifier, min: GridLayerConstraints.intervalXMin, max: GridLayerConstraints.intervalXMax, type: GridType.rectangular),
      (name: "interval y", label: (final AppLocalizations l) => l.intervalY, notifier: (final GridLayerState g) => g.intervalYNotifier, min: GridLayerConstraints.intervalYMin, max: GridLayerConstraints.intervalYMax, type: GridType.rectangular),
      (name: "interval", label: (final AppLocalizations l) => l.interval, notifier: (final GridLayerState g) => g.intervalXNotifier, min: GridLayerConstraints.intervalXMin, max: GridLayerConstraints.intervalXMax, type: GridType.onePointPerspective),
    ];

    for (final ({String name, String Function(AppLocalizations) label, ValueNotifier<int> Function(GridLayerState) notifier, int min, int max, GridType type}) row in rows)
    {
      gridTest("${row.name} shows, follows and writes its value", (final _Scene scene) async {
        await scene.type(row.type);
        final String label = row.label(scene.l10n);
        final ValueNotifier<int> notifier = row.notifier(scene.grid);
        expect(scene.slider(label).min, row.min.toDouble());
        expect(scene.slider(label).max, row.max.toDouble());
        expect(scene.slider(label).value, notifier.value.toDouble());
        expect(scene.slider(label).decimals, 0);

        final int target = row.min + 1;
        notifier.value = target;
        await scene.settle();
        expect(scene.slider(label).value, target.toDouble());

        scene.slider(label).onChanged!(target + 0.6);
        expect(notifier.value, target + 1);
        scene.slider(label).onChanged!(target + 1.4);
        expect(notifier.value, target + 1);
      });

      gridTest("${row.name} commits at the end of a change", (final _Scene scene) async {
        await scene.type(row.type);
        final String label = row.label(scene.l10n);
        expect(scene.committed, false);
        scene.slider(label).onChanged!(row.min + 1.0);
        expect(scene.committed, false);
        scene.slider(label).onChangedEnd!(row.min + 1.0);
        expect(scene.committed, true);
      });
    }

    gridTest("only opacity shows a percentage", (final _Scene scene) async {
      final AppLocalizations l10n = scene.l10n;
      scene.grid.opacityNotifier.value = 42;
      await scene.settle();
      expect(scene.slider(l10n.opacity).label, "42%");
      expect(scene.slider(l10n.brightness).label, isNull);
      expect(scene.slider(l10n.intervalX).label, isNull);
      expect(scene.slider(l10n.intervalY).label, isNull);
    });
  });

  group("the position rows", () {
    final List<({String name, String Function(AppLocalizations) label, ValueNotifier<double> Function(GridLayerState) notifier, GridType type})> rows = <({String name, String Function(AppLocalizations) label, ValueNotifier<double> Function(GridLayerState) notifier, GridType type})>[
      (name: "horizon", label: (final AppLocalizations l) => l.horizon, notifier: (final GridLayerState g) => g.horizonPositionNotifier, type: GridType.onePointPerspective),
      (name: "vanishing point", label: (final AppLocalizations l) => l.vanishingPoint, notifier: (final GridLayerState g) => g.vanishingPoint1Notifier, type: GridType.onePointPerspective),
      (name: "vertical point", label: (final AppLocalizations l) => l.verPoint, notifier: (final GridLayerState g) => g.vanishingPoint3Notifier, type: GridType.threePointPerspective),
    ];

    for (final ({String name, String Function(AppLocalizations) label, ValueNotifier<double> Function(GridLayerState) notifier, GridType type}) row in rows)
    {
      gridTest("${row.name} shows, follows and writes its value", (final _Scene scene) async {
        await scene.type(row.type);
        final String label = row.label(scene.l10n);
        final ValueNotifier<double> notifier = row.notifier(scene.grid);
        expect(scene.slider(label).min, GridLayerConstraints.vanishingPointMin);
        expect(scene.slider(label).max, GridLayerConstraints.vanishingPointMax);
        expect(scene.slider(label).decimals, 2);
        expect(scene.slider(label).label, isNull);

        notifier.value = 0.25;
        await scene.settle();
        expect(scene.slider(label).value, 0.25);

        scene.slider(label).onChanged!(0.375);
        expect(notifier.value, 0.375);

        expect(scene.committed, false);
        scene.slider(label).onChangedEnd!(0.375);
        expect(scene.committed, true);
      });
    }
  });

  group("the range of horizontal points", () {
    gridTest("follows each end on its own", (final _Scene scene) async {
      await scene.type(GridType.twoPointPerspective);
      final String label = scene.l10n.horPoints;
      scene.grid.vanishingPoint1Notifier.value = 0.125;
      await scene.settle();
      expect(scene.range(label).values.start, 0.125);
      expect(scene.range(label).values.end, scene.grid.vanishingPoint2);

      scene.grid.vanishingPoint2Notifier.value = 0.625;
      await scene.settle();
      expect(scene.range(label).values.start, 0.125);
      expect(scene.range(label).values.end, 0.625);
    });

    gridTest("has the limits and precision of a position", (final _Scene scene) async {
      await scene.type(GridType.threePointPerspective);
      final KPixRangeSlider range = scene.range(scene.l10n.horPoints);
      expect(range.min, GridLayerConstraints.vanishingPointMin);
      expect(range.max, GridLayerConstraints.vanishingPointMax);
      expect(range.decimals, 2);
    });

    gridTest("writes both ends and commits at the end of a change", (final _Scene scene) async {
      await scene.type(GridType.twoPointPerspective);
      final String label = scene.l10n.horPoints;
      scene.range(label).onChanged!(const RangeValues(0.25, 0.75));
      expect(scene.grid.vanishingPoint1Notifier.value, 0.25);
      expect(scene.grid.vanishingPoint2Notifier.value, 0.75);
      expect(scene.committed, false);

      scene.range(label).onChangedEnd!(const RangeValues(0.25, 0.75));
      expect(scene.committed, true);
    });
  });

  group("the type buttons", () {
    gridTest("commit a change between grid and perspective", (final _Scene scene) async {
      await scene.tester.tap(find.byTooltip(scene.l10n.perspective));
      await scene.settle();
      expect(isPerspectiveGridType(gridType: scene.grid.gridType), true);
      expect(scene.committed, true);
    });

    gridTest("commit a change of the grid type", (final _Scene scene) async {
      await scene.tester.tap(find.byTooltip(GridType.values.firstWhere((final GridType t) => t != scene.grid.gridType && !isPerspectiveGridType(gridType: t)).desc(scene.l10n)));
      await scene.settle();
      expect(scene.committed, true);
    });

    gridTest("return to the type used last", (final _Scene scene) async {
      final AppLocalizations l10n = scene.l10n;
      await scene.tester.tap(find.byTooltip(l10n.perspective));
      await scene.settle();
      await scene.tester.tap(find.byTooltip(GridType.threePointPerspective.desc(l10n)));
      await scene.settle();
      await scene.tester.tap(find.byTooltip(l10n.grid));
      await scene.settle();
      await scene.tester.tap(find.byTooltip(l10n.perspective));
      await scene.settle();
      expect(scene.grid.gridType, GridType.threePointPerspective);
    });
  });

  group("rebuilds", () {
    gridTest("a value only touches its own row", (final _Scene scene) async {
      final AppLocalizations l10n = scene.l10n;
      final KPixSlider opacity = scene.slider(l10n.opacity);
      final KPixSlider brightness = scene.slider(l10n.brightness);
      final KPixSlider intervalX = scene.slider(l10n.intervalX);

      scene.grid.opacityNotifier.value = GridLayerConstraints.opacityMin + 1;
      await scene.settle();
      expect(identical(scene.slider(l10n.opacity), opacity), false);
      expect(identical(scene.slider(l10n.brightness), brightness), true);
      expect(identical(scene.slider(l10n.intervalX), intervalX), true);
    });

    gridTest("a range end does not touch the other rows", (final _Scene scene) async {
      await scene.type(GridType.threePointPerspective);
      final AppLocalizations l10n = scene.l10n;
      final KPixRangeSlider range = scene.range(l10n.horPoints);
      final KPixSlider vertical = scene.slider(l10n.verPoint);
      final KPixSlider horizon = scene.slider(l10n.horizon);

      scene.grid.vanishingPoint1Notifier.value = 0.05;
      await scene.settle();
      expect(identical(scene.range(l10n.horPoints), range), false);
      expect(identical(scene.slider(l10n.verPoint), vertical), true);
      expect(identical(scene.slider(l10n.horizon), horizon), true);
    });
  });
}
