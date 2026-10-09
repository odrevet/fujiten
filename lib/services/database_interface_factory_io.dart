import 'database_interface.dart';
import 'database_interface_expression.dart';
import 'database_interface_kanji.dart';
import 'postgres/postgres_database_interface_expression.dart';
import 'postgres/postgres_database_interface_kanji.dart';
import 'sqlite/sqlite_database_interface_expression.dart';
import 'sqlite/sqlite_database_interface_kanji.dart';

DatabaseInterfaceExpression createExpressionInterface(
  DatabaseBackend backend, {
  String? url,
  String? anonKey,
}) {
  switch (backend) {
    case DatabaseBackend.sqlite:
      return SqliteDatabaseInterfaceExpression();
    case DatabaseBackend.postgres:
      return PostgresDatabaseInterfaceExpression(
        url: url!,
        anonKey: anonKey!,
      );
  }
}

DatabaseInterfaceKanji createKanjiInterface(
  DatabaseBackend backend, {
  String? url,
  String? anonKey,
}) {
  switch (backend) {
    case DatabaseBackend.sqlite:
      return SqliteDatabaseInterfaceKanji();
    case DatabaseBackend.postgres:
      return PostgresDatabaseInterfaceKanji(
        url: url!,
        anonKey: anonKey!,
      );
  }
}
