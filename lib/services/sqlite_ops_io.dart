import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads and extracts the sqlite dictionary database for [type]
/// ('expression' or 'kanji') in the given [lang], returning the path to the
/// extracted `.db` file. [onProgress] is called with human readable progress.
Future<String> downloadAndExtractSqlite({
  required String type,
  required String lang,
  required void Function(String) onProgress,
}) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final appDocPath = appDocDir.path;
  final downloadTo = '$appDocPath/$type.xz';
  final fileName = 'sqlite_${type}_$lang';

  await Dio().download(
    'https://github.com/odrevet/edict_database/releases/latest/download/$fileName.xz',
    downloadTo,
    onReceiveProgress: (received, total) {
      if (total != -1) {
        onProgress(
          'Downloading... ${(received / total * 100).toStringAsFixed(0)}%',
        );
      }
    },
  );

  onProgress('Extracting...');

  final path = '$appDocPath/$type.db';
  final bytes = File(downloadTo).readAsBytesSync();
  final decompressed = XZDecoder().decodeBytes(bytes);

  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(decompressed);

  File(downloadTo).deleteSync();

  return path;
}

/// Lets the user pick a sqlite database file, returning its path or null.
Future<String?> pickSqliteFile() async {
  try {
    final result = await FilePicker.pickFiles(type: FileType.any);
    return result.isEmpty ? null : result.first.path;
  } catch (_) {
    return null;
  }
}
