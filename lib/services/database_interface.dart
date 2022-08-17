import 'package:sqflite/sqflite.dart';

import '../models/entry.dart';

abstract class DatabaseInterface {
  Database? database;

  DatabaseInterface({required this.database});

  Future<List<Entry>> search(String input, [resultsPerPage = 10, currentPage = 0]);
}
