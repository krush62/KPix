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
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/app_directories.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/palette/palette_manager_entry_widget.dart';
import 'package:kpix/widgets/palette/palette_manager_widget.dart';
import 'package:path/path.dart' as p;
import 'package:toastification/toastification.dart';

import 'support/project_files.dart';
import 'support/selection_harness.dart';

AppLocalizations _l10n(final WidgetTester tester) => AppLocalizations.of(tester.element(find.byType(PaletteManagerWidget)))!;

/// The names of all palettes in the list, including the ones scrolled out of view.
List<String> _listed(final WidgetTester tester)
{
  final GridView grid = tester.widget<GridView>(find.byType(GridView));
  final SliverChildListDelegate delegate = grid.childrenDelegate as SliverChildListDelegate;
  return delegate.children.map((final Widget entry) => (entry as PaletteManagerEntryWidget).entryData.displayName(l10n: _l10n(tester))).toList();
}

/// Pumps until [condition] holds. The palettes are read from disk, which only
/// makes progress while the real event loop gets to run.
Future<void> _pumpUntil(final WidgetTester tester, {required final bool Function() condition, required final String what}) async
{
  for (int i = 0; i < 500; i++)
  {
    if (condition())
    {
      return;
    }
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 20));
  }
  fail("Timed out waiting for $what.");
}

/// Boots a project and opens the manager, with the bundled palettes listed.
Future<void> _pumpManager(final WidgetTester tester) async
{
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final AppPaths paths = createTestPaths();
  await tester.runAsync(() async {
    await bootProject(canvasSize: CoordinateSetI(x: 4, y: 4), appPaths: paths);
    await createInternalDirectories();
  });
  await tester.pumpWidget(ToastificationWrapper(child: MaterialApp(
    theme: monochromeTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: PaletteManagerWidget(dismiss: () {}))),
  ),),);
  await _pumpUntil(tester, condition: () => _listed(tester).length > 1, what: "the palettes to be listed");
  //the dialog is not hit testable while it scales in
  await tester.pump(const Duration(milliseconds: 200));
}

/// Lets the toast expire and releases the layers of the project, whose raster
/// timer would otherwise still be pending when the test ends.
Future<void> _close(final WidgetTester tester) async
{
  await tester.pump(const Duration(seconds: 5));
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpWidget(const SizedBox.shrink());
  for (final Frame frame in GetIt.I.get<DocumentState>().timeline.frames.value)
  {
    for (int i = 0; i < frame.layerList.length; i++)
    {
      frame.layerList.getLayer(index: i).dispose();
    }
  }
  await tester.pump();
}

Future<Uint8List> _validPalette() async
{
  return createPaletteKPalData(rampList: <KPalRampData>[KPalRampData(uuid: "ramp", settings: KPalRampSettings())]);
}

void main()
{
  testWidgets("a good file is announced and shows up in the list", (final WidgetTester tester) async
  {
    await _pumpManager(tester);
    final File source = File(p.join(GetIt.I.get<AppPaths>().exportDir, "picked.$fileExtensionKpal"))..writeAsBytesSync((await tester.runAsync(_validPalette))!);
    installFakeFilePicker(file: FakePickedFile(source));

    await tester.tap(find.byTooltip(_l10n(tester).importPalette));
    await _pumpUntil(tester, condition: () => _listed(tester).contains("picked"), what: "the palette to be listed");

    expect(find.text(_l10n(tester).paletteImportSuccessful), findsOneWidget);
    await _close(tester);
  });

  testWidgets("a damaged file reports the failure and stays out of the list", (final WidgetTester tester) async
  {
    await _pumpManager(tester);
    final File source = File(p.join(GetIt.I.get<AppPaths>().exportDir, "broken.$fileExtensionKpal"))..writeAsBytesSync(<int>[2, 1, 0]);
    installFakeFilePicker(file: FakePickedFile(source));
    final List<String> before = _listed(tester);

    await tester.tap(find.byTooltip(_l10n(tester).importPalette));
    await _pumpUntil(tester, condition: () => find.text(_l10n(tester).paletteImportFailed).evaluate().isNotEmpty, what: "the failure message");

    expect(find.text(_l10n(tester).paletteImportSuccessful), findsNothing);
    expect(_listed(tester), before);
    await _close(tester);
  });

  testWidgets("a name that is taken says so", (final WidgetTester tester) async
  {
    await _pumpManager(tester);
    final List<int> bytes = (await tester.runAsync(_validPalette))!;
    final File source = File(p.join(GetIt.I.get<AppPaths>().exportDir, "taken.$fileExtensionKpal"))..writeAsBytesSync(bytes);
    File(p.join(GetIt.I.get<AppPaths>().internalDir, palettesSubDirName, "taken.$fileExtensionKpal")).writeAsBytesSync(bytes);
    installFakeFilePicker(file: FakePickedFile(source));

    await tester.tap(find.byTooltip(_l10n(tester).importPalette));
    await _pumpUntil(tester, condition: () => find.text(_l10n(tester).paletteWithSameNameExists).evaluate().isNotEmpty, what: "the message");

    await _close(tester);
  });

  testWidgets("another file type asks for a palette file", (final WidgetTester tester) async
  {
    await _pumpManager(tester);
    final File source = File(p.join(GetIt.I.get<AppPaths>().exportDir, "picture.png"))..writeAsBytesSync(<int>[1]);
    installFakeFilePicker(file: FakePickedFile(source));

    await tester.tap(find.byTooltip(_l10n(tester).importPalette));
    await _pumpUntil(tester, condition: () => find.text(_l10n(tester).pleaseSelectAKPalFile).evaluate().isNotEmpty, what: "the message");

    await _close(tester);
  });

  testWidgets("cancelling the dialog reports nothing", (final WidgetTester tester) async
  {
    await _pumpManager(tester);
    final FakeFilePicker picker = installFakeFilePicker(file: null);
    final List<String> before = _listed(tester);

    await tester.tap(find.byTooltip(_l10n(tester).importPalette));
    await _pumpUntil(tester, condition: () => picker.pickCount == 1, what: "the dialog");
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    for (final String message in <String>[_l10n(tester).paletteImportSuccessful, _l10n(tester).paletteImportFailed, _l10n(tester).paletteWithSameNameExists, _l10n(tester).pleaseSelectAKPalFile])
    {
      expect(find.text(message), findsNothing);
    }
    expect(_listed(tester), before);
    await _close(tester);
  });
}
