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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/util/app_directories.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/palette/palette_manager_entry_widget.dart';
import 'package:kpix/widgets/palette/palette_manager_widget.dart';
import 'package:kpix/widgets/palette/save_palette_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import 'support/project_files.dart';
import 'support/selection_harness.dart';
import 'support/widget_harness.dart';

final CoordinateSetI _pixel = CoordinateSetI(x: 1, y: 1);

PaletteState get _palette => GetIt.I.get<PaletteState>();

/// Shows the manager with its list in place. [dismissed] counts how often it wanted to go.
Future<void> _withManager(final WidgetTester tester, final Future<void> Function(ValueNotifier<int> dismissed, AppPaths paths) body) async
{
  final ValueNotifier<int> dismissed = ValueNotifier<int>(0);
  final AppPaths paths = createTestPaths();
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async
  {
    await bootProject(canvasSize: CoordinateSetI(x: 4, y: 4), appPaths: paths);
    await createInternalDirectories();
  });
  await tester.pumpWidget(testApp(child: Center(child: PaletteManagerWidget(dismiss: () {dismissed.value++;}))));
  for (int i = 0; i < 100 && find.byType(PaletteManagerEntryWidget).evaluate().length < 2; i++)
  {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 20));
  }
  await settleUi(tester);

  await body(dismissed, paths);

  await closeTestApp(tester);
}

void _paintPixel()
{
  final DrawingLayerState layer = GetIt.I.get<DocumentState>().timeline.getCurrentLayer()! as DrawingLayerState;
  layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{_pixel: _palette.colorRamps.first.references.first}));
}

Future<void> _selectEntry(final WidgetTester tester, {final int index = 0}) async
{
  await tester.tap(find.byType(PaletteManagerEntryWidget).at(index));
  await settleUi(tester);
}

IconButton _button(final WidgetTester tester, final String tooltip)
{
  return tester.widget<IconButton>(find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton)).first);
}

Future<void> _savePalette(final WidgetTester tester, {required final String name}) async
{
  await tapTooltip(tester, testL10n.saveCurrentPalette);
  await tester.enterText(find.descendant(of: find.byType(SavePaletteWidget), matching: find.byType(TextField)), name);
  await tester.pump();
  await tapTooltip(tester, testL10n.savePalette);
  for (int i = 0; i < 10; i++)
  {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main()
{
  group("the palette manager", ()
  {
    testWidgets("only offers what needs a selection once there is one", (final WidgetTester tester) async
    {
      await _withManager(tester, (final ValueNotifier<int> dismissed, final AppPaths paths) async
      {
        expect(_button(tester, testL10n.applySelectedPalette).onPressed, isNull);
        expect(_button(tester, testL10n.appendToCurrentPalette).onPressed, isNull);

        await _selectEntry(tester);

        expect(_button(tester, testL10n.applySelectedPalette).onPressed, isNotNull);
        expect(_button(tester, testL10n.appendToCurrentPalette).onPressed, isNotNull);
      });
    });

    testWidgets("closes with its button", (final WidgetTester tester) async
    {
      await _withManager(tester, (final ValueNotifier<int> dismissed, final AppPaths paths) async
      {
        await tapTooltip(tester, testL10n.close);

        expect(dismissed.value, 1);
      });
    });

    testWidgets("replaces the palette right away on an empty project", (final WidgetTester tester) async
    {
      await _withManager(tester, (final ValueNotifier<int> dismissed, final AppPaths paths) async
      {
        final List<KPalRampData> before = _palette.colorRamps;
        await _selectEntry(tester);

        await tapTooltip(tester, testL10n.applySelectedPalette);

        expect(find.text(testL10n.remapExistingColors), findsNothing);
        expect(_palette.colorRamps, isNot(same(before)));
        expect(dismissed.value, 1);
      });
    });

    group("with pixels in the project", ()
    {
      Future<void> askToApply(final WidgetTester tester) async
      {
        _paintPixel();
        await tester.runAsync(settle);
        await _selectEntry(tester);
        await tapTooltip(tester, testL10n.applySelectedPalette);
        expect(find.text(testL10n.remapExistingColors), findsOneWidget, reason: "setup");
      }

      testWidgets("keeps the pixels in the closest colors on yes", (final WidgetTester tester) async
      {
        await _withManager(tester, (final ValueNotifier<int> dismissed, final AppPaths paths) async
        {
          final List<KPalRampData> before = _palette.colorRamps;
          await askToApply(tester);

          await tapTooltip(tester, testL10n.yes);

          final DrawingLayerState layer = GetIt.I.get<DocumentState>().timeline.getCurrentLayer()! as DrawingLayerState;
          expect(_palette.colorRamps, isNot(same(before)));
          expect(_palette.colorRamps, contains(layer.getDataEntry(coord: _pixel)!.ramp));
          expect(find.text(testL10n.remapExistingColors), findsNothing);
          expect(dismissed.value, 1);
        });
      });

      testWidgets("drops the pixels on no", (final WidgetTester tester) async
      {
        await _withManager(tester, (final ValueNotifier<int> dismissed, final AppPaths paths) async
        {
          await askToApply(tester);

          await tapTooltip(tester, testL10n.no);

          final DrawingLayerState layer = GetIt.I.get<DocumentState>().timeline.getCurrentLayer()! as DrawingLayerState;
          expect(layer.getDataEntry(coord: _pixel), isNull);
          expect(dismissed.value, 1);
        });
      });

      testWidgets("changes nothing on cancel", (final WidgetTester tester) async
      {
        await _withManager(tester, (final ValueNotifier<int> dismissed, final AppPaths paths) async
        {
          final List<KPalRampData> before = _palette.colorRamps;
          await askToApply(tester);

          await tapTooltip(tester, testL10n.cancel);

          expect(_palette.colorRamps, same(before));
          expect(find.text(testL10n.remapExistingColors), findsNothing);
          expect(dismissed.value, 0);
        });
      });
    });

    testWidgets("appends the palette", (final WidgetTester tester) async
    {
      await _withManager(tester, (final ValueNotifier<int> dismissed, final AppPaths paths) async
      {
        final int count = _palette.colorRamps.length;
        await _selectEntry(tester);

        await tapTooltip(tester, testL10n.appendToCurrentPalette);

        expect(_palette.colorRamps.length, greaterThan(count));
        expect(dismissed.value, 1);
      });
    });

    testWidgets("says so when appending would be too many ramps", (final WidgetTester tester) async
    {
      await _withManager(tester, (final ValueNotifier<int> dismissed, final AppPaths paths) async
      {
        _palette.colorRamps = <KPalRampData>[
          for (int i = 0; i < KPalConstraints.rampCountLimits.max; i++) KPalRampData(uuid: "ramp $i", settings: KPalRampSettings()),
        ];
        await _selectEntry(tester);

        await tapTooltip(tester, testL10n.appendToCurrentPalette);
        await tester.pump(const Duration(milliseconds: 300));

        expect(_palette.colorRamps, hasLength(KPalConstraints.rampCountLimits.max));
        expect(find.text(testL10n.notMoreThanColorRampsAllowed(count: KPalConstraints.rampCountLimits.max)), findsOneWidget);
      });
    });

    group("saving the current palette", ()
    {
      testWidgets("adds it to the list and the directory", (final WidgetTester tester) async
      {
        await _withManager(tester, (final ValueNotifier<int> dismissed, final AppPaths paths) async
        {
          final int count = find.byType(PaletteManagerEntryWidget, skipOffstage: false).evaluate().length;

          await _savePalette(tester, name: "mine");

          expect(await tester.runAsync(() => File(p.join(paths.internalDir, palettesSubDirName, "mine.$fileExtensionKpal")).exists()), isTrue);
          expect(find.byType(SavePaletteWidget), findsNothing);
          expect(find.byType(PaletteManagerEntryWidget, skipOffstage: false).evaluate().length, greaterThanOrEqualTo(count));
        });
      });

      testWidgets("can be called off", (final WidgetTester tester) async
      {
        await _withManager(tester, (final ValueNotifier<int> dismissed, final AppPaths paths) async
        {
          await tapTooltip(tester, testL10n.saveCurrentPalette);
          expect(find.byType(SavePaletteWidget), findsOneWidget);

          await tester.tap(find.descendant(of: find.byType(SavePaletteWidget), matching: find.byTooltip(testL10n.close)));
          await settleUi(tester);

          expect(find.byType(SavePaletteWidget), findsNothing);
          expect(dismissed.value, 0);
        });
      });
    });

    group("deleting a palette", ()
    {
      testWidgets("is not offered for what comes with the app", (final WidgetTester tester) async
      {
        await _withManager(tester, (final ValueNotifier<int> dismissed, final AppPaths paths) async
        {
          await _selectEntry(tester);

          expect(_button(tester, testL10n.deleteSelectedPalette).onPressed, isNull);
        });
      });

      testWidgets("asks first, and removes the file on yes", (final WidgetTester tester) async
      {
        await _withManager(tester, (final ValueNotifier<int> dismissed, final AppPaths paths) async
        {
          await _savePalette(tester, name: "mine");
          final File file = File(p.join(paths.internalDir, palettesSubDirName, "mine.$fileExtensionKpal"));
          final Finder entry = find.byWidgetPredicate((final Widget w) => w is PaletteManagerEntryWidget && (w.entryData.path ?? "").endsWith("mine.$fileExtensionKpal"), skipOffstage: false);
          await tester.ensureVisible(entry);
          await tester.pump();
          await tester.tap(entry);
          await settleUi(tester);

          await tapTooltip(tester, testL10n.deleteSelectedPalette);
          expect(find.text(testL10n.wantToDeletePalette), findsOneWidget);
          await tapTooltip(tester, testL10n.no);
          expect(await tester.runAsync(file.exists), isTrue, reason: "no keeps it");

          await tapTooltip(tester, testL10n.deleteSelectedPalette);
          await tapTooltip(tester, testL10n.yes);
          for (int i = 0; i < 10; i++)
          {
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
            await tester.pump(const Duration(milliseconds: 100));
          }

          expect(await tester.runAsync(file.exists), isFalse);
          expect(entry, findsNothing);
        });
      });
    });
  });
}
