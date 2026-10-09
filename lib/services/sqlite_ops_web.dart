/// Web build does not support local sqlite databases.
Future<String> downloadAndExtractSqlite({
  required String type,
  required String lang,
  required void Function(String) onProgress,
}) async {
  throw UnsupportedError('SQLite databases are not supported on web');
}

Future<String?> pickSqliteFile() async => null;
