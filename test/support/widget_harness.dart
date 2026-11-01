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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/stylus_bridge.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/managers/stamp_manager.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:toastification/toastification.dart';

import 'selection_harness.dart';

final AppLocalizations testL10n = lookupAppLocalizations(const Locale("en"));

/// Lets overlays, animations and toasts arrive, with real time for images and files.
Future<void> settleUi(final WidgetTester tester) async
{
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 100));
}

/// Boots a project, shows the widget from [child] in the app's theme and language
/// and tears everything down again after [body].
///
/// The test font is wider than the real one and some dialogs have a fixed size,
/// which [textScale] makes up for.
void projectWidgetTest(
  final String description,
  final Widget Function() child,
  final Future<void> Function(WidgetTester tester) body, {
  final Size window = const Size(1400, 900),
  final CoordinateSetI? canvasSize,
  final double textScale = 0.7,
  final AppPaths? appPaths,
  final bool skip = false,
})
{
  testWidgets(description, (final WidgetTester tester) async
  {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async
    {
      await bootProject(canvasSize: canvasSize ?? CoordinateSetI(x: 8, y: 8), appPaths: appPaths);
      GetIt.I.registerSingleton<StampManager>(StampManager());
      GetIt.I.registerSingleton<StylusBridge>(StylusBridge());
    });
    await tester.pumpWidget(testApp(child: child(), textScale: textScale));
    await settleUi(tester);

    await body(tester);

    await closeTestApp(tester);
  }, skip: skip,);
}

/// The app around [child], with the theme, the language and the toasts.
Widget testApp({required final Widget child, final double textScale = 0.7})
{
  return ToastificationWrapper(child: MaterialApp(
    theme: monochromeTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale("en"),
    builder: (final BuildContext context, final Widget? app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: app!,
    ),
    home: Material(child: child),
  ),);
}

/// Ends what [testApp] started: the toasts, the widgets and the layers of the project.
Future<void> closeTestApp(final WidgetTester tester) async
{
  toastification.dismissAll(delayForAnimation: false);
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpWidget(const SizedBox.shrink());
  for (final Frame frame in GetIt.I.get<DocumentState>().timeline.frames.value)
  {
    for (int i = 0; i < frame.layerList.length; i++)
    {
      frame.layerList.getLayer(index: i).dispose();
    }
  }
  await tester.pump(const Duration(seconds: 10));
}

/// Finds a tooltip by how it starts, for those with a shortcut behind the label.
Finder findTooltipStarting(final String start)
{
  return find.byWidgetPredicate((final Widget w) => w is Tooltip && (w.message ?? "").startsWith(start));
}

/// Taps the control with the tooltip [tooltip] and waits for what follows.
Future<void> tapTooltip(final WidgetTester tester, final String tooltip) async
{
  await tester.tap(find.byTooltip(tooltip).first);
  await settleUi(tester);
}
