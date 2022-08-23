import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/entry.dart';

abstract class DatabaseInterface {
  Database? database;

  DatabaseInterface({this.database});

  Future<void> open(String path) async {
    database = await databaseFactoryFfi.openDatabase(path);
  }

  Future<void> dispose() async {
    database?.close();
  }

  Future<List<Entry>> search(String input, [resultsPerPage = 10, currentPage = 0]);
}
