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

class KPixTheme
{
  static Color notificationGreen = Color.fromARGB(200, 50, 200, 50);

  static ColorSet lightColors = ColorSet(normal: Colors.grey[400]!, light: Colors.grey[700]!, dark: Colors.grey[350]!);
  static ThemeData monochromeTheme = ThemeData(

    primaryColor: lightColors.normal,
    primaryColorLight: lightColors.light,
    primaryColorDark: lightColors.dark,

    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.grey,
      brightness: Brightness.light,

    ),
    textTheme: GoogleFonts.oxaniumTextTheme( TextTheme(

      displayLarge: TextStyle(fontSize: 57, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: lightColors.light),
      displayMedium: TextStyle(fontSize: 45, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: lightColors.light),
      displaySmall: TextStyle(fontSize: 36, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: lightColors.light),

      headlineLarge: TextStyle(fontSize: 32, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: lightColors.light),
      headlineMedium: TextStyle(fontSize: 28, height: 1.4, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: lightColors.light),
      headlineSmall: TextStyle(fontSize: 24, height: 1.4, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: lightColors.light),

      titleLarge: TextStyle(fontSize: 22, height: 1.4, letterSpacing: 0.0, fontWeight: FontWeight.w600, color: lightColors.light),
      titleMedium: TextStyle(fontSize: 16, height: 1.4, letterSpacing: 0.15, fontWeight: FontWeight.w600, color: lightColors.light),
      titleSmall: TextStyle(fontSize: 14, height: 1.4, letterSpacing: 0.1, fontWeight: FontWeight.w600, color: lightColors.light),

      labelLarge: TextStyle(fontSize: 14, height: 1.4, letterSpacing: 0.1, fontWeight: FontWeight.w600, color: lightColors.light),
      labelMedium: TextStyle(fontSize: 12, height: 1.4, letterSpacing: 0.5, fontWeight: FontWeight.w600, color: lightColors.light),
      labelSmall: TextStyle(fontSize: 11, height: 1.4, letterSpacing: 0.5, fontWeight: FontWeight.w600, color: lightColors.light),

      bodyLarge: TextStyle(fontSize: 14, height: 1.5, letterSpacing: 0.15, fontWeight: FontWeight.w400, color: lightColors.light),
      bodyMedium: TextStyle(fontSize: 12, height: 1.5, letterSpacing: 0.25, fontWeight: FontWeight.w600, color: lightColors.light),
      bodySmall: TextStyle(fontSize: 10, height: 1.5, letterSpacing: 0.4, fontWeight: FontWeight.w600, color: lightColors.light),
    )),

    sliderTheme: SliderThemeData(
      activeTrackColor: lightColors.light,
      inactiveTrackColor: lightColors.dark,
      thumbColor: lightColors.light,
      valueIndicatorColor: lightColors.light,
      valueIndicatorStrokeColor: lightColors.normal,
      overlayColor: lightColors.dark.withAlpha(lightColors.alphaB),
      valueIndicatorTextStyle: TextStyle(
          color: lightColors.dark
      ),
      showValueIndicator: ShowValueIndicator.always,

    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? (states.contains(WidgetState.disabled) ? lightColors.normal : lightColors.light) : lightColors.normal),
      trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? (states.contains(WidgetState.disabled) ? lightColors.dark :lightColors.normal) : lightColors.dark),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.disabled) ? lightColors.normal : lightColors.light),
      overlayColor: WidgetStateProperty.all(lightColors.normal.withAlpha(lightColors.alphaB))

    ),
    inputDecorationTheme: InputDecorationTheme(
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
                color: lightColors.light
            )
        ),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
                color: lightColors.light
            )
        )
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered) ? darkColors.light : darkColors.normal),
          backgroundColor: WidgetStateProperty.all(lightColors.normal),
          overlayColor: WidgetStateProperty.all(lightColors.light),
          surfaceTintColor: WidgetStateProperty.all(lightColors.normal),
          side: WidgetStateProperty.all(
              BorderSide(
                  color: lightColors.light
              )
          )
      )
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: WidgetStateProperty.all(lightColors.elevation),
        shadowColor: WidgetStateProperty.all(lightColors.dark),
        foregroundColor: WidgetStateProperty.all(lightColors.light),
        backgroundColor: WidgetStateProperty.all(lightColors.dark),
        overlayColor: WidgetStateProperty.all(lightColors.dark),
        surfaceTintColor: WidgetStateProperty.all(lightColors.light),
        side: WidgetStateProperty.all(
          BorderSide(
            color: lightColors.light
          )
        )
      )
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? lightColors.normal : lightColors.light),
          backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? lightColors.light : lightColors.normal),
        )
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: lightColors.light
    )

  );




  static ColorSet darkColors = ColorSet(normal: Colors.grey[800]!, light: Colors.grey[400]!, dark: Colors.grey[900]!);
  static ThemeData monochromeThemeDark = ThemeData(

    primaryColor: darkColors.normal,
    primaryColorLight: darkColors.light,
    primaryColorDark: darkColors.dark,


    colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.grey,
        brightness: Brightness.dark
    ),

    //fontFamily: "PixelFonts",

    textTheme: GoogleFonts.oxaniumTextTheme( TextTheme(
      displayLarge: TextStyle(fontSize: 57, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: darkColors.light),
      displayMedium: TextStyle(fontSize: 45, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: darkColors.light),
      displaySmall: TextStyle(fontSize: 36, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: darkColors.light),

      headlineLarge: TextStyle(fontSize: 32, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: darkColors.light),
      headlineMedium: TextStyle(fontSize: 28, height: 1.4, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: darkColors.light),
      headlineSmall: TextStyle(fontSize: 24, height: 1.4, letterSpacing: 0.0, fontWeight: FontWeight.w400, color: darkColors.light),

      titleLarge: TextStyle(fontSize: 22, height: 1.4, letterSpacing: 0.0, fontWeight: FontWeight.w600, color: darkColors.light),
      titleMedium: TextStyle(fontSize: 16, height: 1.4, letterSpacing: 0.15, fontWeight: FontWeight.w600, color: darkColors.light),
      titleSmall: TextStyle(fontSize: 14, height: 1.4, letterSpacing: 0.1, fontWeight: FontWeight.w600, color: darkColors.light),

      labelLarge: TextStyle(fontSize: 14, letterSpacing: 0.1, fontWeight: FontWeight.w600, color: darkColors.light),
      labelMedium: TextStyle(fontSize: 12,letterSpacing: 0.5, fontWeight: FontWeight.w600, color: darkColors.light),
      labelSmall: TextStyle(fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.w600, color: darkColors.light),

      bodyLarge: TextStyle(fontSize: 14, height: 1.5, letterSpacing: 0.15, fontWeight: FontWeight.w400, color: darkColors.light),
      bodyMedium: TextStyle(fontSize: 12, height: 1.5, letterSpacing: 0.25, fontWeight: FontWeight.w600, color: darkColors.light),
      bodySmall: TextStyle(fontSize: 10, height: 1.5, letterSpacing: 0.4, fontWeight: FontWeight.w600, color: darkColors.light),
    )),

    sliderTheme: SliderThemeData(
      activeTrackColor: darkColors.light,
      inactiveTrackColor: darkColors.dark,
      thumbColor: darkColors.light,
      valueIndicatorColor: darkColors.light,
      valueIndicatorStrokeColor: darkColors.normal,
      overlayColor: darkColors.light.withAlpha(darkColors.alphaB),
      valueIndicatorTextStyle: TextStyle(
        color: darkColors.normal
      ),
      showValueIndicator: ShowValueIndicator.always,

    ),

    switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? (states.contains(WidgetState.disabled) ? darkColors.normal : darkColors.light) : darkColors.normal),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? (states.contains(WidgetState.disabled) ? darkColors.dark : darkColors.normal) : darkColors.dark),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.disabled) ? darkColors.normal : darkColors.light),
        overlayColor: WidgetStateProperty.all(darkColors.light.withAlpha(darkColors.alphaB))
    ),

    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
              color: darkColors.light
          )
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: darkColors.light
        )
      )
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered) ? darkColors.normal : darkColors.light),
          backgroundColor: WidgetStateProperty.all(darkColors.normal),
          overlayColor: WidgetStateProperty.all(darkColors.light),
          surfaceTintColor: WidgetStateProperty.all(darkColors.light),
          side: WidgetStateProperty.all(BorderSide(
              color: darkColors.light
          ))
      )

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
              color: darkColors.light
          ))
      )
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? darkColors.normal : darkColors.light),
          backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? darkColors.light : darkColors.normal),
        )
    ),
      textSelectionTheme: TextSelectionThemeData(
          cursorColor: darkColors.light
      )
  );

}