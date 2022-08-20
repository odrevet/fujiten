import 'dart:developer';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseSettingsWidget extends StatefulWidget {
  final String type;
  final String path;
  final Function setPath;
  final Function setDb;

  const DatabaseSettingsWidget(
      {required this.type,
      required this.path,
      required this.setPath,
      required this.setDb,
      Key? key})
      : super(key: key);

  @override
  State<DatabaseSettingsWidget> createState() => _DatabaseSettingsWidgetState();
}

class _DatabaseSettingsWidgetState extends State<DatabaseSettingsWidget> {
  String downloadLog = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(widget.type),
          Text(widget.path),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  Directory appDocDir = await getApplicationDocumentsDirectory();
                  String appDocPath = appDocDir.path;
                  String downloadTo = "$appDocPath/${widget.type}.db";
                  Dio().download(
                      "https://github.com/odrevet/edict_database/releases/download/v0.0.1/${widget.type}.zip",
                      downloadTo, onReceiveProgress: (received, total) {
                    if (total != -1) {
                      setState(() => downloadLog =
                          ("Downloading... ${(received / total * 100).toStringAsFixed(0)}%"));
                    }
                  }).then((_) async {
                    String path = "$appDocPath/${widget.type}.db";

                    // Extract zip
                    try {
                      // Read the Zip file from disk.
                      final bytes = File(downloadTo).readAsBytesSync();

                      // Decode the Zip file
                      final archive = ZipDecoder().decodeBytes(bytes);

                      // Extract the contents of the Zip archive to disk.
                      for (final file in archive) {
                        final data = file.content as List<int>;
                        File('$appDocPath/${widget.type}.db')
                          ..createSync(recursive: true)
                          ..writeAsBytesSync(data);
                      }

                      // Set DB Path and open the Database
                      widget.setPath(path);
                      log("SET DB $path");
                      await widget.setDb(path);
                    } catch (e) {
                      setState(() => downloadLog = "Error ${e.toString()}");
                    }
                  });
                },
                child: const Text('Download'),
              ),
              ElevatedButton(
                onPressed: () => _pickFiles().then((result) async {
                  if (result != null) {
                    String path = result.first.path!;
                    widget.setPath(path);
                    await widget.setDb(path);
                  }
                }),
                child: const Text('Pick file'),
              )
            ],
          ),
          Text(downloadLog)
        ],
      ),
    );
  }

  Future<List<PlatformFile>?> _pickFiles() async {
    try {
      return (await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false))?.files;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Unsupported operation $e');
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
    return null;
  }
}
