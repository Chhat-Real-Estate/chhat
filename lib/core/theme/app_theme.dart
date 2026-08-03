import 'package:flutter/material.dart';

class AppTheme {
  // Premium Dark Theme Colors
  static const Color bgColor = Color(0xFF071A0F);
  static const Color cardColor = Color(0xFF13321C);
  static const Color neonAccent = Color(0xFF90EE90);

  // Original Brand Color
  static const Color originalGreen = Color(0xFF2D6A4F);

  // 1. Light Theme (Jo pehle se tha, usko safe rakha hai)
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: originalGreen,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      );

  // 2. Naya Premium Dark Theme (Jo humne abhi banaya)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      primaryColor: neonAccent,

      // Bottom Navigation Bar Global Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgColor,
        selectedItemColor: neonAccent,
        unselectedItemColor: Colors.grey.shade600,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      // AppBar Global Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),

      // TextField Global Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),

      colorScheme: const ColorScheme.dark(
        primary: neonAccent,
        surface: cardColor,
        background: bgColor,
      ),
      fontFamily: 'Roboto',
    );
  }
}
