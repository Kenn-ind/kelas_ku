import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get light {
    const seed = Color(0xFF7C4DFF);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
    );
    final textTheme = _buildTextTheme(baseTheme.textTheme, colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF7F5FC),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: seed, width: 1.3),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: StadiumBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: seed.withValues(alpha: 0.12),
        backgroundColor: Colors.white,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color:
                isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color:
                isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            size: 22,
          );
        }),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: seed.withValues(alpha: 0.08),
        selectedColor: seed.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, ColorScheme colorScheme) {
    final bodyTheme = GoogleFonts.nunitoSansTextTheme(base).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return bodyTheme.copyWith(
      displayLarge: GoogleFonts.poppins(
        textStyle: bodyTheme.displayLarge,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -1.2,
      ),
      displayMedium: GoogleFonts.poppins(
        textStyle: bodyTheme.displayMedium,
        fontWeight: FontWeight.w800,
        height: 1.12,
        letterSpacing: -0.9,
      ),
      displaySmall: GoogleFonts.poppins(
        textStyle: bodyTheme.displaySmall,
        fontWeight: FontWeight.w700,
        height: 1.14,
        letterSpacing: -0.6,
      ),
      headlineLarge: GoogleFonts.poppins(
        textStyle: bodyTheme.headlineLarge,
        fontWeight: FontWeight.w800,
        height: 1.18,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.poppins(
        textStyle: bodyTheme.headlineMedium,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.poppins(
        textStyle: bodyTheme.headlineSmall,
        fontWeight: FontWeight.w700,
        height: 1.22,
      ),
      titleLarge: GoogleFonts.poppins(
        textStyle: bodyTheme.titleLarge,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleMedium: GoogleFonts.poppins(
        textStyle: bodyTheme.titleMedium,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleSmall: GoogleFonts.poppins(
        textStyle: bodyTheme.titleSmall,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      bodyLarge: GoogleFonts.nunitoSans(
        textStyle: bodyTheme.bodyLarge,
        fontWeight: FontWeight.w500,
        height: 1.45,
      ),
      bodyMedium: GoogleFonts.nunitoSans(
        textStyle: bodyTheme.bodyMedium,
        fontWeight: FontWeight.w500,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.nunitoSans(
        textStyle: bodyTheme.bodySmall,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.nunitoSans(
        textStyle: bodyTheme.labelLarge,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.nunitoSans(
        textStyle: bodyTheme.labelMedium,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
      ),
      labelSmall: GoogleFonts.nunitoSans(
        textStyle: bodyTheme.labelSmall,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}
