import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/config.dart';
import 'package:fujiten/services/sqlite_ops.dart';
import 'package:fujiten/widgets/database_status_display.dart';
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
  DatabaseBackend _backend = DatabaseBackend.sqlite;
  String _postgresUrl = '';
  String _postgresAnonKey = '';
  bool _obscureKey = true;

  late final TextEditingController _urlController;
  late final TextEditingController _anonKeyController;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  late Future<String> pathDb;

  @override
  void initState() {
    super.initState();

    _urlController = TextEditingController();
    _anonKeyController = TextEditingController();

    pathDb = _prefs.then((SharedPreferences prefs) {
      _selectedLang = prefs.getString('${widget.type}_lang') ?? 'eng';
      _backend = kIsWeb
          ? DatabaseBackend.postgres
          : prefs.getString('${widget.type}_backend') == 'postgres'
          ? DatabaseBackend.postgres
          : DatabaseBackend.sqlite;
      _postgresUrl = prefs.getString('postgres_url') ?? SupabaseConfig.url;
      _postgresAnonKey =
          prefs.getString('postgres_anon_key') ?? SupabaseConfig.anonKey;
      _urlController.text = _postgresUrl;
      _anonKeyController.text = _postgresAnonKey;

      return prefs.getString('${widget.type}_path') ?? '';
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _anonKeyController.dispose();
    super.dispose();
  }

  Future<void> setPath(String path) async {
    final SharedPreferences prefs = await _prefs;

    setState(() {
      pathDb = prefs.setString('${widget.type}_path', path).then(
            (bool success) {
          return path;
        },
      );
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

  void _refreshDatabaseStatus() {
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

  Future<void> _onBackendChanged(DatabaseBackend backend) async {
    // On web only the Postgres backend is available.
    if (kIsWeb && backend == DatabaseBackend.sqlite) return;

    final prefs = await _prefs;

    setState(() {
      _backend = backend;
    });

    await prefs.setString('${widget.type}_backend', backend.name);

    if (backend == DatabaseBackend.postgres) {
      _updateLocalStatus(DatabaseStatus.pathNotSet);
      setState(() {
        downloadLog = '';
      });
    } else {
      final path = prefs.getString('${widget.type}_path') ?? '';
      if (!mounted) return;
      final cubit = _getCubit(context);
      if (path.isNotEmpty) {
        await cubit.configure(DatabaseBackend.sqlite, path: path);
        _updateLocalStatus(cubit.databaseInterface.status!);
      } else {
        await cubit.configure(DatabaseBackend.sqlite);
        _updateLocalStatus(DatabaseStatus.pathNotSet);
      }
      setState(() {
        downloadLog = '';
      });
      if (mounted) {
        _refreshDatabaseStatus();
      }
    }
  }

  Future<void> _connectPostgres() async {
    final prefs = await _prefs;
    final url = _urlController.text.trim();
    final anonKey = _anonKeyController.text.trim();

    if (url.isEmpty || anonKey.isEmpty) {
      _updateLocalStatus(DatabaseStatus.error);
      setState(() {
        downloadLog = 'Please enter the Postgres URL and anon key';
      });
      return;
    }

    await prefs.setString('postgres_url', url);
    await prefs.setString('postgres_anon_key', anonKey);
    await prefs.setString('${widget.type}_backend', 'postgres');

    _updateLocalStatus(DatabaseStatus.loading);

    if (!mounted) return;
    final cubit = _getCubit(context);
    await cubit.configure(
      DatabaseBackend.postgres,
      url: url,
      anonKey: anonKey,
    );

    _updateLocalStatus(cubit.databaseInterface.status!);

    setState(() {
      downloadLog = '';
    });

    if (mounted) {
      _refreshDatabaseStatus();
    }
  }

  Future<void> _downloadDatabase(
      BuildContext context,
      DatabaseInterface databaseInterface,
      ) async {
    final String lang = _getDatabaseLanguageCode();

    _updateLocalStatus(DatabaseStatus.loading);

    try {
      final String path = await downloadAndExtractSqlite(
        type: widget.type,
        lang: lang,
        onProgress: (msg) {
          setState(() {
            downloadLog = msg;
          });
        },
      );

      await setPath(path);
      await databaseInterface.open(path);
      await databaseInterface.setStatus();

      _updateLocalStatus(databaseInterface.status!);

      setState(() {
        downloadLog = '';
      });

      if (context.mounted) {
        _refreshDatabaseStatus();
      }
    } catch (e) {
      _updateLocalStatus(DatabaseStatus.error);

      setState(() {
        downloadLog = 'Error ${e.toString()}';
      });
    }
  }

  Future<void> _pickFile(DatabaseInterface databaseInterface) async {
    final String? path = await pickSqliteFile();
    if (path == null) return;

    _updateLocalStatus(DatabaseStatus.loading);

    await setPath(path);
    await databaseInterface.open(path);
    await databaseInterface.setStatus();

    _updateLocalStatus(databaseInterface.status!);

    setState(() {
      downloadLog = '';
    });

    if (mounted) {
      _refreshDatabaseStatus();
    }
  }

  Future<void> _clearPath(DatabaseInterface databaseInterface) async {
    const String path = '';

    await setPath(path);
    await databaseInterface.open(path);

    _updateLocalStatus(DatabaseStatus.pathNotSet);

    setState(() {
      downloadLog = '';
    });

    databaseInterface.status = DatabaseStatus.pathNotSet;

    if (mounted) {
      _refreshDatabaseStatus();
    }
  }

  Widget _buildPostgresSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _urlController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Supabase URL',
            hintText: 'https://xxxx.supabase.co',
            prefixIcon: Icon(Icons.link),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _anonKeyController,
          obscureText: _obscureKey,
          decoration: InputDecoration(
            labelText: 'Anon / Publishable key',
            prefixIcon: const Icon(Icons.key),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureKey ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () => setState(() => _obscureKey = !_obscureKey),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: downloadLog.isNotEmpty ? null : _connectPostgres,
            icon: const Icon(Icons.cloud_done),
            label: const Text('Connect'),
          ),
        ),
      ],
    );
  }

  Widget _buildSqliteSection(
      BuildContext context,
      AsyncSnapshot<String> snapshot,
      DatabaseInterface databaseInterface,
      ) {
    final theme = Theme.of(context);
    final bool isEmpty = snapshot.data!.isEmpty;
    final bool busy = downloadLog.isNotEmpty;

    final ButtonStyle buttonStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      visualDensity: VisualDensity.compact,
    );

    final ButtonStyle clearStyle = buttonStyle.copyWith(
      foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
            ? null
            : theme.colorScheme.error,
      ),
    );

    Widget buttonLabel(String text) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, maxLines: 1),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isEmpty ? Icons.folder_off_outlined : Icons.folder_outlined,
                color: isEmpty
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Database path', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 2),
                    Text(
                      isEmpty
                          ? 'Please download or select a dictionary database'
                          : snapshot.data!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isEmpty
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface,
                        fontStyle:
                        isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedLang,
          decoration: const InputDecoration(
            labelText: 'Language',
            prefixIcon: Icon(Icons.translate),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All languages')),
            DropdownMenuItem(value: 'eng', child: Text('English')),
          ],
          onChanged: busy
              ? null
              : (value) {
            if (value != null) {
              setLang(value);
            }
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed:
                isEmpty || busy ? null : () => _clearPath(databaseInterface),
                icon: const Icon(Icons.clear, size: 18),
                label: buttonLabel('Clear'),
                style: clearStyle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: busy ? null : () => _pickFile(databaseInterface),
                icon: const Icon(Icons.folder_open, size: 18),
                label: buttonLabel('Pick File'),
                style: buttonStyle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: busy
                    ? null
                    : () => _downloadDatabase(context, databaseInterface),
                icon: const Icon(Icons.download, size: 18),
                label: buttonLabel('Download'),
                style: buttonStyle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLog(BuildContext context) {
    final theme = Theme.of(context);
    final bool isError =
        downloadLog.contains('Error') || downloadLog.contains('failed');
    final bool isBusy =
        downloadLog.contains('Downloading') ||
            downloadLog.contains('Extracting');

    final Color foreground = isError
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onPrimaryContainer;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (isBusy)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(foreground),
              ),
            ),
          if (isError) Icon(Icons.error, size: 16, color: foreground),
          if (isBusy || isError) const SizedBox(width: 8),
          Expanded(
            child: Text(
              downloadLog,
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: pathDb,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const Center(child: CircularProgressIndicator());

          default:
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final databaseInterface = _getDatabaseInterface(context);
            final displayStatus = _localStatus ?? databaseInterface.status;
            final colorScheme = Theme.of(context).colorScheme;

            return Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DatabaseStatusItem(
                      title: widget.type == 'kanji' ? 'Kanji' : 'Expression',
                      status: displayStatus,
                      kanjiChar: widget.type == 'kanji' ? '漢' : '言',
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<DatabaseBackend>(
                      expandedInsets: EdgeInsets.zero,
                      showSelectedIcon: false,
                      segments: [
                        if (!kIsWeb)
                          const ButtonSegment(
                            value: DatabaseBackend.sqlite,
                            label: Text('Local SQLite'),
                            icon: Icon(Icons.storage),
                          ),
                        const ButtonSegment(
                          value: DatabaseBackend.postgres,
                          label: Text('Postgres'),
                          icon: Icon(Icons.cloud),
                        ),
                      ],
                      selected: {_backend},
                      onSelectionChanged: (s) => _onBackendChanged(s.first),
                    ),
                    const SizedBox(height: 20),
                    if (_backend == DatabaseBackend.postgres)
                      _buildPostgresSection(context)
                    else
                      _buildSqliteSection(context, snapshot, databaseInterface),
                    if (downloadLog.isNotEmpty) _buildLog(context),
                  ],
                ),
              ),
            );
        }
      },
    );
  }
}