import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fujiten/services/database_interface_expression.dart';
import 'package:fujiten/services/database_interface_kanji.dart';
import 'package:fujiten/widgets/settings/database_settings_widget.dart';

import '../../services/database_interface.dart';

class DatasetPage extends StatelessWidget {
  final Future<void> Function(String) setExpressionDb;
  final Future<void> Function(String) setKanjiDb;
  final DatabaseInterfaceExpression databaseInterfaceExpression;
  final DatabaseInterfaceKanji databaseInterfaceKanji;
  final VoidCallback? onBackPressed;

  const DatasetPage({
    required this.setExpressionDb,
    required this.setKanjiDb,
    required this.databaseInterfaceExpression,
    required this.databaseInterfaceKanji,
    this.onBackPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: onBackPressed == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && onBackPressed != null) {
          onBackPressed!();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Databases')),
        body: ListView(
          children: [
            DatabaseSettingsWidget(type: "expression", setDb: setExpressionDb),
            DatabaseSettingsWidget(type: "kanji", setDb: setKanjiDb),
            /*if (databaseInterfaceExpression.status == DatabaseStatus.ok &&
                databaseInterfaceKanji.status == DatabaseStatus.ok)*/
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
