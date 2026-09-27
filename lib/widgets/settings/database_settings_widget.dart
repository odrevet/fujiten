import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/widgets/database_status_display.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../cubits/expression_cubit.dart';
import '../../cubits/kanji_cubit.dart';
import '../../services/database_interface.dart';

class DatabaseSettingsWidget extends StatefulWidget {
  final String type; // 'kanji' or 'expression'

  const DatabaseSettingsWidget({required this.type, super.key});

  @override
  State<DatabaseSettingsWidget> createState() => _DatabaseSettingsWidgetState();
}

class _DatabaseSettingsWidgetState extends State<DatabaseSettingsWidget> {
  String downloadLog = '';
  DatabaseStatus? _localStatus;
  String _selectedLang = 'eng';

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  late Future<String> pathDb;

  @override
  void initState() {
    super.initState();

    pathDb = _prefs.then((SharedPreferences prefs) {
      _selectedLang = prefs.getString('${widget.type}_lang') ?? 'eng';

      return prefs.getString('${widget.type}_path') ?? '';
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

  Future<void> setLang(String lang) async {
    final SharedPreferences prefs = await _prefs;

    await prefs.setString('${widget.type}_lang', lang);

    setState(() {
      _selectedLang = lang;
    });
  }

  /// Returns the language code used by the database filename.
  ///
  /// Expression databases use ISO-639-2 codes:
  ///   eng, all
  ///
  /// Kanji databases use ISO-639-1 codes:
  ///   en, all
  String _getDatabaseLanguageCode() {
    if (widget.type == 'kanji') {
      switch (_selectedLang) {
        case 'eng':
          return 'en';
        case 'all':
          return 'all';
        default:
          return _selectedLang;
      }
    }

    return _selectedLang;
  }

  dynamic _getCubit(BuildContext context) {
    if (widget.type == 'kanji') {
      return context.read<KanjiCubit>();
    } else {
      return context.read<ExpressionCubit>();
    }
  }

  DatabaseInterface _getDatabaseInterface(BuildContext context) {
    final cubit = _getCubit(context);
    return cubit.databaseInterface;
  }

  void _refreshDatabaseStatus(BuildContext context) {
    final cubit = _getCubit(context);

    if (widget.type == 'kanji') {
      (cubit as KanjiCubit).refreshDatabaseStatus();
    } else {
      (cubit as ExpressionCubit).refreshDatabaseStatus();
    }
  }

  void _updateLocalStatus(DatabaseStatus status) {
    setState(() {
      _localStatus = status;
    });
  }

  Future<void> _downloadDatabase(
    BuildContext context,
    DatabaseInterface databaseInterface,
  ) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();

    final String appDocPath = appDocDir.path;
    final String downloadTo = '$appDocPath/${widget.type}.xz';

    final String lang = _getDatabaseLanguageCode();
    final String fileName = 'sqlite_${widget.type}_$lang';

    _updateLocalStatus(DatabaseStatus.loading);

    try {
      await Dio().download(
        'https://github.com/odrevet/edict_database/releases/latest/download/$fileName.xz',
        downloadTo,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              downloadLog =
                  'Downloading... ${(received / total * 100).toStringAsFixed(0)}%';
            });
          }
        },
      );

      setState(() {
        downloadLog = 'Extracting...';
      });

      final String path = '$appDocPath/${widget.type}.db';

      final bytes = File(downloadTo).readAsBytesSync();
      final decompressed = XZDecoder().decodeBytes(bytes);

      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(decompressed);

      File(downloadTo).deleteSync();

      await setPath(path);
      await databaseInterface.open(path);
      await databaseInterface.setStatus();

      _updateLocalStatus(databaseInterface.status!);

      setState(() {
        downloadLog = '';
      });

      if (context.mounted) {
        _refreshDatabaseStatus(context);
      }
    } catch (e) {
      _updateLocalStatus(DatabaseStatus.error);

      setState(() {
        downloadLog = 'Error ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: pathDb,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const CircularProgressIndicator();

          default:
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final databaseInterface = _getDatabaseInterface(context);

            final displayStatus = _localStatus ?? databaseInterface.status;

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
                    DatabaseStatusItem(
                      title: widget.type == 'kanji' ? 'Kanji' : 'Expression',
                      status: displayStatus,
                      kanjiChar: widget.type == 'kanji' ? '漢' : '言',
                    ),

                    const SizedBox(height: 16),

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
                                ? 'Please download or select a dictionary database'
                                : snapshot.data!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: snapshot.data!.isEmpty
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontStyle: snapshot.data!.isEmpty
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Language:',
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 4),

                    DropdownButton<String>(
                      value: _selectedLang,
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All languages'),
                        ),
                        DropdownMenuItem(value: 'eng', child: Text('English')),
                      ],
                      onChanged: downloadLog.isNotEmpty
                          ? null
                          : (value) {
                              if (value != null) {
                                setLang(value);
                              }
                            },
                    ),

                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: downloadLog.isNotEmpty
                              ? null
                              : () => _downloadDatabase(
                                  context,
                                  databaseInterface,
                                ),
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
                              : () => _pickFile().then((result) async {
                                  if (result != null) {
                                    _updateLocalStatus(DatabaseStatus.loading);

                                    final String path = result.first.path!;

                                    await setPath(path);

                                    await databaseInterface.open(path);

                                    await databaseInterface.setStatus();

                                    _updateLocalStatus(
                                      databaseInterface.status!,
                                    );

                                    setState(() {
                                      downloadLog = '';
                                    });

                                    if (context.mounted) {
                                      _refreshDatabaseStatus(context);
                                    }
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
                                  const String path = '';

                                  await setPath(path);
                                  await databaseInterface.open(path);

                                  _updateLocalStatus(DatabaseStatus.pathNotSet);

                                  setState(() {
                                    downloadLog = '';
                                  });

                                  databaseInterface.status =
                                      DatabaseStatus.pathNotSet;

                                  if (context.mounted) {
                                    _refreshDatabaseStatus(context);
                                  }
                                },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .error,
                          ),
                        ),
                      ],
                    ),

                    if (downloadLog.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: downloadLog.contains('Error')
                              ? Theme.of(context).colorScheme.errorContainer
                              : Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            if (downloadLog.contains('Downloading') ||
                                downloadLog.contains('Extracting'))
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                              ),

                            if (downloadLog.contains('Error') ||
                                downloadLog.contains('failed'))
                              Icon(
                                Icons.error,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                downloadLog,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color:
                                          downloadLog.contains('Error') ||
                                              downloadLog.contains('failed')
                                          ? Theme.of(context)
                                                .colorScheme
                                                .onErrorContainer
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
      },
    );
  }

  Future<List<PlatformFile>?> _pickFile() async {
    try {
      return await FilePicker.pickFiles(type: FileType.any);
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
