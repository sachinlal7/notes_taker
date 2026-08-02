import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final generated = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    );
    final colors = brightness == Brightness.light
        ? generated.copyWith(
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            primaryContainer: AppColors.primaryContainer,
            onPrimaryContainer: AppColors.onPrimaryContainer,
            secondary: AppColors.secondary,
            secondaryContainer: AppColors.secondaryContainer,
            onSecondaryContainer: AppColors.onSecondaryContainer,
            tertiary: AppColors.tertiary,
            tertiaryContainer: AppColors.tertiaryContainer,
            onTertiaryContainer: AppColors.onTertiaryContainer,
            error: AppColors.error,
            errorContainer: AppColors.errorContainer,
            onErrorContainer: AppColors.onErrorContainer,
            surface: AppColors.surface,
            surfaceContainerLowest: AppColors.surfaceLowest,
            surfaceContainerLow: AppColors.surfaceLow,
            surfaceContainer: AppColors.surfaceContainer,
            surfaceContainerHigh: AppColors.surfaceHigh,
            surfaceContainerHighest: AppColors.surfaceHighest,
            onSurface: AppColors.textPrimary,
            onSurfaceVariant: AppColors.textSecondary,
            outline: AppColors.outline,
            outlineVariant: AppColors.outlineVariant,
          )
        : generated;
    final base = ThemeData(colorScheme: colors, useMaterial3: true);
    final workSans = GoogleFonts.workSansTextTheme(base.textTheme);
    final inter = GoogleFonts.interTextTheme(base.textTheme);
    return base.copyWith(
      scaffoldBackgroundColor: brightness == Brightness.light
          ? AppColors.background
          : const Color(0xFF111318),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: .08),
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: workSans.copyWith(
        displayLarge: workSans.displayLarge?.copyWith(
          fontSize: 57,
          height: 64 / 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -.25,
        ),
        headlineLarge: workSans.headlineLarge?.copyWith(
          fontSize: 32,
          height: 1.25,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: workSans.headlineMedium?.copyWith(
          fontSize: 28,
          height: 36 / 28,
          fontWeight: FontWeight.w400,
        ),
        titleLarge: workSans.titleLarge?.copyWith(
          fontSize: 22,
          height: 28 / 22,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: workSans.titleMedium?.copyWith(
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w500,
          letterSpacing: .15,
        ),
        bodyLarge: inter.bodyLarge?.copyWith(
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w400,
          letterSpacing: .5,
        ),
        bodyMedium: inter.bodyMedium?.copyWith(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w400,
          letterSpacing: .25,
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          color: colors.onSurface,
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w500,
          letterSpacing: .1,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          color: colors.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
