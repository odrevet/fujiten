import 'package:flutter/material.dart';

class ThemeState {
  final ThemeData themeData;
  final ThemeMode themeMode;
  final bool isDynamicColor;
  final bool useAccentColor;
  final Color? customAccentColor;

  ThemeState({
    required this.themeData,
    required this.themeMode,
    required this.useAccentColor,
    this.customAccentColor,
    this.isDynamicColor = false,
  });
}
