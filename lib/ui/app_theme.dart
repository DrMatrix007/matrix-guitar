import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const blue = Color(0xFF3B82F6);
  const background = Color(0xFF080B10);
  final colors =
      ColorScheme.fromSeed(
        seedColor: blue,
        brightness: Brightness.dark,
      ).copyWith(
        primary: blue,
    onPrimary: background,
        primaryContainer: const Color(0xFF152E52),
        onPrimaryContainer: const Color(0xFFD6E7FF),
        secondary: const Color(0xFF93C5FD),
        secondaryContainer: const Color(0xFF1C2C43),
        onSecondaryContainer: const Color(0xFFC6DCFA),
        surface: background,
        surfaceContainerLowest: const Color(0xFF05070B),
        surfaceContainerLow: const Color(0xFF10151E),
        surfaceContainer: const Color(0xFF141B26),
        surfaceContainerHigh: const Color(0xFF192230),
        surfaceContainerHighest: const Color(0xFF202B3B),
        onSurface: const Color(0xFFF1F5FC),
        onSurfaceVariant: const Color(0xFF9EADC2),
        outline: const Color(0xFF64748B),
        outlineVariant: const Color(0xFF293547),
      );
  final base = ThemeData(colorScheme: colors, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: background,
    textTheme: base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(color: colors.secondary),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: colors.onSurface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: colors.onSurface,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: blue.withValues(alpha: 0.35)),
      ),
      labelColor: const Color(0xFFBFDBFE),
      unselectedLabelColor: colors.onSurfaceVariant,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      indicatorAnimation: TabIndicatorAnimation.linear,
      splashBorderRadius: BorderRadius.circular(12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: colors.surfaceContainerLow,
      selectedColor: colors.primaryContainer,
      side: BorderSide(color: colors.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: blue,
      linearTrackColor: colors.surfaceContainerHigh,
      linearMinHeight: 6,
      borderRadius: BorderRadius.circular(8),
    ),
  );
}
