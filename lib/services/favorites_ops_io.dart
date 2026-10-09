import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Exports [json] to a user-chosen file.
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
    final file = files.first;
    if (file.path != null) {
      return await File(file.path!).readAsString();
    }
    return utf8.decode(await file.readAsBytes());
  } catch (_) {
    return null;
  }
}
