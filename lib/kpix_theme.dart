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

/// Notifier for theme change.
class ThemeNotifier extends ChangeNotifier
{
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode
  {
    return _themeMode;
  }

  set themeMode(final ThemeMode theme)
  {
    _themeMode = theme;
    notifyListeners();
  }
}

/// Currently used theme (system/light/dark).
final ThemeNotifier themeSettings = ThemeNotifier();

/// Base colors of a theme, exposed to widgets as [ThemeData.primaryColor],
/// [ThemeData.primaryColorLight] and [ThemeData.primaryColorDark].
class ColorSet
{
  final Brightness brightness;
  final Color normal;
  final Color light;
  final Color dark;

  const ColorSet({
    required this.brightness,
    required this.normal,
    required this.light,
    required this.dark,
  });

  bool get isDark => brightness == Brightness.dark;
}

const Color notificationGreen = Color.fromARGB(200, 50, 200, 50);

final ColorSet _lightColors = ColorSet(brightness: Brightness.light, normal: Colors.grey[350]!, light: Colors.grey[600]!, dark: Colors.grey[100]!);
final ColorSet _darkColors = ColorSet(brightness: Brightness.dark, normal: Colors.grey[800]!, light: Colors.grey[400]!, dark: Colors.grey[900]!);

const String _fontFamily = "Oxanium";
const BorderRadius _borderRadius = BorderRadius.all(Radius.circular(8));
const int _buttonOverlayAlpha = 32;
const int _controlOverlayAlpha = 100;
const double _elevation = 16.0;

final ThemeData monochromeTheme = _buildTheme(colors: _lightColors);
final ThemeData monochromeThemeDark = _buildTheme(colors: _darkColors);

TextStyle _textStyle({required final double size, required final double height, required final double spacing, required final FontWeight weight, required final Color color})
{
  return TextStyle(fontSize: size, height: height, letterSpacing: spacing, fontWeight: weight, color: color, fontFamily: _fontFamily);
}

TextTheme _buildTextTheme({required final Color color})
{
  TextStyle style(final double size, final double height, final double spacing, final FontWeight weight)
  {
    return _textStyle(size: size, height: height, spacing: spacing, weight: weight, color: color);
  }

  return TextTheme(
    displayLarge: style(57, 1.2, 0.0, FontWeight.w400),
    displayMedium: style(45, 1.2, 0.0, FontWeight.w400),
    displaySmall: style(36, 1.2, 0.0, FontWeight.w400),

    headlineLarge: style(32, 1.2, 0.0, FontWeight.w400),
    headlineMedium: style(28, 1.4, 0.0, FontWeight.w400),
    headlineSmall: style(24, 1.4, 0.0, FontWeight.w400),

    titleLarge: style(22, 1.4, 0.0, FontWeight.w600),
    titleMedium: style(16, 1.4, 0.15, FontWeight.w600),
    titleSmall: style(14, 1.4, 0.1, FontWeight.w600),

    labelLarge: style(14, 1.4, 0.1, FontWeight.w600),
    labelMedium: style(12, 1.4, 0.5, FontWeight.w600),
    labelSmall: style(11, 1.4, 0.5, FontWeight.w600),

    bodyLarge: style(14, 1.5, 0.15, FontWeight.w400),
    bodyMedium: style(12, 1.5, 0.25, FontWeight.w600),
    bodySmall: style(10, 1.5, 0.4, FontWeight.w600),
  );
}

WidgetStateProperty<T> _whenDisabled<T>({required final T disabled, required final T enabled})
{
  return WidgetStateProperty.resolveWith((final Set<WidgetState> states) => states.contains(WidgetState.disabled) ? disabled : enabled);
}

WidgetStateProperty<T> _whenSelected<T>({required final T selected, required final T unselected})
{
  return WidgetStateProperty.resolveWith((final Set<WidgetState> states) => states.contains(WidgetState.selected) ? selected : unselected);
}

ThemeData _buildTheme({required final ColorSet colors})
{
  final bool isDark = colors.isDark;

  final ButtonStyle generalButtonStyle = ButtonStyle(
    foregroundColor: _whenDisabled(disabled: colors.normal, enabled: colors.light),
    backgroundColor: _whenDisabled(disabled: colors.dark, enabled: colors.normal),
    overlayColor: WidgetStatePropertyAll<Color>(colors.light.withAlpha(_buttonOverlayAlpha)),
    surfaceTintColor: WidgetStatePropertyAll<Color>(colors.light),
    padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    side: _whenDisabled(disabled: BorderSide(color: colors.normal), enabled: BorderSide(color: colors.light)),
    shape: const WidgetStatePropertyAll<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: _borderRadius)),
  );

  // The light theme shows tooltips inverted.
  final Color tooltipBackground = isDark ? colors.dark : colors.light;
  final Color tooltipText = isDark ? colors.light : colors.dark;

  return ThemeData(
    primaryColor: colors.normal,
    primaryColorLight: colors.light,
    primaryColorDark: colors.dark,

    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.grey,
      brightness: colors.brightness,
    ),

    textTheme: _buildTextTheme(color: colors.light),

    tooltipTheme: TooltipThemeData(
      padding: const EdgeInsetsGeometry.all(6),
      waitDuration: const Duration(milliseconds: 750),
      showDuration: const Duration(seconds: 5),
      decoration: BoxDecoration(
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: tooltipBackground,
            blurRadius: 8,
          ),
        ],
        color: tooltipBackground,
        borderRadius: _borderRadius,
        border: BoxBorder.all(
          width: 2.0,
          color: colors.normal,
        ),
      ),
      textStyle: _textStyle(size: 12, height: 1.4, spacing: 0.7, weight: FontWeight.w900, color: tooltipText),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: colors.light,
      inactiveTrackColor: colors.dark,
      thumbColor: colors.light,
      valueIndicatorColor: colors.light,
      valueIndicatorStrokeColor: colors.normal,
      overlayColor: (isDark ? colors.light : colors.dark).withAlpha(_controlOverlayAlpha),
      valueIndicatorTextStyle: TextStyle(
        color: isDark ? colors.normal : colors.dark,
      ),
      showValueIndicator: ShowValueIndicator.onDrag,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((final Set<WidgetState> states) => states.contains(WidgetState.selected) && !states.contains(WidgetState.disabled) ? colors.light : colors.normal),
      trackColor: WidgetStateProperty.resolveWith((final Set<WidgetState> states) => states.contains(WidgetState.selected) && !states.contains(WidgetState.disabled) ? colors.normal : colors.dark),
      trackOutlineColor: _whenDisabled(disabled: colors.normal, enabled: colors.light),
      overlayColor: WidgetStatePropertyAll<Color>((isDark ? colors.light : colors.normal).withAlpha(_controlOverlayAlpha)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colors.light),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colors.light),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(style: generalButtonStyle),
    filledButtonTheme: FilledButtonThemeData(style: generalButtonStyle),
    iconButtonTheme: IconButtonThemeData(style: generalButtonStyle),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: const WidgetStatePropertyAll<double>(_elevation),
        shadowColor: WidgetStatePropertyAll<Color>(colors.dark),
        foregroundColor: WidgetStatePropertyAll<Color>(colors.light),
        backgroundColor: WidgetStatePropertyAll<Color>(colors.dark),
        overlayColor: WidgetStatePropertyAll<Color>(isDark ? colors.normal : colors.dark),
        surfaceTintColor: WidgetStatePropertyAll<Color>(colors.light),
        side: WidgetStatePropertyAll<BorderSide>(BorderSide(color: colors.light)),
      ),
    ),

    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: _whenSelected(selected: colors.normal, unselected: colors.light),
        backgroundColor: _whenSelected(selected: colors.light, unselected: colors.normal),
        iconColor: _whenSelected(selected: colors.normal, unselected: colors.light),
        padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(horizontal: 2.0)),
        shape: const WidgetStatePropertyAll<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: _borderRadius)),
        side: WidgetStatePropertyAll<BorderSide>(BorderSide(color: colors.light)),
      ),
    ),

    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.light,
    ),

    radioTheme: RadioThemeData(
      backgroundColor: WidgetStatePropertyAll<Color>(colors.normal),
      fillColor: WidgetStatePropertyAll<Color>(colors.light),
    ),
  );
}
