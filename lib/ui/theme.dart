import 'package:flutter/material.dart';

ThemeData newtubeTheme(
  Brightness brightness, {
  bool oled = false,
  int seedColor = 0xFFD32F2F,
  List<String> fontFamilyFallback = const [],
}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: Color(seedColor),
    brightness: brightness,
  );
  final theme = ThemeData(
    colorScheme: scheme,
    fontFamily: 'Inter',
    fontFamilyFallback: fontFamilyFallback,
  );
  if (!oled) return theme;
  return theme.copyWith(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: scheme.copyWith(
      surface: Colors.black,
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: Colors.black,
      surfaceContainer: Colors.black,
      surfaceContainerHigh: Colors.black,
      surfaceContainerHighest: Colors.black,
      surfaceTint: Colors.transparent,
    ),
    cardTheme: theme.cardTheme.copyWith(color: const Color(0xFF111111)),
    dialogTheme: theme.dialogTheme.copyWith(backgroundColor: Colors.black),
  );
}
