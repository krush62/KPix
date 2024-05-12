import 'package:flutter/material.dart';

class KPixTheme {

  static ThemeData monochromeTheme = ThemeData(

    primaryColor: Colors.grey[300],
    primaryColorLight: Colors.grey[700],
    primaryColorDark: Colors.grey[100],

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
      activeTrackColor: Colors.grey[700],
      inactiveTrackColor: Colors.grey[100],
      thumbColor: Colors.grey[700],
      valueIndicatorColor: Colors.grey[700],
      valueIndicatorStrokeColor: Colors.grey[300],
      overlayColor: Colors.grey[100]!.withAlpha(100),
      valueIndicatorTextStyle: TextStyle(
          color: Colors.grey[100]
      ),
      showValueIndicator: ShowValueIndicator.always,

    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? (states.contains(MaterialState.disabled) ? Colors.grey[700] : Colors.grey[300]) : Colors.grey[300]),
      trackColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? (states.contains(MaterialState.disabled) ? Colors.grey[100] :Colors.grey[300]) : Colors.grey[100]),
      trackOutlineColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.disabled) ? Colors.grey[300] : Colors.grey[700]),
      overlayColor: MaterialStateProperty.all(Colors.grey[300]!.withAlpha(100))

    )
  );




  static ThemeData monochromeThemeDark = ThemeData(

    primaryColor: Colors.grey[800],
    primaryColorLight: Colors.grey[400],
    primaryColorDark: Colors.grey[900],


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

      labelLarge: TextStyle(fontSize: 14, height: 1.4, letterSpacing: 0.1, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontSize: 12, height: 1.4, letterSpacing: 0.5, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(fontSize: 11, height: 1.4, letterSpacing: 0.5, fontWeight: FontWeight.w600),

      bodyLarge: TextStyle(fontSize: 14, height: 1.5, letterSpacing: 0.15, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 12, height: 1.5, letterSpacing: 0.25, fontWeight: FontWeight.w600),
      bodySmall: TextStyle(fontSize: 10, height: 1.5, letterSpacing: 0.4, fontWeight: FontWeight.w600),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: Colors.grey[400],
      inactiveTrackColor: Colors.grey[900],
      thumbColor: Colors.grey[400],
      valueIndicatorColor: Colors.grey[400],
      valueIndicatorStrokeColor: Colors.grey[800],
      overlayColor: Colors.grey[400]!.withAlpha(100),
      valueIndicatorTextStyle: TextStyle(
        color: Colors.grey[800]
      ),
      showValueIndicator: ShowValueIndicator.always,

    ),

    switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? (states.contains(MaterialState.disabled) ? Colors.grey[800] : Colors.grey[400]) : Colors.grey[800]),
        trackColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? (states.contains(MaterialState.disabled) ? Colors.grey[900] : Colors.grey[800]) : Colors.grey[900]),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.disabled) ? Colors.grey[800] : Colors.grey[400]),
        overlayColor: MaterialStateProperty.all(Colors.grey[400]!.withAlpha(900))
    ),

  );

}