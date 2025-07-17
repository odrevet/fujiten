import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseSettingsWidget extends StatefulWidget {
  final String type;
  final Function setDb;

  const DatabaseSettingsWidget(
      {required this.type, required this.setDb, super.key});

  @override
  State<DatabaseSettingsWidget> createState() => _DatabaseSettingsWidgetState();
}

class _DatabaseSettingsWidgetState extends State<DatabaseSettingsWidget> {
  String downloadLog = '';

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> pathDb;

  @override
  void initState() {
    super.initState();
    pathDb = _prefs.then((SharedPreferences prefs) {
      return prefs.getString('${widget.type}_path') ?? "";
    });
  }

  Future<void> setPath(String path) async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      pathDb =
          prefs.setString('${widget.type}_path', path).then((bool success) {
        return path;
      });
    });
  }

  Future<bool> _displayCancelDownloadDialog() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Exit will cancel the download'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return
      PopScope<Object?>(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) {
              return;
            }

            final bool shouldPop = downloadLog.isEmpty;
            if (context.mounted && shouldPop) {
              Navigator.pop(context);
            }
            else{
              _displayCancelDownloadDialog();
            }
          },
        child: FutureBuilder<String>(
            future: pathDb,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return const CircularProgressIndicator();
                default:
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return Card(
                      child: Column(
                        children: [
                          Text(widget.type),
                          Text(snapshot.data!),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: downloadLog.isNotEmpty
                                    ? null
                                    : () async {
                                  Directory appDocDir =
                                  await getApplicationDocumentsDirectory();
                                  String appDocPath = appDocDir.path;
                                  String downloadTo =
                                      "$appDocPath/${widget.type}.db";
                                  Dio().download(
                                      "https://github.com/odrevet/edict_database/releases/latest/download/${widget.type}.zip",
                                      downloadTo,
                                      onReceiveProgress: (received, total) {
                                        if (total != -1) {
                                          setState(() => downloadLog =
                                          ("Downloading... ${(received / total * 100).toStringAsFixed(0)}%"));
                                        }
                                      }).then((_) async {
                                    String path =
                                        "$appDocPath/${widget.type}.db";

                                    // Extract zip
                                    try {
                                      // Read the Zip file from disk.
                                      final bytes = File(downloadTo)
                                          .readAsBytesSync();

                                      // Decode the Zip file
                                      final archive =
                                      ZipDecoder().decodeBytes(bytes);

                                      // Extract the contents of the Zip archive to disk.
                                      for (final file in archive) {
                                        final data =
                                        file.content as List<int>;
                                        File(
                                            '$appDocPath/${widget.type}.db')
                                          ..createSync(recursive: true)
                                          ..writeAsBytesSync(data);
                                      }

                                      // Set DB Path and open the Database
                                      setPath(path);
                                      setState(() {
                                        downloadLog = "";
                                      });
                                      await widget.setDb(path);
                                    } catch (e) {
                                      setState(() => downloadLog =
                                      "Error ${e.toString()}");
                                    }
                                  });
                                },
                                child: const Text('Download'),
                              ),
                              ElevatedButton(
                                onPressed: downloadLog.isNotEmpty
                                    ? null
                                    : () => _pickFiles().then((result) async {
                                  if (result != null) {
                                    String path = result.first.path!;
                                    setPath(path);
                                    await widget.setDb(path);
                                    setState(() {
                                      downloadLog = '';
                                    });
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
              }
            }));
  }

  Future<List<PlatformFile>?> _pickFiles() async {
    try {
      return (await FilePicker.platform
              .pickFiles(type: FileType.any, allowMultiple: false))
          ?.files;
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
