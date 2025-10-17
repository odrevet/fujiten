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
    useAccentColor: false,
    customAccentColor: null,
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
    final useAccentColor = prefs.getBool('useAccentColor') ?? false;
    final customColorValue = prefs.getInt('customAccentColor');

    final mode = ThemeMode.values.firstWhere(
          (e) => e.toString() == themeModeString,
      orElse: () => ThemeMode.light,
    );

    final customColor = customColorValue != null ? Color(customColorValue) : null;

    await updateThemeMode(
      mode,
      useDynamicColors: useDynamicColors,
      useAccentColor: useAccentColor,
      customAccentColor: customColor,
    );
  }

  /// Toggle dynamic colors on/off (preserves current theme mode)
  Future<void> toggleDynamicColors(bool enabled) async {
    final currentMode = state.themeMode;
    await updateThemeMode(currentMode, useDynamicColors: enabled);
  }

  /// Toggle system accent color on/off (desktop platforms)
  Future<void> toggleAccentColor(bool enabled) async {
    final currentMode = state.themeMode;
    await updateThemeMode(currentMode, useAccentColor: enabled);
  }

  /// Set custom accent color from color picker
  Future<void> setCustomAccentColor(Color color) async {
    final currentMode = state.themeMode;
    await updateThemeMode(
      currentMode,
      useAccentColor: false,
      useDynamicColors: false,
      customAccentColor: color,
    );

    // Save custom color
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('customAccentColor', color.value);
  }

  /// Clear custom accent color
  Future<void> clearCustomAccentColor() async {
    final currentMode = state.themeMode;
    await updateThemeMode(currentMode, customAccentColor: null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('customAccentColor');
  }

  /// Toggle between light and dark mode (preserves dynamic color setting)
  Future<void> toggleThemeMode(bool isDark) async {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    final useDynamicColors = state.isDynamicColor;
    final useAccentColor = state.useAccentColor;
    final customColor = state.customAccentColor;
    await updateThemeMode(
      mode,
      useDynamicColors: useDynamicColors,
      useAccentColor: useAccentColor,
      customAccentColor: customColor,
    );
  }

  /// Update theme mode with all color options
  Future<void> updateThemeMode(
      ThemeMode mode, {
        bool useDynamicColors = false,
        bool useAccentColor = false,
        Color? customAccentColor,
      }) async {
    // Priority: Dynamic Colors > Accent Color > Custom Color > Default
    if (useDynamicColors) {
      await _applyDynamicTheme(mode);
    } else if (useAccentColor) {
      await _applyAccentColorTheme(mode);
    } else if (customAccentColor != null) {
      _applyCustomColorTheme(mode, customAccentColor);
    } else {
      _applyStaticTheme(mode);
    }

    // Save preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.toString());
    await prefs.setBool('useDynamicColors', useDynamicColors);
    await prefs.setBool('useAccentColor', useAccentColor);
  }

  /// Apply dynamic theme based on system colors (Android)
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
          useAccentColor: false,
          customAccentColor: null,
        ));
      } else {
        _applyStaticTheme(mode);
      }
    } catch (e) {
      debugPrint('Dynamic colors not available: $e');
      _applyStaticTheme(mode);
    }
  }

  /// Apply theme based on system accent color (Desktop)
  Future<void> _applyAccentColorTheme(ThemeMode mode) async {
    try {
      final accentColor = await DynamicColorPlugin.getAccentColor();

      if (accentColor != null) {
        final brightness = mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
        final colorScheme = ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: brightness,
        );

        emit(ThemeState(
          themeData: ThemeData(colorScheme: colorScheme, useMaterial3: true),
          themeMode: mode,
          isDynamicColor: false,
          useAccentColor: true,
          customAccentColor: null,
        ));
      } else {
        _applyStaticTheme(mode);
      }
    } catch (e) {
      debugPrint('Accent color not available: $e');
      _applyStaticTheme(mode);
    }
  }

  /// Apply theme with custom accent color
  void _applyCustomColorTheme(ThemeMode mode, Color accentColor) {
    final brightness = mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: brightness,
    );

    emit(ThemeState(
      themeData: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
      ),
      themeMode: mode,
      isDynamicColor: false,
      useAccentColor: false,
      customAccentColor: accentColor,
    ));
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
      useAccentColor: false,
      customAccentColor: null,
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
        useAccentColor: false,
        customAccentColor: null,
      ));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('useDynamicColors', false);
      await prefs.setBool('useAccentColor', false);
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
      useAccentColor: false,
      customAccentColor: null,
    ));
  }
}