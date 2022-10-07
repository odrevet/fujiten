import 'package:sqflite/sqflite.dart';

import '../models/entry.dart';

enum DatabaseStatus {
  ok,
  pathNotSet,
  noResults,
}

abstract class DatabaseInterface {
  Database? database;
  DatabaseStatus? status;

  DatabaseInterface({this.database});

  Future<void> open(String path) async {
    database = await openDatabase(path, readOnly: true);
  }

  Future<void> dispose() async {
    database?.close();
  }

  Future<List<Entry>> search(String input, [resultsPerPage = 10, currentPage = 0]);
}
