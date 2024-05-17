import 'package:flutter/material.dart';

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

class KPixTheme {

  static ColorSet lightColors = ColorSet(normal: Colors.grey[350]!, light: Colors.grey[700]!, dark: Colors.grey[200]!);
  static ThemeData monochromeTheme = ThemeData(

    primaryColor: lightColors.normal,
    primaryColorLight: lightColors.light,
    primaryColorDark: lightColors.dark,

    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.grey,
      brightness: Brightness.light,

    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 57, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400),
      displayMedium: TextStyle(fontSize: 45, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400),
      displaySmall: TextStyle(fontSize: 36, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400),

      headlineLarge: TextStyle(fontSize: 32, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400),
      headlineMedium: TextStyle(fontSize: 28, height: 1.4, letterSpacing: 0.0, fontWeight: FontWeight.w400),
      headlineSmall: TextStyle(fontSize: 24, height: 1.4, letterSpacing: 0.0, fontWeight: FontWeight.w400),

      titleLarge: TextStyle(fontSize: 22, height: 1.4, letterSpacing: 0.0, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 16, height: 1.4, letterSpacing: 0.15, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontSize: 14, height: 1.4, letterSpacing: 0.1, fontWeight: FontWeight.w600),

      labelLarge: TextStyle(fontSize: 14, height: 1.4, letterSpacing: 0.1, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontSize: 12, height: 1.4, letterSpacing: 0.5, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(fontSize: 11, height: 1.4, letterSpacing: 0.5, fontWeight: FontWeight.w600),

      bodyLarge: TextStyle(fontSize: 14, height: 1.5, letterSpacing: 0.15, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 12, height: 1.5, letterSpacing: 0.25, fontWeight: FontWeight.w600),
      bodySmall: TextStyle(fontSize: 10, height: 1.5, letterSpacing: 0.4, fontWeight: FontWeight.w600),
    ),
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
      thumbColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? (states.contains(MaterialState.disabled) ? lightColors.normal : lightColors.light) : lightColors.normal),
      trackColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? (states.contains(MaterialState.disabled) ? lightColors.dark :lightColors.normal) : lightColors.dark),
      trackOutlineColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.disabled) ? lightColors.normal : lightColors.light),
      overlayColor: MaterialStateProperty.all(lightColors.normal.withAlpha(lightColors.alphaB))

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
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: MaterialStateProperty.all(lightColors.elevation),
        shadowColor: MaterialStateProperty.all(lightColors.dark),
        foregroundColor: MaterialStateProperty.all(lightColors.light),
        backgroundColor: MaterialStateProperty.all(lightColors.dark),
        overlayColor: MaterialStateProperty.all(lightColors.dark),
        surfaceTintColor: MaterialStateProperty.all(lightColors.light),
        side: MaterialStateProperty.all(
          BorderSide(
            color: lightColors.light
          )
        )
      )
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

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 57, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400),
      displayMedium: TextStyle(fontSize: 45, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400),
      displaySmall: TextStyle(fontSize: 36, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400),

      headlineLarge: TextStyle(fontSize: 32, height: 1.2, letterSpacing: 0.0, fontWeight: FontWeight.w400),
      headlineMedium: TextStyle(fontSize: 28, height: 1.4, letterSpacing: 0.0, fontWeight: FontWeight.w400),
      headlineSmall: TextStyle(fontSize: 24, height: 1.4, letterSpacing: 0.0, fontWeight: FontWeight.w400),

      titleLarge: TextStyle(fontSize: 22, height: 1.4, letterSpacing: 0.0, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 16, height: 1.4, letterSpacing: 0.15, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontSize: 14, height: 1.4, letterSpacing: 0.1, fontWeight: FontWeight.w600),

      labelLarge: TextStyle(fontSize: 14, letterSpacing: 0.1, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontSize: 12,letterSpacing: 0.5, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.w600),

      bodyLarge: TextStyle(fontSize: 14, height: 1.5, letterSpacing: 0.15, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 12, height: 1.5, letterSpacing: 0.25, fontWeight: FontWeight.w600),
      bodySmall: TextStyle(fontSize: 10, height: 1.5, letterSpacing: 0.4, fontWeight: FontWeight.w600),
    ),

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
        thumbColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? (states.contains(MaterialState.disabled) ? darkColors.normal : darkColors.light) : darkColors.normal),
        trackColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? (states.contains(MaterialState.disabled) ? darkColors.dark : darkColors.normal) : darkColors.dark),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.disabled) ? darkColors.normal : darkColors.light),
        overlayColor: MaterialStateProperty.all(darkColors.light.withAlpha(darkColors.alphaB))
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

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: MaterialStateProperty.all(darkColors.elevation),
        shadowColor: MaterialStateProperty.all(darkColors.dark),
        foregroundColor: MaterialStateProperty.all(darkColors.light),
        backgroundColor: MaterialStateProperty.all(darkColors.dark),
        overlayColor: MaterialStateProperty.all(darkColors.normal),
        surfaceTintColor: MaterialStateProperty.all(darkColors.light),
          side: MaterialStateProperty.all(BorderSide(
              color: darkColors.light
          ))
      )
    )
  );

}