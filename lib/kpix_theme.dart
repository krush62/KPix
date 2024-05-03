import 'package:flutter/material.dart';

class KPixTheme {

  static ThemeData monochromeTheme = ThemeData(

    // Define color scheme
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.grey,
      backgroundColor: Colors.grey[100],
      errorColor: Colors.red,
      brightness: Brightness.light,
      accentColor: Colors.grey[200],
      cardColor: Colors.grey[400],
    ),

    // Define text themes for different text styles
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

    // Define button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.grey[800]),
        foregroundColor: MaterialStateProperty.all(Colors.grey[100]),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
      ),
    ),

    // Define card theme
    cardTheme: CardTheme(
      color: Colors.grey[200],
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ),

    // Define scaffold background color
    scaffoldBackgroundColor: Colors.grey[100],

    // Define divider color
    dividerColor: Colors.grey[600],

    // Define icon themes
    iconTheme: IconThemeData(color: Colors.grey[800]),

    // Define app bar theme
    appBarTheme: AppBarTheme(
      color: Colors.grey[800],
      iconTheme: IconThemeData(color: Colors.grey[100]),
      // Corrected to use titleTextStyle in appBarTheme
      titleTextStyle: TextStyle(color: Colors.grey[100], fontSize: 20.0),
    ),
  );




  static ThemeData monochromeThemeDark = ThemeData(
    // Define primary color as a shade of grey
    primaryColor: Colors.grey[800],

    // Define color scheme
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.grey,
      backgroundColor: Colors.grey[900],
      errorColor: Colors.red,
      brightness: Brightness.dark
    ),


    // Define text themes for different text styles
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

    // Define button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.grey[100]),
        foregroundColor: MaterialStateProperty.all(Colors.grey[800]),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
      ),
    ),

    // Define card theme
    cardTheme: CardTheme(
      color: Colors.grey[800],
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ),

    // Define scaffold background color
    scaffoldBackgroundColor: Colors.grey[100],

    // Define divider color
    dividerColor: Colors.grey[600],

    // Define icon themes
    iconTheme: IconThemeData(color: Colors.grey[200]),

    // Define app bar theme
    appBarTheme: AppBarTheme(
      color: Colors.grey[800],
      iconTheme: IconThemeData(color: Colors.grey[100]),
      // Corrected to use titleTextStyle in appBarTheme
      titleTextStyle: TextStyle(color: Colors.grey[100], fontSize: 20.0),
    ),
  );



}