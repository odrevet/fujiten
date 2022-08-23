import 'package:sqlite3/sqlite3.dart';

import '../models/entry.dart';

abstract class DatabaseInterface {
  Database? database;

  DatabaseInterface({this.database});

  Future<void> open(String path) async {
    database = sqlite3.open(path, mode: OpenMode.readOnly);
  }

  Future<void> dispose() async {
  }

  Future<List<Entry>> search(String input, [resultsPerPage = 10, currentPage = 0]);
}
