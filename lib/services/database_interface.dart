import 'package:sqflite/sqflite.dart';

import '../models/entry.dart';

enum DatabaseStatus { ok, pathNotSet, noResults }

abstract class DatabaseInterface {
  Database? database;
  DatabaseStatus? status;
  String? log;

  DatabaseInterface({this.database});

  Future<void> open(String path) async {
    try {
      database = await openDatabase(path, readOnly: true);
    } catch (e) {
      database = null;
      status = DatabaseStatus.noResults;
      log = e.toString();
    }
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
      log = 'No database selected';
    } else {
      int nbEntries = await count();
      if (nbEntries == 0) {
        status = DatabaseStatus.noResults;
        log = 'No entry found in database';
      } else {
        status = DatabaseStatus.ok;
        log = 'Database loaded';
      }
    }
  }
}
