import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads and extracts the KanjiVG archive, returning the directory path.
/// [onProgress] is called with human readable progress.
Future<String> downloadAndExtractKanjivg({
  required void Function(String) onProgress,
}) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final appDocPath = appDocDir.path;
  final downloadTo = '$appDocPath/kanjivg.zip';

  await Dio().download(
    'https://github.com/KanjiVG/kanjivg/releases/download/r20250816/kanjivg-20250816-all.zip',
    downloadTo,
    onReceiveProgress: (received, total) {
      if (total != -1) {
        onProgress(
          'Downloading... ${(received / total * 100).toStringAsFixed(0)}%',
        );
      }
    },
  );

  final path = '$appDocPath/kanjivg';

  final bytes = File(downloadTo).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  final kanjiVgDir = Directory(path);
  if (!kanjiVgDir.existsSync()) {
    kanjiVgDir.createSync(recursive: true);
  }

  for (final file in archive) {
    final filename = file.name;
    if (file.isFile) {
      final data = file.content as List<int>;
      File('$path/$filename')
        ..createSync(recursive: true)
        ..writeAsBytesSync(data);
    } else {
      Directory('$path/$filename').createSync(recursive: true);
    }
  }

  File(downloadTo).deleteSync();

  return path;
}

/// Lets the user pick a KanjiVG directory, returning its path or null.
Future<String?> pickKanjivgDirectory() async {
  try {
    return await FilePicker.getDirectoryPath();
  } catch (_) {
    return null;
  }
}

/// Reads the SVG source for the given [codepoint] from [kanjivgPath],
/// or null if it does not exist.
Future<String?> readKanjivgSvg(String kanjivgPath, String codepoint) async {
  final svgFile = File('$kanjivgPath/kanji/$codepoint.svg');
  if (!await svgFile.exists()) return null;
  return svgFile.readAsString();
}
