import 'package:flutter/material.dart';
import 'package:fujiten/services/database_interface_expression.dart';

import '../services/database_interface.dart';
import '../services/database_interface_kanji.dart';

class DatabaseStatusDisplay extends StatelessWidget {
  final DatabaseInterfaceKanji databaseInterfaceKanji;
  final DatabaseInterfaceExpression databaseInterfaceExpression;

  const DatabaseStatusDisplay({
    required this.databaseInterfaceExpression,
    required this.databaseInterfaceKanji,
    super.key,
  });

  String databaseStatusFormat(DatabaseStatus? databaseStatus) {
    switch (databaseStatus) {
      case null:
        return "No database set. Please choose a Database in the setting menu";
      case DatabaseStatus.ok:
        return "OK";
      case DatabaseStatus.noResults:
        return "The selected database is invalid (no entry found)";
      case DatabaseStatus.pathNotSet:
        return "No database set. Please choose a Database in the setting menu";
      default:
        return "Unknown status $databaseStatus";
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        "Kanji DB: ${databaseStatusFormat(databaseInterfaceKanji.status)}",
        style: TextStyle(
          color: databaseInterfaceKanji.status != DatabaseStatus.ok
              ? Colors.red
              : Colors.green,
        ),
      ),
      const Divider(),
      Text(
        "Expression DB: ${databaseStatusFormat(databaseInterfaceExpression.status)}",
        style: TextStyle(
          color: databaseInterfaceExpression.status != DatabaseStatus.ok
              ? Colors.red
              : Colors.green,
        ),
      ),
      databaseInterfaceKanji.status != DatabaseStatus.ok ||
              databaseInterfaceExpression.status != DatabaseStatus.ok
          ? const Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Database must be set from the setting menu'),
                ],
              ),
            )
          : const Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(child: Icon(Icons.check)),
                  TextSpan(text: 'All DB OK'),
                ],
              ),
            ),
    ],
  );
}
