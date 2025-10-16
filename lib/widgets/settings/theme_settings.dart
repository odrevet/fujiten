import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/theme_cubit.dart';
import '../../models/states/theme_state.dart';


class ThemeSettings extends StatelessWidget {
  const ThemeSettings({super.key});

  // Check if dynamic colors are supported on this platform
  bool get _supportsDynamicColors {
    try {
      return Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows;
    } catch (e) {
      // If Platform is not available (web), assume no support
      return false;
    }
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
          final isDark = currentMode == ThemeMode.dark;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme Mode Switch (Light/Dark)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  child: SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
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
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    subtitle: Text(
                      isDark
                          ? 'Easy on the eyes in low light'
                          : 'Clean and bright interface',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    value: isDark,
                    onChanged: (value) {
                      context.read<ThemeCubit>().toggleThemeMode(value);
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // Dynamic Colors Switch (only show if supported)
                if (_supportsDynamicColors) ...[
                  const SizedBox(height: 8),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    child: SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDynamicColor
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
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
                          color: isDynamicColor ? Theme.of(context).primaryColor : null,
                        ),
                      ),
                      subtitle: Text(
                        'Use colors from your wallpaper (Android 12+)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      value: isDynamicColor,
                      onChanged: (value) {
                        context.read<ThemeCubit>().toggleDynamicColors(value);
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}