import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../cubits/theme_cubit.dart';

class ThemeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeData themeData;
  final bool isSelected;

  const ThemeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.themeData,
    required this.isSelected,
    super.key,
  });

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkTheme', themeData.brightness == Brightness.dark);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[600],
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Theme.of(context).primaryColor : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 24,
              )
            : const Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey,
                size: 24,
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          context.read<ThemeCubit>().updateTheme(themeData);
          _saveThemePreference();
        },
      ),
    );
  }
}

class ThemeSettings extends StatelessWidget {
  const ThemeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: BlocBuilder<ThemeCubit, ThemeData>(
        builder: (context, currentTheme) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose your preferred theme for the app',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ThemeTile(
                  title: "Light Theme",
                  subtitle: "Clean and bright interface",
                  icon: Icons.light_mode,
                  themeData: ThemeData(
                    brightness: Brightness.light,
                    useMaterial3: true,
                  ),
                  isSelected: currentTheme.brightness == Brightness.light,
                ),
                ThemeTile(
                  title: "Dark Theme",
                  subtitle: "Easy on the eyes in low light",
                  icon: Icons.dark_mode,
                  themeData: ThemeData(
                    brightness: Brightness.dark,
                    useMaterial3: true,
                  ),
                  isSelected: currentTheme.brightness == Brightness.dark,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
