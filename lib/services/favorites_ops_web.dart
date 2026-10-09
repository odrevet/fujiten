import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Exports [json] by triggering a browser download.
Future<void> exportFavorites(String json) async {
  await FilePicker.saveFile(
    dialogTitle: 'Export favorites',
    fileName: 'favorites.json',
    type: FileType.custom,
    allowedExtensions: ['json'],
    bytes: Uint8List.fromList(utf8.encode(json)),
  );
}

/// Lets the user pick a favorites JSON file and returns its contents,
/// or null if cancelled.
Future<String?> importFavorites() async {
  try {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (files.isEmpty) return null;
    return utf8.decode(await files.first.readAsBytes());
  } catch (_) {
    return null;
  }
}
