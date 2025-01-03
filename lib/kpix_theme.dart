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
import 'package:google_fonts/google_fonts.dart';

class ColorSet
{
  final Color normal;
  final Color light;
  final Color dark;
  final int alphaB;
  final double elevation;

  const ColorSet({
    required this.normal,
    required this.light,
    required this.dark,
    this.alphaB = 100,
    this.elevation = 16.0,
  });
}


  const Color notificationGreen = Color.fromARGB(200, 50, 200, 50);
  ColorSet _lightColors = ColorSet(normal: Colors.grey[400]!, light: Colors.grey[700]!, dark: Colors.grey[350]!);
  ThemeData monochromeTheme = ThemeData(

    primaryColor: _lightColors.normal,
    primaryColorLight: _lightColors.light,
    primaryColorDark: _lightColors.dark,

    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.grey,
    ),
    textTheme: GoogleFonts.oxaniumTextTheme( TextTheme(

      displayLarge: TextStyle(fontSize: 57, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: _lightColors.light),
      displayMedium: TextStyle(fontSize: 45, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: _lightColors.light),
      displaySmall: TextStyle(fontSize: 36, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: _lightColors.light),

      headlineLarge: TextStyle(fontSize: 32, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: _lightColors.light),
      headlineMedium: TextStyle(fontSize: 28, height: 1.4, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: _lightColors.light),
      headlineSmall: TextStyle(fontSize: 24, height: 1.4, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: _lightColors.light),

      titleLarge: TextStyle(fontSize: 22, height: 1.4, letterSpacing: 0.0, fontWeight: FontWeight.w600, color: _lightColors.light),
      titleMedium: TextStyle(fontSize: 16, height: 1.4, letterSpacing: 0.15, fontWeight: FontWeight.w600, color: _lightColors.light),
      titleSmall: TextStyle(fontSize: 14, height: 1.4, letterSpacing: 0.1, fontWeight: FontWeight.w600, color: _lightColors.light),

      labelLarge: TextStyle(fontSize: 14, height: 1.4, letterSpacing: 0.1, fontWeight: FontWeight.w600, color: _lightColors.light),
      labelMedium: TextStyle(fontSize: 12, height: 1.4, letterSpacing: 0.5, fontWeight: FontWeight.w600, color: _lightColors.light),
      labelSmall: TextStyle(fontSize: 11, height: 1.4, letterSpacing: 0.5, fontWeight: FontWeight.w600, color: _lightColors.light),

      bodyLarge: TextStyle(fontSize: 14, height: 1.5, letterSpacing: 0.15, fontWeight: FontWeight.w400, color: _lightColors.light),
      bodyMedium: TextStyle(fontSize: 12, height: 1.5, letterSpacing: 0.25, fontWeight: FontWeight.w600, color: _lightColors.light),
      bodySmall: TextStyle(fontSize: 10, height: 1.5, letterSpacing: 0.4, fontWeight: FontWeight.w600, color: _lightColors.light),
    ),),

    sliderTheme: SliderThemeData(
      activeTrackColor: _lightColors.light,
      inactiveTrackColor: _lightColors.dark,
      thumbColor: _lightColors.light,
      valueIndicatorColor: _lightColors.light,
      valueIndicatorStrokeColor: _lightColors.normal,
      overlayColor: _lightColors.dark.withAlpha(_lightColors.alphaB),
      valueIndicatorTextStyle: TextStyle(
          color: _lightColors.dark,
      ),
      showValueIndicator: ShowValueIndicator.always,

    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((final Set<WidgetState> states) => states.contains(WidgetState.selected) ? (states.contains(WidgetState.disabled) ? _lightColors.normal : _lightColors.light) : _lightColors.normal),
      trackColor: WidgetStateProperty.resolveWith((final Set<WidgetState> states) => states.contains(WidgetState.selected) ? (states.contains(WidgetState.disabled) ? _lightColors.dark :_lightColors.normal) : _lightColors.dark),
      trackOutlineColor: WidgetStateProperty.resolveWith((final Set<WidgetState> states) => states.contains(WidgetState.disabled) ? _lightColors.normal : _lightColors.light),
      overlayColor: WidgetStateProperty.all(_lightColors.normal.withAlpha(_lightColors.alphaB)),

    ),
    inputDecorationTheme: InputDecorationTheme(
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
                color: _lightColors.light,
            ),
        ),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
                color: _lightColors.light,
            ),
        ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((final Set<WidgetState> states) => states.contains(WidgetState.hovered) ? darkColors.light : darkColors.normal),
          backgroundColor: WidgetStateProperty.all(_lightColors.normal),
          overlayColor: WidgetStateProperty.all(_lightColors.light),
          surfaceTintColor: WidgetStateProperty.all(_lightColors.normal),
          side: WidgetStateProperty.all(
              BorderSide(
                  color: _lightColors.light,
              ),
          ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(_lightColors.light),
        overlayColor: WidgetStateProperty.all(_lightColors.light),
        surfaceTintColor: WidgetStateProperty.all(_lightColors.light),
        shape: WidgetStateProperty.all(
          const RoundedRectangleBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: WidgetStateProperty.all(_lightColors.elevation),
        shadowColor: WidgetStateProperty.all(_lightColors.dark),
        foregroundColor: WidgetStateProperty.all(_lightColors.light),
        backgroundColor: WidgetStateProperty.all(_lightColors.dark),
        overlayColor: WidgetStateProperty.all(_lightColors.dark),
        surfaceTintColor: WidgetStateProperty.all(_lightColors.light),
        side: WidgetStateProperty.all(
          BorderSide(
            color: _lightColors.light,
          ),
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((final Set<WidgetState> states) => states.contains(WidgetState.selected) ? _lightColors.normal : _lightColors.light),
          backgroundColor: WidgetStateProperty.resolveWith((final Set<WidgetState> states) => states.contains(WidgetState.selected) ? _lightColors.light : _lightColors.normal),
          padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.only(left: 2.0, right: 2.0)),
        ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: _lightColors.light,
    ),

  );




  ColorSet darkColors = ColorSet(normal: Colors.grey[800]!, light: Colors.grey[400]!, dark: Colors.grey[900]!);
  ThemeData monochromeThemeDark = ThemeData(

    primaryColor: darkColors.normal,
    primaryColorLight: darkColors.light,
    primaryColorDark: darkColors.dark,


    colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.grey,
        brightness: Brightness.dark,
    ),

    //fontFamily: "PixelFonts",

    textTheme: GoogleFonts.oxaniumTextTheme(
      TextTheme(
        displayLarge: monochromeTheme.textTheme.displayLarge!.copyWith(color: darkColors.light),
        displayMedium: monochromeTheme.textTheme.displayMedium!.copyWith(color: darkColors.light),
        displaySmall: monochromeTheme.textTheme.displaySmall!.copyWith(color: darkColors.light),

        headlineLarge: monochromeTheme.textTheme.headlineLarge!.copyWith(color: darkColors.light),
        headlineMedium: monochromeTheme.textTheme.headlineMedium!.copyWith(color: darkColors.light),
        headlineSmall: monochromeTheme.textTheme.headlineSmall!.copyWith(color: darkColors.light),

        titleLarge: monochromeTheme.textTheme.titleLarge!.copyWith(color: darkColors.light),
        titleMedium: monochromeTheme.textTheme.titleMedium!.copyWith(color: darkColors.light),
        titleSmall: monochromeTheme.textTheme.titleSmall!.copyWith(color: darkColors.light),

        labelLarge: monochromeTheme.textTheme.labelLarge!.copyWith(color: darkColors.light),
        labelMedium: monochromeTheme.textTheme.labelMedium!.copyWith(color: darkColors.light),
        labelSmall: monochromeTheme.textTheme.labelSmall!.copyWith(color: darkColors.light),

        bodyLarge: monochromeTheme.textTheme.bodyLarge!.copyWith(color: darkColors.light),
        bodyMedium: monochromeTheme.textTheme.bodyMedium!.copyWith(color: darkColors.light),
        bodySmall: monochromeTheme.textTheme.bodySmall!.copyWith(color: darkColors.light),
      ),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: darkColors.light,
      inactiveTrackColor: darkColors.dark,
      thumbColor: darkColors.light,
      valueIndicatorColor: darkColors.light,
      valueIndicatorStrokeColor: darkColors.normal,
      overlayColor: darkColors.light.withAlpha(darkColors.alphaB),
      valueIndicatorTextStyle: TextStyle(
        color: darkColors.normal,
      ),
      showValueIndicator: ShowValueIndicator.always,

    ),

    switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((final Set<WidgetState> states) => states.contains(WidgetState.selected) ? (states.contains(WidgetState.disabled) ? darkColors.normal : darkColors.light) : darkColors.normal),
        trackColor: WidgetStateProperty.resolveWith((final Set<WidgetState> states) => states.contains(WidgetState.selected) ? (states.contains(WidgetState.disabled) ? darkColors.dark : darkColors.normal) : darkColors.dark),
        trackOutlineColor: WidgetStateProperty.resolveWith((final Set<WidgetState> states) => states.contains(WidgetState.disabled) ? darkColors.normal : darkColors.light),
        overlayColor: WidgetStateProperty.all(darkColors.light.withAlpha(darkColors.alphaB)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
              color: darkColors.light,
          ),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: darkColors.light,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((final Set<WidgetState> states) => states.contains(WidgetState.hovered) ? darkColors.normal : darkColors.light),
          backgroundColor: WidgetStateProperty.all(darkColors.normal),
          overlayColor: WidgetStateProperty.all(darkColors.light),
          surfaceTintColor: WidgetStateProperty.all(darkColors.light),
          side: WidgetStateProperty.all(BorderSide(
              color: darkColors.light,
          ),
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(darkColors.light),
        overlayColor: WidgetStateProperty.all(darkColors.light),
        surfaceTintColor: WidgetStateProperty.all(darkColors.light),
        shape: WidgetStateProperty.all(
          const RoundedRectangleBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: WidgetStateProperty.all(darkColors.elevation),
        shadowColor: WidgetStateProperty.all(darkColors.dark),
        foregroundColor: WidgetStateProperty.all(darkColors.light),
        backgroundColor: WidgetStateProperty.all(darkColors.dark),
        overlayColor: WidgetStateProperty.all(darkColors.normal),
        surfaceTintColor: WidgetStateProperty.all(darkColors.light),
          side: WidgetStateProperty.all(BorderSide(
              color: darkColors.light,
          ),
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((final Set<WidgetState> states) => states.contains(WidgetState.selected) ? darkColors.normal : darkColors.light),
          backgroundColor: WidgetStateProperty.resolveWith((final Set<WidgetState> states) => states.contains(WidgetState.selected) ? darkColors.light : darkColors.normal),
          padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.only(left: 2.0, right: 2.0)),
        ),
    ),
      textSelectionTheme: TextSelectionThemeData(
          cursorColor: darkColors.light,
      ),
  );
