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

  const DatabaseSettingsWidget({
    required this.type,
    required this.setDb,
    super.key,
  });

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
      pathDb = prefs.setString('${widget.type}_path', path).then((
        bool success,
      ) {
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
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (downloadLog == '') {
          Navigator.pop(context);
        } else {
          final bool shouldPop = await _displayCancelDownloadDialog();
          if (context.mounted && shouldPop) {
            Navigator.pop(context);
          }
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
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with database type
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  widget.type == 'expression' ? '言' : '漢',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${widget.type.substring(0, 1).toUpperCase()}${widget.type.substring(1)} Database',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Database path/status section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Database Path:',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                snapshot.data!.isEmpty
                                    ? 'No database selected'
                                    : snapshot.data!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: snapshot.data!.isEmpty
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      fontStyle: snapshot.data!.isEmpty
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Action buttons
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: downloadLog.isNotEmpty
                                  ? null
                                  : () async {
                                      Directory appDocDir =
                                          await getApplicationDocumentsDirectory();
                                      String appDocPath = appDocDir.path;
                                      String downloadTo =
                                          "$appDocPath/${widget.type}.db";
                                      Dio()
                                          .download(
                                            "https://github.com/odrevet/edict_database/releases/latest/download/${widget.type}.zip",
                                            downloadTo,
                                            onReceiveProgress: (received, total) {
                                              if (total != -1) {
                                                setState(
                                                  () => downloadLog =
                                                      ("Downloading... ${(received / total * 100).toStringAsFixed(0)}%"),
                                                );
                                              }
                                            },
                                          )
                                          .then((_) async {
                                            String path =
                                                "$appDocPath/${widget.type}.db";

                                            // Extract zip
                                            try {
                                              // Read the Zip file from disk.
                                              final bytes = File(
                                                downloadTo,
                                              ).readAsBytesSync();

                                              // Decode the Zip file
                                              final archive = ZipDecoder()
                                                  .decodeBytes(bytes);

                                              // Extract the contents of the Zip archive to disk.
                                              for (final file in archive) {
                                                final data =
                                                    file.content as List<int>;
                                                File(
                                                    '$appDocPath/${widget.type}.db',
                                                  )
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
                                              setState(
                                                () => downloadLog =
                                                    "Error ${e.toString()}",
                                              );
                                            }
                                          });
                                    },
                              icon: const Icon(Icons.download),
                              label: const Text('Download'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
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
                              icon: const Icon(Icons.folder_open),
                              label: const Text('Pick File'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: snapshot.data == ''
                                  ? null
                                  : () async {
                                      String path = '';
                                      setPath(path);
                                      await widget.setDb(path);
                                      setState(() {
                                        downloadLog = '';
                                      });
                                    },
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                            ),
                          ],
                        ),

                        // Progress/status message
                        if (downloadLog.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: downloadLog.contains('Error')
                                  ? Theme.of(context).colorScheme.errorContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                if (downloadLog.contains('Downloading'))
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                if (downloadLog.contains('Error'))
                                  Icon(
                                    Icons.error,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    downloadLog,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: downloadLog.contains('Error')
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.onErrorContainer
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                          fontWeight: FontWeight.normal,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }
          }
        },
      ),
    );
  }

  Future<List<PlatformFile>?> _pickFiles() async {
    try {
      return (await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      ))?.files;
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
