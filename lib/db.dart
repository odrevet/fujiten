import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<Database> attachDb(Database db, String dbName, String alias) async {
  String databasesPath = await getDatabasesPath();
  String path = join(databasesPath, dbName);
  await db.rawQuery("ATTACH DATABASE '$path' as '$alias'");
  return db;
}

Future<Database> detachDb(Database db, String alias) async {
  await db.rawQuery("DETACH DATABASE '$alias'");
  return db;
}

Future<Database> openDb(String dbName) async {
  String databasesPath = await getDatabasesPath();
  String path = join(databasesPath, dbName);
  return openDatabase(path, readOnly: true);
}
