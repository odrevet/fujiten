import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/entry.dart';

enum DatabaseStatus { ok, pathNotSet, noResults }


abstract class DatabaseInterface {
  Database? database;
  DatabaseStatus? status;
  String? log;
  static bool useRegexp = false;

  DatabaseInterface({this.database});

  Future<void> open(String path) async {
    try {
      if (const bool.fromEnvironment('FFI', defaultValue: true)) {
        database = await databaseFactoryFfi.openDatabase(path);
      } else {
        database = await openDatabase(path, readOnly: true);
      }
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
    String input,
    int resultsPerPage,
    int currentPage,
    bool useRegexp
  );

  Future<int> count();

  Future<void> setStatus() async {
    if (database == null) {
      status = DatabaseStatus.pathNotSet;
      log = 'No services selected';
    } else {
      int nbEntries = await count();
      if (nbEntries == 0) {
        status = DatabaseStatus.noResults;
        log = 'No entry found in services';
      } else {
        status = DatabaseStatus.ok;
        log = 'Database loaded';
      }
    }
  }
}
