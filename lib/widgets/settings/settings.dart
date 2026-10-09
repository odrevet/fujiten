import 'package:flutter/material.dart';
import 'package:fujiten/widgets/favorites/favorites_page.dart';
import 'package:fujiten/widgets/settings/search_options_widget.dart';
import 'package:fujiten/widgets/settings/theme_settings.dart';

import 'about_dialog.dart';
import 'dataset_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.data_usage),
            title: const Text("Databases"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DatasetPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text("Favorites"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritesPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text("Search Options"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Search option')),
                  body: SearchOptionsWidget(),
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text("Theme"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ThemeSettings()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("About"),
            onTap: () => showFujitenAboutDialog(context),
          ),
        ],
      ),
    );
  }
}