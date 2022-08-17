import 'package:sqflite/sqflite.dart';

import '../models/entry.dart';

abstract class DatabaseInterface {
  Database? database;

  DatabaseInterface({this.database});

  Future<void> open(String path) async {
    database = await openDatabase(path, readOnly: true);
  }

  Future<void> dispose() async {
    database?.close();
  }

  Future<List<Entry>> search(String input, [resultsPerPage = 10, currentPage = 0]);
}
