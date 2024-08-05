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

class KPixTheme {

  static ColorSet lightColors = ColorSet(normal: Colors.grey[400]!, light: Colors.grey[700]!, dark: Colors.grey[350]!);
  static ThemeData monochromeTheme = ThemeData(

    primaryColor: lightColors.normal,
    primaryColorLight: lightColors.light,
    primaryColorDark: lightColors.dark,

    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.grey,
      brightness: Brightness.light,

    ),
    textTheme: GoogleFonts.oxaniumTextTheme(const TextTheme(

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

    textTheme: GoogleFonts.oxaniumTextTheme(const TextTheme(
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
    )
  );

}