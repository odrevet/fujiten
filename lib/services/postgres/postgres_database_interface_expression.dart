import 'dart:developer';

import '../../models/entry.dart';
import '../../models/sense.dart';
import '../../models/states/search_options_state.dart';
import '../../string_utils.dart';
import '../database_interface.dart';
import '../database_interface_expression.dart';
import 'postgres_client.dart';

/// Postgres backend for expression search.
///
/// Only POSIX regular expressions are supported (PostgREST `match`
/// operator). The input is always interpreted as a regexp and filtered
/// and paginated by Postgres. GLOB is not supported. Raw searches are
/// filtered client-side (no `like`/`ilike`).
class PostgresDatabaseInterfaceExpression extends DatabaseInterfaceExpression {
  final String url;
  final String anonKey;

  PostgresClient? _client;
  bool _connected = false;

  PostgresDatabaseInterfaceExpression({
    required this.url,
    required this.anonKey,
  });

  @override
  DatabaseBackend get backend => DatabaseBackend.postgres;

  @override
  bool get isOpen => _connected;

  PostgresClient get _c => _client!;

  @override
  Future<void> open(String path) async {
    _client = PostgresClient(url: url, anonKey: anonKey, schema: 'expression');
    try {
      _connected = await _client!.testConnection('entry');
      if (!_connected) {
        status = DatabaseStatus.noResults;
        logMessage = 'Could not connect to Postgres';
      }
    } catch (e) {
      _connected = false;
      status = DatabaseStatus.noResults;
      logMessage = e.toString();
    }
  }

  @override
  Future<void> dispose() async {
    _client?.dispose();
    _client = null;
    _connected = false;
  }

  Future<List<int>> _findEntryIdsRaw(
      String input,
      int resultsPerPage,
      int currentPage,
      List<String> langs,
      ) async {
    final isRomaji = kanaKit.isRomaji(input);
    final hasKanji = RegExp(matchKanji).hasMatch(input);
    final ids = <int>{};

    if (isRomaji) {
      final glossParams = <String, dynamic>{
        'select': 'id_sense,content,lang(iso3)',
        'limit': 50000,
      };
      if (langs.isNotEmpty) {
        glossParams['lang.iso3'] = 'in.(${langs.join(',')})';
      }
      final glossRows = await _c.query('gloss', glossParams);
      final senseIds = glossRows
          .where((r) => (r['content'] as String? ?? '').contains(input))
          .map((r) => r['id_sense'] as int)
          .toSet()
          .toList();
      if (senseIds.isEmpty) return [];
      final senseRows = await _c.query('sense', {
        'select': 'id_entry',
        'id': 'in.(${senseIds.join(',')})',
      });
      ids.addAll(senseRows.map((r) => r['id_entry'] as int));
    } else {
      if (!hasKanji) {
        final rRows = await _c.query('r_ele', {
          'select': 'id_entry,reb',
          'limit': 50000,
        });
        ids.addAll(
          rRows
              .where((r) => (r['reb'] as String? ?? '').contains(input))
              .map((r) => r['id_entry'] as int),
        );
      }
      final kRows = await _c.query('k_ele', {
        'select': 'id_entry,keb',
        'limit': 50000,
      });
      ids.addAll(
        kRows
            .where((r) => (r['keb'] as String? ?? '').contains(input))
            .map((r) => r['id_entry'] as int),
      );
    }

    final allIds = ids.toList();
    final start = currentPage * resultsPerPage;
    if (start >= allIds.length) return [];
    final end = (start + resultsPerPage).clamp(0, allIds.length);
    return allIds.sublist(start, end);
  }

  Future<List<int>> _findEntryIds(
      String input,
      int resultsPerPage,
      int currentPage,
      List<String> langs,
      ) async {
    final isRomaji = kanaKit.isRomaji(input);
    final hasKanji = RegExp(matchKanji).hasMatch(input);

    final filter = 'match.$input';
    final limit = resultsPerPage;
    final offset = currentPage * resultsPerPage;

    if (isRomaji) {
      final glossParams = <String, dynamic>{
        'select': 'id_sense,lang(iso3)',
        'content': filter,
        'order': 'id_sense',
        'limit': limit,
        'offset': offset,
      };
      if (langs.isNotEmpty) {
        glossParams['lang.iso3'] = 'in.(${langs.join(',')})';
      }
      final glossRows = await _c.query('gloss', glossParams);
      final senseIds = glossRows
          .map((r) => r['id_sense'] as int)
          .toSet()
          .toList();
      if (senseIds.isEmpty) return [];
      final senseRows = await _c.query('sense', {
        'select': 'id_entry',
        'id': 'in.(${senseIds.join(',')})',
      });
      return senseRows.map((r) => r['id_entry'] as int).toSet().toList();
    }

    final ids = <int>{};
    if (!hasKanji) {
      final rRows = await _c.query('r_ele', {
        'select': 'id_entry',
        'reb': filter,
        'order': 'id_entry',
        'limit': limit,
        'offset': offset,
      });
      ids.addAll(rRows.map((r) => r['id_entry'] as int));
    }
    final kRows = await _c.query('k_ele', {
      'select': 'id_entry',
      'keb': filter,
      'order': 'id_entry',
      'limit': limit,
      'offset': offset,
    });
    ids.addAll(kRows.map((r) => r['id_entry'] as int));
    return ids.toList();
  }

  Future<List<ExpressionEntry>> _fetchEntries(
      List<int> entryIds,
      List<String> langs,
      ) async {
    final entries = <ExpressionEntry>[];
    final idToEntry = <int, ExpressionEntry>{};

    for (var i = 0; i < entryIds.length; i += 100) {
      final chunk = entryIds.sublist(
        i,
        (i + 100).clamp(0, entryIds.length),
      );
      final rows = await _c.query('entry', {
        'select':
        'id,r_ele(reb),k_ele(keb),sense(id,gloss(content,lang(iso3)),pos(name),dial(name),misc(name),field(name),sense_xref(keb,reb),sense_ant(keb,reb))',
        'id': 'in.(${chunk.join(',')})',
      });

      for (final row in rows) {
        final entryId = row['id'] as int;
        final rEle = (row['r_ele'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
        final kEle = (row['k_ele'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
        final senseRows =
            (row['sense'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        final readings = <String>{};
        for (final r in rEle) {
          final reb = r['reb'] as String?;
          if (reb != null) readings.add(reb);
        }
        for (final k in kEle) {
          final keb = k['keb'] as String?;
          if (keb == null) continue;
          for (final r in rEle) {
            final reb = r['reb'] as String?;
            if (reb != null) readings.add('$keb:$reb');
          }
        }

        final xref = <String>{};
        final ant = <String>{};
        final senses = <Sense>[];

        for (final s in senseRows) {
          final glosses = <Gloss>[];
          final glossRows =
              (s['gloss'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          for (final g in glossRows) {
            final content = g['content'] as String?;
            if (content == null) continue;
            final lang =
                (g['lang'] as Map?)?.cast<String, dynamic>()['iso3'] as String? ??
                    '';
            if (langs.isNotEmpty && !langs.contains(lang)) continue;
            glosses.add(Gloss(content: content, lang: lang));
          }

          final posses = (s['pos'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map((p) => p['name'] as String)
              .toList() ??
              [];
          final dial = (s['dial'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map((p) => p['name'] as String)
              .toList() ??
              [];
          final misc = (s['misc'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map((p) => p['name'] as String)
              .toList() ??
              [];
          final fields = (s['field'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map((p) => p['name'] as String)
              .toList() ??
              [];

          senses.add(
            Sense(
              glosses: glosses,
              posses: posses,
              dial: dial,
              misc: misc,
              fields: fields,
            ),
          );

          for (final x
          in (s['sense_xref'] as List?)?.cast<Map<String, dynamic>>() ??
              []) {
            final keb = x['keb'] as String?;
            final reb = x['reb'] as String?;
            if (reb != null) {
              xref.add('${keb ?? ''}:$reb');
            } else if (keb != null) {
              xref.add(keb);
            }
          }
          for (final a
          in (s['sense_ant'] as List?)?.cast<Map<String, dynamic>>() ??
              []) {
            final keb = a['keb'] as String?;
            final reb = a['reb'] as String?;
            if (reb != null) {
              ant.add('${keb ?? ''}:$reb');
            } else if (keb != null) {
              ant.add(keb);
            }
          }
        }

        idToEntry[entryId] = ExpressionEntry(
          reading: readings.toList(),
          senses: senses,
          xref: xref.toList(),
          ant: ant.toList(),
        );
      }
    }

    for (final id in entryIds) {
      final entry = idToEntry[id];
      if (entry != null) entries.add(entry);
    }
    return entries;
  }

  /// [mode] selects the search strategy. Regexp uses the PostgREST
  /// `match` operator; raw is filtered client-side; glob is unsupported.
  @override
  Future<List<ExpressionEntry>> search(
      String input,
      int resultsPerPage,
      int currentPage,
      SearchMode mode,
      List<String> langs,
      ) async {
    try {
      final entryIds = mode == SearchMode.raw
          ? await _findEntryIdsRaw(input, resultsPerPage, currentPage, langs)
          : await _findEntryIds(input, resultsPerPage, currentPage, langs);
      if (entryIds.isEmpty) return [];
      return await _fetchEntries(entryIds, langs);
    } catch (e) {
      log('search expression postgres: $e');
      return [];
    }
  }

  @override
  Future<List<String>> getAvailableLangs() async {
    try {
      final rows = await _c.query('lang', {'select': 'iso3', 'order': 'id'});
      return rows.map((r) => r['iso3'] as String).toList();
    } catch (e) {
      log('getAvailableLangs expression postgres: $e');
      return [];
    }
  }

  @override
  Future<int> count() async {
    try {
      return await _c.count('entry', {'select': 'id'});
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<bool> isRegexpAvailable() async => true;

  @override
  Future<bool> isGlobAvailable() async => false;
}