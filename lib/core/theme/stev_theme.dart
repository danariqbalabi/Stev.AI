// Stev.AI ThemeData built from StevTokens.
//
// Use it in lib/app/app.dart:  theme: StevTheme.light,
// (replaces the seed-color AppTheme; the green seed palette is not the brand).

import 'package:flutter/material.dart';

import 'stev_tokens.dart';

abstract final class StevTheme {
  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: StevColors.ink,
      onPrimary: StevColors.onInk,
      secondary: StevColors.leaf,
      onSecondary: StevColors.ink,
      error: StevColors.over,
      onError: StevColors.onInk,
      surface: StevColors.canvas,
      onSurface: StevColors.ink,
      onSurfaceVariant: StevColors.ink2,
      outline: StevColors.ink3,
      outlineVariant: StevColors.glassEdge,
      surfaceContainerLowest: StevColors.card,
      surfaceContainerLow: StevColors.card,
      surfaceContainer: StevColors.canvas,
      surfaceContainerHigh: StevColors.card,
      surfaceContainerHighest: StevColors.card,
    );

    final text = TextTheme(
      displayLarge: StevType.heroCard,
      displayMedium: StevType.number,
      headlineLarge: StevType.title,
      headlineMedium: StevType.headingResult,
      titleLarge: StevType.heading,
      titleMedium: StevType.label,
      bodyLarge: StevType.label,
      bodyMedium: StevType.body,
      bodySmall: StevType.caption,
      labelLarge: StevType.button,
      labelSmall: StevType.micro,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: StevType.family,
      textTheme: text,
      scaffoldBackgroundColor: StevColors.canvas,
      splashFactory: NoSplash.splashFactory, // feedback = 3D press, not ripples
      highlightColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: StevColors.ink,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: StevColors.card,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent, // sheets draw their own glass
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: StevColors.glassCard,
        hintStyle: StevType.label.copyWith(color: StevColors.ink2),
        contentPadding: const EdgeInsets.symmetric(horizontal: StevSpace.s4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StevRadius.button),
          borderSide: const BorderSide(color: StevColors.glassEdge),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StevRadius.button),
          borderSide: const BorderSide(color: StevColors.glassEdge),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StevRadius.button),
          borderSide: const BorderSide(color: StevColors.ink, width: 2),
        ),
      ),
    );
  }
}
