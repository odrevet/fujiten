import 'package:flutter/material.dart';

class ThemeState {
  final ThemeData themeData;
  final ThemeMode themeMode;
  final bool isDynamicColor;

  ThemeState({
    required this.themeData,
    required this.themeMode,
    this.isDynamicColor = false,
  });
}
