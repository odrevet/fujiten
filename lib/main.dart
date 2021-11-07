// @dart=2.9

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'mainWidget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        ],
        title: 'Japanese dictionary',
        home: MainWidget(),
    supportedLocales: [
    const Locale('en'),
    const Locale('fr'),
    const Locale('ja'),
    ],
    );
  }
}
