import 'dart:developer';

import '../../models/entry.dart';
import '../../models/kanji.dart';
import '../../models/states/search_options_state.dart';
import '../../string_utils.dart';
import '../database_interface.dart';
import '../database_interface_kanji.dart';
import 'postgres_client.dart';

/// Postgres backend for kanji search.
///
/// Only POSIX regular expressions are supported (PostgREST `match`
/// operator). The input is always interpreted as a regexp. GLOB is not
/// supported. Raw searches are filtered client-side (no `like`/`ilike`).
class PostgresDatabaseInterfaceKanji extends DatabaseInterfaceKanji {
  final String url;
  final String anonKey;

  PostgresClient? _client;
  bool _connected = false;

  PostgresDatabaseInterfaceKanji({
    required this.url,
    required this.anonKey,
  });

  @override
  DatabaseBackend get backend => DatabaseBackend.postgres;

  @override
  bool get isOpen => _connected;

  PostgresClient get _c => _client!;

  static const _characterSelect =
      'id,stroke_count,freq,jlpt,character_radical(id_radical),on_yomi(reading),kun_yomi(reading),meaning(content,lang(iso2))';

  @override
  Future<void> open(String path) async {
    _client = PostgresClient(url: url, anonKey: anonKey, schema: 'kanji');
    try {
      _connected = await _client!.testConnection('character');
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

  String _stripDashes(String reading) {
    return reading.replaceAll('-', '').replaceAll('.', '');
  }

  /// Kun readings are stored with okurigana separators ("あ.げる", "-ざま"),
  /// which must be ignored when matching. This cannot be expressed as a
  /// PostgREST filter, so the match is applied client-side on the
  /// stripped readings.
  Future<List<String>> _searchKunYomi(String input, SearchMode mode) async {
    final rows = await _c.query('kun_yomi', {
      'select': 'id_character,reading',
      'limit': 50000,
    });
    final ids = <String>{};
    for (final r in rows) {
      final reading = _stripDashes(r['reading'] as String? ?? '');
      final match = mode == SearchMode.raw
          ? reading.contains(input)
          : RegExp(input).hasMatch(reading);
      if (match) {
        ids.add(r['id_character'] as String);
      }
    }
    return ids.toList();
  }

  Future<List<String>> _searchOnYomi(String input, SearchMode mode) async {
    if (mode == SearchMode.raw) {
      final rows = await _c.query('on_yomi', {
        'select': 'id_character,reading',
        'limit': 50000,
      });
      return rows
          .where((r) => (r['reading'] as String? ?? '').contains(input))
          .map((r) => r['id_character'] as String)
          .toSet()
          .toList();
    }
    final rows = await _c.query('on_yomi', {
      'select': 'id_character',
      'reading': 'match.$input',
    });
    return rows.map((r) => r['id_character'] as String).toSet().toList();
  }

  Future<List<String>> _searchMeaning(
      String input,
      List<String> langs,
      SearchMode mode,
      ) async {
    if (mode == SearchMode.raw) {
      final params = <String, dynamic>{
        'select': 'id_character,content',
        'limit': 50000,
      };
      if (langs.isNotEmpty) {
        params['lang.iso2'] = 'in.(${langs.join(',')})';
      }
      final rows = await _c.query('meaning', params);
      return rows
          .where((r) => (r['content'] as String? ?? '').contains(input))
          .map((r) => r['id_character'] as String)
          .toSet()
          .toList();
    }
    final params = <String, dynamic>{
      'select': 'id_character',
      'content': 'match.$input',
    };
    if (langs.isNotEmpty) {
      params['lang.iso2'] = 'in.(${langs.join(',')})';
    }
    final rows = await _c.query('meaning', params);
    return rows.map((r) => r['id_character'] as String).toSet().toList();
  }

  Future<List<String>> _findCharacterIds(
      String input,
      List<String> langs,
      SearchMode mode,
      ) async {
    final matchesKanji = RegExp(matchKanji).allMatches(input);
    final hasHiragana = input.runes.any(
          (rune) => kanaKit.isHiragana(String.fromCharCode(rune)),
    );
    final hasKatakana = input.runes.any(
          (rune) => kanaKit.isKatakana(String.fromCharCode(rune)),
    );
    final hasRomaji = kanaKit.isRomaji(input);

    final ids = <String>{};

    if (matchesKanji.isNotEmpty) {
      ids.addAll(matchesKanji.map((m) => m.group(0)!));
    } else if (hasHiragana && !hasKatakana && !hasRomaji) {
      ids.addAll(await _searchKunYomi(input, mode));
    } else if (hasKatakana && !hasHiragana && !hasRomaji) {
      ids.addAll(await _searchOnYomi(input, mode));
    } else if (hasRomaji && !hasHiragana && !hasKatakana) {
      ids.addAll(await _searchMeaning(input, langs, mode));
    } else {
      final hiraganaInput = kanaKit.toHiragana(input);
      final katakanaInput = kanaKit.toKatakana(input);
      ids.addAll(await _searchKunYomi(hiraganaInput, mode));
      ids.addAll(await _searchOnYomi(katakanaInput, mode));
    }

    return ids.toList();
  }

  Kanji _kanjiFromRow(Map<String, dynamic> row) {
    return Kanji(
      literal: row['id'] as String,
      strokeCount: row['stroke_count'] as int? ?? 0,
      radicals: (row['character_radical'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((r) => r['id_radical'] as String)
          .toList() ??
          [],
      on: (row['on_yomi'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((r) => r['reading'] as String)
          .toList() ??
          [],
      kun: (row['kun_yomi'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((r) => r['reading'] as String)
          .toList() ??
          [],
      meanings: (row['meaning'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((m) {
        final lang =
            (m['lang'] as Map?)?.cast<String, dynamic>()['iso2']
            as String? ??
                '';
        return Meaning(
          content: m['content'] as String? ?? '',
          lang: lang,
        );
      })
          .toList() ??
          [],
    );
  }

  Future<List<Kanji>> _fetchCharacters(List<String> ids) async {
    if (ids.isEmpty) return [];
    final rows = await _c.query('character', {
      'select': _characterSelect,
      'id': 'in.(${ids.join(',')})',
    });
    return rows.map(_kanjiFromRow).toList();
  }

  /// [mode] selects the search strategy. Regexp uses the PostgREST
  /// `match` operator; raw is filtered client-side; glob is unsupported.
  @override
  Future<List<KanjiEntry>> search(
      String input, [
        int? resultsPerPage,
        int currentPage = 0,
        SearchMode mode = SearchMode.raw,
        List<String> langs = const [],
      ]) async {
    try {
      final ids = await _findCharacterIds(input, langs, mode);
      var kanji = await _fetchCharacters(ids);

      kanji.sort((a, b) {
        final freqA = a.freq ?? 9999;
        final freqB = b.freq ?? 9999;
        if (freqA != freqB) return freqA.compareTo(freqB);
        return a.strokeCount.compareTo(b.strokeCount);
      });

      if (resultsPerPage != null) {
        final start = currentPage * resultsPerPage;
        if (start >= kanji.length) return [];
        final end = (start + resultsPerPage).clamp(0, kanji.length);
        kanji = kanji.sublist(start, end);
      }

      return kanji.map((k) => KanjiEntry(kanji: k)).toList();
    } catch (e) {
      log('search kanji postgres: $e');
      return [];
    }
  }

  @override
  Future<int> count() async {
    try {
      return await _c.count('character', {'select': 'id'});
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<List<String>> getAvailableLangs() async {
    try {
      final rows = await _c.query('lang', {'select': 'iso2', 'order': 'id'});
      return rows.map((r) => r['iso2'] as String).toList();
    } catch (e) {
      log('getAvailableLangs kanji postgres: $e');
      return [];
    }
  }

  @override
  Future<List<Kanji>> getCharactersFromLiterals(List<String> characters) async {
    if (characters.isEmpty) return [];
    try {
      final rows = await _c.query('character', {
        'select': _characterSelect,
        'id': 'in.(${characters.join(',')})',
      });
      return rows.map(_kanjiFromRow).toList();
    } catch (e) {
      log('getCharactersFromLiterals postgres: $e');
      return [];
    }
  }

  @override
  Future<List<String>> getCharactersFromRadicals(List<String> radicals) async {
    if (radicals.isEmpty) return [];
    try {
      Set<String>? characters;
      for (final radical in radicals) {
        final rows = await _c.query('character_radical', {
          'select': 'id_character',
          'id_radical': 'eq.$radical',
        });
        final ids = rows.map((r) => r['id_character'] as String).toSet();
        characters = characters == null ? ids : characters.intersection(ids);
        if (characters.isEmpty) break;
      }
      if (characters == null || characters.isEmpty) return [];
      final kanji = await _fetchCharacters(characters.toList());
      kanji.sort((a, b) => a.strokeCount.compareTo(b.strokeCount));
      return kanji.map((k) => k.literal).toList();
    } catch (e) {
      log('getCharactersFromRadicals postgres: $e');
      return [];
    }
  }

  @override
  Future<List<Kanji>> getRadicals() async {
    try {
      final radicals = await _c.query('radical', {
        'select': 'id,stroke_count',
        'order': 'stroke_count',
      });
      if (radicals.isEmpty) return [];

      final inList = 'in.(${radicals.map((r) => r['id']).join(',')})';
      final res = await Future.wait([
        _c.query('on_yomi', {
          'select': 'id_character,reading',
          'id_character': inList,
          'limit': 50000,
        }),
        _c.query('kun_yomi', {
          'select': 'id_character,reading',
          'id_character': inList,
          'limit': 50000,
        }),
        _c.query('meaning', {
          'select': 'id_character,content,lang(iso2)',
          'id_character': inList,
          'limit': 50000,
        }),
      ]);

      Map<String, List<Map<String, dynamic>>> group(
          List<Map<String, dynamic>> rows) {
        final m = <String, List<Map<String, dynamic>>>{};
        for (final r in rows) {
          (m[r['id_character'] as String] ??= []).add(r);
        }
        return m;
      }

      final on = group(res[0]);
      final kun = group(res[1]);
      final mean = group(res[2]);

      return radicals.map((r) {
        final id = r['id'] as String;
        return _kanjiFromRow({
          ...r,
          'on_yomi': on[id] ?? [],
          'kun_yomi': kun[id] ?? [],
          'meaning': mean[id] ?? [],
        });
      }).toList();
    } catch (e) {
      log('getRadicals postgres: $e');
      return [];
    }
  }

  @override
  Future<List<String?>> getRadicalsCharacter() async {
    try {
      final rows = await _c.query('radical', {'select': 'id'});
      return rows.map((r) => r['id'] as String).toList();
    } catch (e) {
      log('getRadicalsCharacter postgres: $e');
      return [];
    }
  }

  @override
  Future<List<String?>> getRadicalsForSelection(
      List<String> selectedRadicals,
      ) async {
    if (selectedRadicals.isEmpty) return [];
    try {
      Set<String>? characters;
      for (final radical in selectedRadicals) {
        final rows = await _c.query('character_radical', {
          'select': 'id_character',
          'id_radical': 'eq.$radical',
        });
        final ids = rows.map((r) => r['id_character'] as String).toSet();
        characters = characters == null ? ids : characters.intersection(ids);
        if (characters.isEmpty) break;
      }
      if (characters == null || characters.isEmpty) return [];
      final rows = await _c.query('character_radical', {
        'select': 'id_radical',
        'id_character': 'in.(${characters.join(',')})',
      });
      return rows.map((r) => r['id_radical'] as String).toSet().toList();
    } catch (e) {
      log('getRadicalsForSelection postgres: $e');
      return [];
    }
  }

  @override
  Future<bool> isRegexpAvailable() async => true;

  @override
  Future<bool> isGlobAvailable() async => false;
}