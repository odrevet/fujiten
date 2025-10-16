import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/states/theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeState(
    themeData: _defaultTheme,
    themeMode: ThemeMode.light,
    isDynamicColor: false,
  ));

  static final ThemeData _defaultTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    useMaterial3: true,
    brightness: Brightness.light,
  );

  /// Initialize theme from saved preferences
  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode') ?? 'ThemeMode.light';
    final useDynamicColors = prefs.getBool('useDynamicColors') ?? false;

    final mode = ThemeMode.values.firstWhere(
          (e) => e.toString() == themeModeString,
      orElse: () => ThemeMode.light,
    );

    await updateThemeMode(mode, useDynamicColors: useDynamicColors);
  }

  /// Toggle dynamic colors on/off (preserves current theme mode)
  Future<void> toggleDynamicColors(bool enabled) async {
    final currentMode = state.themeMode;
    await updateThemeMode(currentMode, useDynamicColors: enabled);
  }

  /// Toggle between light and dark mode (preserves dynamic color setting)
  Future<void> toggleThemeMode(bool isDark) async {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    final useDynamicColors = state.isDynamicColor;
    await updateThemeMode(mode, useDynamicColors: useDynamicColors);
  }

  /// Update theme mode (light/dark/system) with optional dynamic colors
  Future<void> updateThemeMode(ThemeMode mode, {bool useDynamicColors = false}) async {
    if (useDynamicColors) {
      await _applyDynamicTheme(mode);
    } else {
      _applyStaticTheme(mode);
    }

    // Save preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.toString());
    await prefs.setBool('useDynamicColors', useDynamicColors);
  }

  /// Apply dynamic theme based on system colors
  Future<void> _applyDynamicTheme(ThemeMode mode) async {
    try {
      final corePalette = await DynamicColorPlugin.getCorePalette();

      if (corePalette != null) {
        final brightness = mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
        final colorScheme = corePalette.toColorScheme(brightness: brightness);

        emit(ThemeState(
          themeData: ThemeData(colorScheme: colorScheme, useMaterial3: true),
          themeMode: mode,
          isDynamicColor: true,
        ));
      } else {
        // Fallback to static theme if dynamic colors unavailable
        _applyStaticTheme(mode);
      }
    } catch (e) {
      debugPrint('Dynamic colors not available: $e');
      _applyStaticTheme(mode);
    }
  }

  /// Apply static theme without dynamic colors
  void _applyStaticTheme(ThemeMode mode) {
    final brightness = mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: brightness,
    );

    emit(ThemeState(
      themeData: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
      ),
      themeMode: mode,
      isDynamicColor: false,
    ));
  }

  /// Update theme from a custom image
  Future<void> updateThemeFromImage(ImageProvider imageProvider) async {
    try {
      final brightness = state.themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;
      final colorScheme = await ColorScheme.fromImageProvider(
        provider: imageProvider,
        brightness: brightness,
      );

      emit(ThemeState(
        themeData: ThemeData(colorScheme: colorScheme, useMaterial3: true),
        themeMode: state.themeMode,
        isDynamicColor: false,
      ));

      // Save that we're no longer using dynamic colors
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('useDynamicColors', false);
    } catch (e) {
      debugPrint('Failed to extract colors from image: $e');
    }
  }

  /// Update theme directly
  void updateTheme(ThemeData themeData) {
    final mode = themeData.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    emit(ThemeState(
      themeData: themeData,
      themeMode: mode,
      isDynamicColor: false,
    ));
  }
}