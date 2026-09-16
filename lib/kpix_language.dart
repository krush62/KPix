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
import 'package:kpix/l10n/app_localizations.dart';

/// The stored value for "follow the system language".
///
/// An empty code rather than null, so it can be held in a preference and
/// selected in a dropdown like any other language.
const String systemLanguageCode = "";

/// Notifier for language change.
class LanguageNotifier extends ChangeNotifier
{
  String _languageCode = systemLanguageCode;

  /// The chosen language, empty while the system language is followed.
  String get languageCode
  {
    return _languageCode;
  }

  set languageCode(final String code)
  {
    _languageCode = isSupportedLanguage(languageCode: code) ? code : systemLanguageCode;
    notifyListeners();
  }

  /// The locale for the app, null while the system language is followed.
  Locale? get locale
  {
    return _languageCode == systemLanguageCode ? null : Locale(_languageCode);
  }

  /// The translations for the chosen language.
  ///
  /// Reads the choice directly instead of going through a [BuildContext], so it
  /// is also correct before the app has rebuilt for a language that was just
  /// picked. [fallback] is used while the system language is followed.
  AppLocalizations resolve({required final AppLocalizations fallback})
  {
    final Locale? chosen = locale;
    return chosen == null ? fallback : lookupAppLocalizations(chosen);
  }
}

/// Currently used language (system or one of the supported ones).
final LanguageNotifier languageSettings = LanguageNotifier();

/// Whether [languageCode] is one of the languages the app was translated into.
bool isSupportedLanguage({required final String languageCode})
{
  return AppLocalizations.supportedLocales.any((final Locale locale) => locale.languageCode == languageCode);
}

/// Every language name in its own language.
///
/// Names are not translated, so a language can still be found after the wrong
/// one was picked.
const Map<String, String> _languageNames = <String, String>{
  "de": "Deutsch",
  "en": "English",
};

/// The languages to choose from, the system option first.
Map<String, String> getLanguageLabelMap({required final AppLocalizations l10n})
{
  final Map<String, String> labelMap = <String, String>{systemLanguageCode: l10n.languageSystem};
  for (final Locale locale in AppLocalizations.supportedLocales)
  {
    labelMap[locale.languageCode] = _languageNames[locale.languageCode] ?? locale.languageCode.toUpperCase();
  }
  return labelMap;
}
