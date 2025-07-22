import 'package:flutter/material.dart';
import 'package:fujiten/services/database_interface.dart';
import 'package:fujiten/services/database_interface_expression.dart';
import 'package:fujiten/services/database_interface_kanji.dart';
import 'package:fujiten/widgets/settings/database_settings_widget.dart';

import '../database_status_display.dart';

class DatasetPage extends StatefulWidget {
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
  State<DatasetPage> createState() => _DatasetPageState();
}

class _DatasetPageState extends State<DatasetPage> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.onBackPressed == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.onBackPressed != null) {
          widget.onBackPressed!();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Databases')),
        body: ListView(
          children: [
            DatabaseSettingsWidget(
              type: "expression",
              setDb: widget.setExpressionDb,
              databaseInterface: widget.databaseInterfaceExpression,
            ),
            DatabaseSettingsWidget(
              type: "kanji",
              setDb: widget.setKanjiDb,
              databaseInterface: widget.databaseInterfaceKanji,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Check if databases are OK first
                    bool bothDbsOk =
                        widget.databaseInterfaceKanji.status ==
                            DatabaseStatus.ok &&
                        widget.databaseInterfaceExpression.status ==
                            DatabaseStatus.ok;

                    if (bothDbsOk) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() {
                        widget.databaseInterfaceExpression.setStatus();
                        widget.databaseInterfaceKanji.setStatus();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: Text('Continue', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
