import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFFDFCF8);
  static const Color primaryColor = Color(0xFF5B6F9D);
  static const Color accentColor = Color(0xFFFF8A80);
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color pillUnselected = Color(0xFFE0E0E0);

  static const double pageHorizontalPadding = 24.0;

  static const TextStyle logoStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 3.0,
    color: textPrimary,
  );

  static const TextStyle headingStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle subtleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle pillTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.6,
    color: Colors.white,
  );

  static ThemeData get lightTheme => ThemeData(
    scaffoldBackgroundColor: background,
    useMaterial3: true,
    fontFamily: 'San Francisco',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentColor,
    ).copyWith(surface: background),
  );
}
