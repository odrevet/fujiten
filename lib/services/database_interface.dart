import 'package:sqflite/sqflite.dart';

import '../models/entry.dart';

enum DatabaseStatus { ok, pathNotSet, noResults }

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

  Future<List<Entry>> search(
    String input, [
    int? resultsPerPage = 10,
    int currentPage = 0,
  ]);

  Future<int> count();

  Future<void> setStatus() async {
    if (database == null) {
      status = DatabaseStatus.pathNotSet;
    } else {
      int nbEntries = await count();
      if (nbEntries == 0) {
        status = DatabaseStatus.noResults;
      } else {
        status = DatabaseStatus.ok;
      }
    }
  }
}
