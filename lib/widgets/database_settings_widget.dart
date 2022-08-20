import 'dart:io';

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
                  Dio().download(
                      "https://github.com/odrevet/edict_database/releases/download/v0.0.1/${widget.type}.db",
                      "$appDocPath/expression.db", onReceiveProgress: (received, total) {
                    if (total != -1) {
                      setState(() {
                        downloadLog = ("${(received / total * 100).toStringAsFixed(0)}%");
                      });
                    }
                  }).then((response) async {
                    String path = "$appDocPath/${widget.type}.db";
                    widget.setPath(path);
                    await widget.setDb(path);
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
