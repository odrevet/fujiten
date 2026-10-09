import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fujiten/services/kanjivg_ops.dart';
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
    if (kIsWeb) {
      return Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('KanjiVG is not supported on web'),
              ),
            ],
          ),
        ),
      );
    }

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
                                    try {
                                      final String path =
                                          await downloadAndExtractKanjivg(
                                        onProgress: (msg) {
                                          setState(() {
                                            downloadLog = msg;
                                          });
                                        },
                                      );
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
                                : () async {
                                    final String? path =
                                        await pickKanjivgDirectory();
                                    if (path != null) {
                                      await setPath(path);
                                      setState(() {
                                        downloadLog = '';
                                      });
                                    }
                                  },
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
}
