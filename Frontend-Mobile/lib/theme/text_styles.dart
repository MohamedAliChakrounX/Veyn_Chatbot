import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class VeynTheme {
  static ThemeData getTheme({bool isArabic = false}) {
    final textTheme = isArabic
        ? GoogleFonts.readexProTextTheme()
        : GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: VeynColors.surfaceSunken,
      primaryColor: VeynColors.accent,
      colorScheme: const ColorScheme.light(
        primary: VeynColors.accent,
        secondary: VeynColors.ink,
        surface: VeynColors.surface,
        error: VeynColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: VeynColors.ink,
      ),
      textTheme: textTheme.apply(
        bodyColor: VeynColors.ink,
        displayColor: VeynColors.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: VeynColors.surface.withValues(alpha: 0.95),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: VeynColors.inkSoft),
        titleTextStyle: isArabic
            ? GoogleFonts.readexPro(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: VeynColors.ink,
              )
            : GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: VeynColors.ink,
              ),
      ),
      cardTheme: CardThemeData(
        color: VeynColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: VeynColors.line),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: VeynColors.line,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
