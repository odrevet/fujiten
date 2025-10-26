import 'dart:io' show Platform;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../cubits/theme_cubit.dart';
import '../../models/states/theme_state.dart';

class ThemeSettings extends StatelessWidget {
  const ThemeSettings({super.key});

  // Check if dynamic colors are supported (Android 12+)
  bool get _supportsDynamicColors {
    try {
      return Platform.isAndroid;
    } catch (e) {
      return false;
    }
  }

  // Check if accent color is supported (Desktop platforms)
  bool get _supportsAccentColor {
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (e) {
      return false;
    }
  }

  Future<void> _showColorPicker(
    BuildContext context,
    Color currentColor,
  ) async {
    Color pickerColor = currentColor;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Pick an Accent Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              labelTypes: const [],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                context.read<ThemeCubit>().setCustomAccentColor(pickerColor);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          final currentMode = themeState.themeMode;
          final isDynamicColor = themeState.isDynamicColor;
          final useAccentColor = themeState.useAccentColor;
          final customAccentColor = themeState.customAccentColor;
          final isDark = currentMode == ThemeMode.dark;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme Mode Switch (Light/Dark)
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                  child: SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                        color: isDark
                            ? Theme.of(context).primaryColor
                            : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    title: Text(
                      isDark ? 'Dark Mode' : 'Light Mode',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isDark
                          ? 'Easy on the eyes in low light'
                          : 'Clean and bright interface',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    value: isDark,
                    onChanged: (value) {
                      context.read<ThemeCubit>().toggleThemeMode(value);
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(),
                ),

                // Color Options Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Text(
                    'Color Options',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Dynamic Colors Switch (Android only)
                if (_supportsDynamicColors) ...[
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    elevation: 2,
                    child: SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDynamicColor
                              ? Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.palette,
                          color: isDynamicColor
                              ? Theme.of(context).primaryColor
                              : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                      title: Text(
                        'Dynamic Colors',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDynamicColor
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        'Use colors from your wallpaper (Android 12+)',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      value: isDynamicColor,
                      onChanged: (value) {
                        context.read<ThemeCubit>().toggleDynamicColors(value);
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],

                // System Accent Color Switch (Desktop only)
                if (_supportsAccentColor) ...[
                  FutureBuilder<Color?>(
                    future: DynamicColorPlugin.getAccentColor(),
                    builder: (context, snapshot) {
                      final accentColorAvailable =
                          snapshot.hasData && snapshot.data != null;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 2,
                        child: SwitchListTile(
                          secondary: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: useAccentColor && accentColorAvailable
                                  ? Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.color_lens,
                              color: useAccentColor && accentColorAvailable
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[600],
                              size: 24,
                            ),
                          ),
                          title: const Text(
                            'System Accent Color',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            accentColorAvailable
                                ? 'Use your system accent color'
                                : 'System accent color not available',
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: useAccentColor && accentColorAvailable,
                          onChanged: accentColorAvailable
                              ? (value) {
                                  context.read<ThemeCubit>().toggleAccentColor(
                                    value,
                                  );
                                }
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                ],

                // Custom Accent Color Picker
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: customAccentColor != null
                            ? customAccentColor.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: customAccentColor != null
                            ? Border.all(color: customAccentColor, width: 2)
                            : null,
                      ),
                      child: Icon(
                        Icons.colorize,
                        color: customAccentColor ?? Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      'Custom Accent Color',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      customAccentColor != null
                          ? 'Custom color applied'
                          : 'Choose your own accent color',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    trailing: customAccentColor != null
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              context
                                  .read<ThemeCubit>()
                                  .clearCustomAccentColor();
                            },
                            tooltip: 'Clear custom color',
                          )
                        : const Icon(Icons.chevron_right),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      _showColorPicker(
                        context,
                        customAccentColor ?? Theme.of(context).primaryColor,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
