import 'package:flutter/material.dart';

class AppTheme {
  // We can use a warm, dessert-inspired color scheme as the seed.
  static const Color _primaryColor = Color(0xFFD27D2D); // Caramel/Mocha accent
  static const Color _backgroundColor = Color(0xFFF9F7F3); // Clean off-white

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        surface: _backgroundColor,
      ),
      scaffoldBackgroundColor: _backgroundColor,
      
      // Universal Floating Action Button / Navbar theming can go here
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}