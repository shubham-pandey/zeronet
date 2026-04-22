import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Zeronet design tokens
class ZeronetColors {
  ZeronetColors._();

  // Backgrounds
  static const Color background = Color(0xFF0D0F12);
  static const Color surface = Color(0xFF13161B);
  static const Color surfaceLight = Color(0xFF1A1D24);
  static const Color surfaceBorder = Color(0xFF2A2D35);

  // Accents
  static const Color primary = Color(0xFF3D8BFF);
  static const Color primaryDim = Color(0xFF1A3A6B);
  static const Color danger = Color(0xFFFF4444);
  static const Color dangerDim = Color(0xFF3D1111);
  static const Color warning = Color(0xFFFFA94D);
  static const Color success = Color(0xFF22C55E);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textTertiary = Color(0xFF6B7280);
}

class ZeronetTheme {
  ZeronetTheme._();

  static TextStyle get _baseTextStyle => GoogleFonts.inter();

  static TextTheme get textTheme => TextTheme(
        displayLarge: _baseTextStyle.copyWith(
          fontSize: 56,
          fontWeight: FontWeight.w800,
          color: ZeronetColors.textPrimary,
          letterSpacing: -1.5,
        ),
        displayMedium: _baseTextStyle.copyWith(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: ZeronetColors.textPrimary,
          letterSpacing: -1,
        ),
        headlineLarge: _baseTextStyle.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: ZeronetColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: _baseTextStyle.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: ZeronetColors.textPrimary,
        ),
        titleLarge: _baseTextStyle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ZeronetColors.textPrimary,
        ),
        titleMedium: _baseTextStyle.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: ZeronetColors.textPrimary,
        ),
        bodyLarge: _baseTextStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: ZeronetColors.textSecondary,
        ),
        bodyMedium: _baseTextStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ZeronetColors.textSecondary,
        ),
        bodySmall: _baseTextStyle.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: ZeronetColors.textTertiary,
        ),
        labelLarge: _baseTextStyle.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: ZeronetColors.textPrimary,
          letterSpacing: 1.5,
        ),
        labelMedium: _baseTextStyle.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: ZeronetColors.textSecondary,
          letterSpacing: 1.2,
        ),
        labelSmall: _baseTextStyle.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: ZeronetColors.textTertiary,
          letterSpacing: 1.0,
        ),
      );

  /// Monospace style for numbers / coordinates / timers
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        color: ZeronetColors.textPrimary,
        fontFeatures: [const FontFeature.tabularFigures()],
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ZeronetColors.background,
        colorScheme: const ColorScheme.dark(
          surface: ZeronetColors.surface,
          primary: ZeronetColors.primary,
          error: ZeronetColors.danger,
          onPrimary: Colors.white,
          onSurface: ZeronetColors.textPrimary,
        ),
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: ZeronetColors.background,
          elevation: 0,
          titleTextStyle: textTheme.titleLarge,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: ZeronetColors.surface,
          selectedItemColor: ZeronetColors.primary,
          unselectedItemColor: ZeronetColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: ZeronetColors.primary,
          inactiveTrackColor: ZeronetColors.surfaceBorder,
          thumbColor: Colors.white,
          overlayColor: ZeronetColors.primary.withValues(alpha: 0.15),
          trackHeight: 6,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return ZeronetColors.textTertiary;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return ZeronetColors.primary;
            }
            return ZeronetColors.surfaceBorder;
          }),
        ),
      );
}
