import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KanjiVGSettingsWidget extends StatefulWidget {
  const KanjiVGSettingsWidget({super.key});

  @override
  State<KanjiVGSettingsWidget> createState() => _KanjiVGSettingsWidgetState();
}

class _KanjiVGSettingsWidgetState extends State<KanjiVGSettingsWidget> {
  String downloadLog = '';

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> pathKanjiVG;

  @override
  void initState() {
    super.initState();
    pathKanjiVG = _prefs.then((SharedPreferences prefs) {
      return prefs.getString('kanjivg_path') ?? "";
    });
  }

  Future<void> setPath(String path) async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      pathKanjiVG = prefs.setString('kanjivg_path', path).then((bool success) {
        return path;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: pathKanjiVG,
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '筆',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'KanjiVG',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Path/status section
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
                              'KanjiVG Directory:',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              snapshot.data!.isEmpty
                                  ? 'Please download or select KanjiVG directory'
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
                                        "$appDocPath/kanjivg.zip";
                                    Dio()
                                        .download(
                                          'https://github.com/KanjiVG/kanjivg/releases/download/r20250816/kanjivg-20250816-all.zip',
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
                                          String path = "$appDocPath/kanjivg";

                                          // Extract zip
                                          try {
                                            // Read the Zip file from disk.
                                            final bytes = File(
                                              downloadTo,
                                            ).readAsBytesSync();

                                            // Decode the Zip file
                                            final archive = ZipDecoder()
                                                .decodeBytes(bytes);

                                            // Extract to kanjivg directory
                                            Directory kanjiVgDir = Directory(
                                              path,
                                            );
                                            if (!kanjiVgDir.existsSync()) {
                                              kanjiVgDir.createSync(
                                                recursive: true,
                                              );
                                            }

                                            // Extract all files
                                            for (final file in archive) {
                                              final filename = file.name;
                                              if (file.isFile) {
                                                final data =
                                                    file.content as List<int>;
                                                File('$path/$filename')
                                                  ..createSync(recursive: true)
                                                  ..writeAsBytesSync(data);
                                              } else {
                                                Directory(
                                                  '$path/$filename',
                                                ).createSync(recursive: true);
                                              }
                                            }

                                            // Delete the zip file
                                            File(downloadTo).deleteSync();

                                            // Set path
                                            await setPath(path);
                                            setState(() {
                                              downloadLog = "";
                                            });
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
                                : () => _pickDirectory().then((path) async {
                                    if (path != null) {
                                      await setPath(path);
                                      setState(() {
                                        downloadLog = '';
                                      });
                                    }
                                  }),
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Pick Directory'),
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
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: downloadLog.contains('Error')
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onErrorContainer
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onPrimaryContainer,
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
    );
  }

  Future<String?> _pickDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      return selectedDirectory;
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
    return null;
  }
}
