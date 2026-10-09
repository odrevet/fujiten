import 'database_interface.dart';
import 'database_interface_expression.dart';
import 'database_interface_kanji.dart';
import 'postgres/postgres_database_interface_expression.dart';
import 'postgres/postgres_database_interface_kanji.dart';

/// Web build only supports the Postgres backend.
DatabaseInterfaceExpression createExpressionInterface(
  DatabaseBackend backend, {
  String? url,
  String? anonKey,
}) {
  return PostgresDatabaseInterfaceExpression(
    url: url ?? '',
    anonKey: anonKey ?? '',
  );
}

DatabaseInterfaceKanji createKanjiInterface(
  DatabaseBackend backend, {
  String? url,
  String? anonKey,
}) {
  return PostgresDatabaseInterfaceKanji(
    url: url ?? '',
    anonKey: anonKey ?? '',
  );
}
