import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const purple = Color(0xFF7B5EA7);
  static const purpleLight = Color(0xFF9B7BC7);
  static const purpleDark = Color(0xFF5A3F8A);
  static const pink = Color(0xFFE91E8C);
  static const orange = Color(0xFFF5A623);
  static const green = Color(0xFF4CD964);
  static const red = Color(0xFFFF3B30);
  static const bgDark = Color(0xFF1C1C2E);
  static const bgDarker = Color(0xFF0F0F1E);
  static const bgLight = Color(0xFFF8F7FF);
  static const cardBg = Color(0xFFF3F0FF);
  static const border = Color(0xFFE8E4F0);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: purple,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
    scaffoldBackgroundColor: bgLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
      titleTextStyle: TextStyle(
        color: Color(0xFF1A1A2E),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: purple,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    scaffoldBackgroundColor: bgDarker,
  );
}
