import 'package:flutter/material.dart';

abstract final class AppColors {
  static const blue = Color(0xFF1557E8);
  static const ink = Color(0xFF101828);
  static const muted = Color(0xFF667085);
  static const canvas = Color(0xFFF5F7FB);
  static const line = Color(0xFFE5E9F2);
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue),
    fontFamily: 'Arial',
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
      bodyLarge: TextStyle(color: AppColors.ink, height: 1.4),
      bodyMedium: TextStyle(color: AppColors.muted, height: 1.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
    ),
  );
}
