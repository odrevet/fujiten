import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../cubits/theme_cubit.dart';

class ThemeTile extends StatelessWidget {
  final String title;
  final ThemeData themeData;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  ThemeTile({required this.title, required this.themeData, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text(title),
        onTap: () {
          context.read<ThemeCubit>().updateTheme(themeData);
          _prefs.then((prefs) => prefs.setBool(
              'darkTheme', themeData.brightness == Brightness.dark));
        });
  }
}

class ThemeSettings extends StatelessWidget {
  const ThemeSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Brightness')),
      body: BlocBuilder<ThemeCubit, ThemeData>(
        builder: (context, themeData) => ListView(children: [
          ThemeTile(
              title: "Light",
              themeData: ThemeData(brightness: Brightness.light)),
          ThemeTile(
              title: "Dark", themeData: ThemeData(brightness: Brightness.dark)),
        ]),
      ),
    );
  }
}
