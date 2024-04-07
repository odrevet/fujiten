import 'package:flutter/material.dart';
import 'package:fujiten/widgets/settings/database_settings_widget.dart';

class DatasetPage extends StatelessWidget {
  final Future<void> Function(String) setExpressionDb;
  final Future<void> Function(String) setKanjiDb;

  const DatasetPage(
      {required this.setExpressionDb, required this.setKanjiDb, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Databases')),
        body: ListView(
          children: [
            DatabaseSettingsWidget(type: "expression", setDb: setExpressionDb),
            DatabaseSettingsWidget(type: "kanji", setDb: setKanjiDb)
          ],
        ));
  }
}
