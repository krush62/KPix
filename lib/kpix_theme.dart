import 'package:flutter/material.dart';

//https://medium.com/@krishnajiyedlapalli60/creating-custom-theme-in-flutter-with-material-3-70e524a126d0
class KPixTheme {

  static ThemeData lightThemeData(BuildContext context) {
    return ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF9C413E),
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFFFFDAD7),
          onPrimaryContainer: Color(0xFF410004),
          secondary: Color(0xFF6D5E00),
          onSecondary: Color(0xFFFFFFFF),
          secondaryContainer: Color(0xFFFCE365),
          onSecondaryContainer: Color(0xFF211B00),
          tertiary: Color(0xFF3E691A),
          onTertiary: Color(0xFFFFFFFF),
          tertiaryContainer: Color(0xFFBEF291),
          onTertiaryContainer: Color(0xFF0C2000),
          error: Color(0xFFBA1A1A),
          errorContainer: Color(0xFFFFDAD6),
          onError: Color(0xFFFFFFFF),
          onErrorContainer: Color(0xFF410002),
          background: Color(0xFFF8FDFF),
          onBackground: Color(0xFF001F25),
          surface: Color(0xFFF8FDFF),
          onSurface: Color(0xFF001F25),
          surfaceVariant: Color(0xFFF5DDDB),
          onSurfaceVariant: Color(0xFF534342),
          outline: Color(0xFF857371),
          onInverseSurface: Color(0xFFD6F6FF),
          inverseSurface: Color(0xFF00363F),
          inversePrimary: Color(0xFFFFB3AE),
          shadow: Color(0xFF000000),
          surfaceTint: Color(0xFF9C413E),
          outlineVariant: Color(0xFFD8C2C0),
          scrim: Color(0xFF000000)
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

        bodyLarge: TextStyle(fontSize: 16, height: 1.5, letterSpacing: 0.15, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, letterSpacing: 0.25, fontWeight: FontWeight.w600),
        bodySmall: TextStyle(fontSize: 12, height: 1.5, letterSpacing: 0.4, fontWeight: FontWeight.w600),
      )
    );

    }

  static ThemeData darkThemeData() {
    return ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFFFB3AE),
          onPrimary: Color(0xFF5F1415),
          primaryContainer: Color(0xFF7E2A29),
          onPrimaryContainer: Color(0xFFFFDAD7),
          secondary: Color(0xFFDEC64C),
          onSecondary: Color(0xFF393000),
          secondaryContainer: Color(0xFF524600),
          onSecondaryContainer: Color(0xFFFCE365),
          tertiary: Color(0xFFA2D578),
          onTertiary: Color(0xFF193800),
          tertiaryContainer: Color(0xFF275000),
          onTertiaryContainer: Color(0xFFBEF291),
          error: Color(0xFFFFB4AB),
          errorContainer: Color(0xFF93000A),
          onError: Color(0xFF690005),
          onErrorContainer: Color(0xFFFFDAD6),
          background: Color(0xFF001F25),
          onBackground: Color(0xFFA6EEFF),
          surface: Color(0xFF001F25),
          onSurface: Color(0xFFA6EEFF),
          surfaceVariant: Color(0xFF534342),
          onSurfaceVariant: Color(0xFFD8C2C0),
          outline: Color(0xFFA08C8B),
          onInverseSurface: Color(0xFF001F25),
          inverseSurface: Color(0xFFA6EEFF),
          inversePrimary: Color(0xFF9C413E),
          shadow: Color(0xFF000000),
          surfaceTint: Color(0xFFFFB3AE),
          outlineVariant: Color(0xFF534342),
          scrim: Color(0xFF000000)
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

          bodyLarge: TextStyle(fontSize: 16, height: 1.5, letterSpacing: 0.15, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 14, height: 1.5, letterSpacing: 0.25, fontWeight: FontWeight.w600),
          bodySmall: TextStyle(fontSize: 12, height: 1.5, letterSpacing: 0.4, fontWeight: FontWeight.w600),
        )
    );
  }
}