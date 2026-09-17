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
import 'package:kpix/kpix_language.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/widgets/controls/kpix_dropdown.dart';
import 'package:kpix/widgets/preferences/preference_gui.dart';

/// Wraps [home] in an app carrying the localizations, in [locale] when given.
Widget _app({required final Widget home, final Locale? locale})
{
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(body: home),
  );
}

Widget _languageRow({required final ValueNotifier<String> notifier})
{
  return Builder(
    builder: (final BuildContext context)
    {
      final AppLocalizations l10n = AppLocalizations.of(context)!;
      return PrefDropdownRow<String>(
        label: l10n.language,
        notifier: notifier,
        valueMap: getLanguageLabelMap(l10n: l10n),
      );
    },
  );
}

void main()
{
  test("the system option comes first and every supported language follows", ()
  {
    final AppLocalizations l10n = lookupAppLocalizations(const Locale("en"));
    final Map<String, String> labels = getLanguageLabelMap(l10n: l10n);

    expect(labels.keys.first, systemLanguageCode);
    expect(labels.length, AppLocalizations.supportedLocales.length + 1);
    for (final Locale locale in AppLocalizations.supportedLocales)
    {
      expect(labels.containsKey(locale.languageCode), isTrue, reason: locale.languageCode);
    }
  });

  test("every language is named in its own language", ()
  {
    final Map<String, String> labels = getLanguageLabelMap(l10n: lookupAppLocalizations(const Locale("de")));

    expect(labels["en"], "English");
    expect(labels["de"], "Deutsch");
    //only the system entry follows the current language
    expect(labels[systemLanguageCode], lookupAppLocalizations(const Locale("de")).languageSystem);
  });

  test("an unsupported code falls back to the system language", ()
  {
    final LanguageNotifier notifier = LanguageNotifier();

    notifier.languageCode = "fr";
    expect(notifier.languageCode, systemLanguageCode);
    expect(notifier.locale, isNull);

    notifier.languageCode = "de";
    expect(notifier.locale, const Locale("de"));
  });

  test("the translations are resolved from the choice, not from the app", ()
  {
    final LanguageNotifier notifier = LanguageNotifier();
    final AppLocalizations english = lookupAppLocalizations(const Locale("en"));

    expect(notifier.resolve(fallback: english).language, "Language");
    notifier.languageCode = "de";
    expect(notifier.resolve(fallback: english).language, "Sprache");
  });

  testWidgets("the dropdown opens and hands the picked language to the notifier", (final WidgetTester tester) async {
    final ValueNotifier<String> language = ValueNotifier<String>(systemLanguageCode);
    await tester.pumpWidget(_app(home: _languageRow(notifier: language), locale: const Locale("en")));

    expect(find.text("Language"), findsOneWidget);
    //the closed button shows the current choice
    expect(find.text("System"), findsOneWidget);

    await tester.tap(find.byType(KPixDropdown<String>));
    await tester.pumpAndSettle();

    expect(find.text("Deutsch"), findsWidgets);
    expect(find.text("English"), findsWidgets);

    await tester.tap(find.text("Deutsch").last);
    await tester.pumpAndSettle();

    expect(language.value, "de");
    expect(find.text("Deutsch"), findsOneWidget);
  });

  testWidgets("the row is translated along with the app", (final WidgetTester tester) async {
    final ValueNotifier<String> language = ValueNotifier<String>(systemLanguageCode);
    await tester.pumpWidget(_app(home: _languageRow(notifier: language), locale: const Locale("de")));

    expect(find.text("Sprache"), findsOneWidget);
  });
}
