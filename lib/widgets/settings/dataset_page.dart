import 'package:flutter/material.dart';
import 'package:fujiten/widgets/settings/database_settings_widget.dart';

class DatasetPage extends StatefulWidget {
  final Function() refreshDbStatus;

  const DatasetPage({
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
            refreshDbStatus: widget.refreshDbStatus,
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
