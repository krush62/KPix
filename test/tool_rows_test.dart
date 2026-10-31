import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/tool_options/tool_gui.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

Widget _app(final Widget child)
{
  return MaterialApp(
    theme: monochromeTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Material(child: Center(child: SizedBox(width: 400, height: 200, child: child))),
  );
}

void main()
{
  group("ToolSliderRow", () {
    KPixSlider slider(final WidgetTester tester) => tester.widget<KPixSlider>(find.byType(KPixSlider));

    testWidgets("shows its label next to the slider", (final WidgetTester tester) async {
      await tester.pumpWidget(_app(ToolSliderRow<int>(label: "row", notifier: ValueNotifier<int>(1))));
      expect(tester.getCenter(find.text("row")).dy, closeTo(tester.getCenter(find.byType(KPixSlider)).dy, 1));
    });

    testWidgets("rounds whole numbers", (final WidgetTester tester) async {
      final ValueNotifier<int> notifier = ValueNotifier<int>(1);
      await tester.pumpWidget(_app(ToolSliderRow<int>(label: "row", notifier: notifier, maxVal: 9)));
      slider(tester).onChanged!(2.6);
      expect(notifier.value, 3);
    });

    testWidgets("keeps decimals as they are", (final WidgetTester tester) async {
      final ValueNotifier<double> notifier = ValueNotifier<double>(1);
      await tester.pumpWidget(_app(ToolSliderRow<double>(label: "row", notifier: notifier, maxVal: 9)));
      slider(tester).onChanged!(2.6);
      expect(notifier.value, 2.6);
    });

    testWidgets("passes its limits and precision on", (final WidgetTester tester) async {
      await tester.pumpWidget(_app(ToolSliderRow<double>(label: "row", notifier: ValueNotifier<double>(2), minVal: 1, maxVal: 3, decimals: 2)));
      expect(slider(tester).min, 1);
      expect(slider(tester).max, 3);
      expect(slider(tester).decimals, 2);
      expect(slider(tester).value, 2);
    });

    testWidgets("shows the value itself without a label builder", (final WidgetTester tester) async {
      await tester.pumpWidget(_app(ToolSliderRow<int>(label: "row", notifier: ValueNotifier<int>(1))));
      expect(slider(tester).label, isNull);
      expect(slider(tester).decimals, 0);
    });

    testWidgets("uses its label builder", (final WidgetTester tester) async {
      await tester.pumpWidget(_app(ToolSliderRow<int>(label: "row", notifier: ValueNotifier<int>(1), labelBuilder: (final int value) => "$value%")));
      expect(slider(tester).label, "1%");
    });

    testWidgets("can be turned off", (final WidgetTester tester) async {
      await tester.pumpWidget(_app(ToolSliderRow<int>(label: "row", notifier: ValueNotifier<int>(1), enabled: false)));
      expect(slider(tester).onChanged, isNull);
    });

    testWidgets("is on by default", (final WidgetTester tester) async {
      await tester.pumpWidget(_app(ToolSliderRow<int>(label: "row", notifier: ValueNotifier<int>(1))));
      expect(slider(tester).onChanged, isNotNull);
      expect(slider(tester).onChangedEnd, isNull);
    });

    testWidgets("reports the end of a change", (final WidgetTester tester) async {
      double? ended;
      await tester.pumpWidget(_app(ToolSliderRow<int>(label: "row", notifier: ValueNotifier<int>(1), onChangedEnd: (final double value) {ended = value;})));
      slider(tester).onChangedEnd!(0.5);
      expect(ended, 0.5);
    });

    testWidgets("rebuilds with its value", (final WidgetTester tester) async {
      final ValueNotifier<int> notifier = ValueNotifier<int>(1);
      await tester.pumpWidget(_app(ToolSliderRow<int>(label: "row", notifier: notifier, maxVal: 9)));
      notifier.value = 7;
      await tester.pump();
      expect(slider(tester).value, 7);
    });
  });

  group("the column of a row", () {
    final ValueNotifier<bool> toggle = ValueNotifier<bool>(false);
    final Map<String, Widget Function()> rows = <String, Widget Function()>{
      "ToolSliderRow": () => ToolSliderRow<int>(label: "row", notifier: ValueNotifier<int>(1)),
      "ToolSwitchRow": () => ToolSwitchRow(label: "row", notifier: toggle),
      "ToolModifierSwitchRow": () => ToolModifierSwitchRow(label: "row", notifier: toggle, unmodifiedNotifier: toggle, modifierNotifier: ValueNotifier<bool>(false), defaultState: false),
      "ToolDropdownRow": () => ToolDropdownRow<int>(label: "row", notifier: ValueNotifier<int>(1), valueMap: const <int, String>{1: "one", 2: "two"}),
    };

    for (final MapEntry<String, Widget Function()> row in rows.entries)
    {
      testWidgets("${row.key} is wide by default", (final WidgetTester tester) async {
        await tester.pumpWidget(_app(row.value()));
        final List<Expanded> columns = tester.widgetList<Expanded>(find.descendant(of: find.byType(row.value().runtimeType), matching: find.byType(Expanded))).toList();
        expect(columns.first.flex, 1);
        expect(columns[1].flex, ToolSettingsWidgetOptions.columnWidthRatio);
      });
    }
  });

  group("DialogActionButton", () {
    Widget button({final VoidCallback? onPressed, final double? iconSize, final double? padding})
    {
      return Row(children: <Widget>[
        if (padding == null)
          DialogActionButton(tooltip: "tip", icon: Icons.add, onPressed: onPressed, iconSize: iconSize)
        else
          DialogActionButton(tooltip: "tip", icon: Icons.add, onPressed: onPressed, iconSize: iconSize, padding: padding),
      ],);
    }

    testWidgets("shows its tooltip and icon", (final WidgetTester tester) async {
      await tester.pumpWidget(_app(button(onPressed: () {})));
      expect(find.byTooltip("tip"), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets("reports a press", (final WidgetTester tester) async {
      int pressed = 0;
      await tester.pumpWidget(_app(button(onPressed: () {pressed++;})));
      await tester.tap(find.byType(IconButton));
      expect(pressed, 1);
    });

    testWidgets("is off without a callback", (final WidgetTester tester) async {
      await tester.pumpWidget(_app(button()));
      expect(tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
    });

    testWidgets("shares the row", (final WidgetTester tester) async {
      await tester.pumpWidget(_app(button(onPressed: () {})));
      expect(tester.getSize(find.byType(Expanded)).width, 400);
    });

    testWidgets("has the padding of a dialog", (final WidgetTester tester) async {
      await tester.pumpWidget(_app(button(onPressed: () {})));
      final Padding padding = tester.widget<Padding>(find.ancestor(of: find.byType(IconButton), matching: find.byType(Padding)).first);
      expect(padding.padding, const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding));
    });

    testWidgets("can have another padding", (final WidgetTester tester) async {
      await tester.pumpWidget(_app(button(onPressed: () {}, padding: 3)));
      final Padding padding = tester.widget<Padding>(find.ancestor(of: find.byType(IconButton), matching: find.byType(Padding)).first);
      expect(padding.padding, const EdgeInsets.all(3));
    });

    testWidgets("can size its icon", (final WidgetTester tester) async {
      await tester.pumpWidget(_app(button(onPressed: () {}, iconSize: 17)));
      expect(tester.widget<Icon>(find.byIcon(Icons.add)).size, 17);
    });
  });
}
