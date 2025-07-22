import 'package:flutter/material.dart';
import 'package:fujiten/services/database_interface_expression.dart';
import 'package:fujiten/services/database_interface_kanji.dart';
import 'package:fujiten/widgets/settings/database_settings_widget.dart';

class DatasetPage extends StatefulWidget {
  final DatabaseInterfaceExpression databaseInterfaceExpression;
  final DatabaseInterfaceKanji databaseInterfaceKanji;
  final Function() refreshDbStatus;

  const DatasetPage({
    required this.databaseInterfaceExpression,
    required this.databaseInterfaceKanji,
    required this.refreshDbStatus,
    super.key,
  });

  @override
  State<DatasetPage> createState() => _DatasetPageState();
}

class _DatasetPageState extends State<DatasetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Databases')),
      body: ListView(
        children: [
          DatabaseSettingsWidget(
              type: "expression",
              databaseInterface: widget.databaseInterfaceExpression,
              refreshDbStatus: widget.refreshDbStatus
          ),
          DatabaseSettingsWidget(
            type: "kanji",
            databaseInterface: widget.databaseInterfaceKanji,
            refreshDbStatus: widget.refreshDbStatus,
          ),
        ],
      ),
    );
  }
}
