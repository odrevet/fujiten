

import 'dart:developer';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../models/entry.dart';
import '../../models/kanji.dart';
import '../../models/states/search_options_state.dart';
import '../../string_utils.dart';
import '../database_interface.dart';
import '../database_interface_kanji.dart';

class SqliteDatabaseInterfaceKanji extends DatabaseInterfaceKanji {
  Database? database;

  SqliteDatabaseInterfaceKanji({this.database});

  @override
  DatabaseBackend get backend => DatabaseBackend.sqlite;

  @override
  bool get isOpen => database != null;

  @override
  Future<void> open(String path) async {
    try {
      if (const bool.fromEnvironment('FFI', defaultValue: false)) {
        database = await databaseFactoryFfi.openDatabase(path);
      } else {
        database = await openDatabase(path, readOnly: true);
      }
    } catch (e) {
      database = null;
      status = DatabaseStatus.noResults;
      logMessage = e.toString();
    }
  }

  @override
  Future<void> dispose() async {
    await database?.close();
    database = null;
  }

  String _matchCondition(String column, SearchMode mode, String input) {
    switch (mode) {
      case SearchMode.raw:
        return "instr($column, '$input') > 0";
      case SearchMode.regexp:
        return "$column REGEXP '$input'";
      case SearchMode.glob:
        return "$column GLOB '$input'";
    }
  }

  @override
  Future<List<KanjiEntry>> search(
    String input, [
    int? resultsPerPage,
    int currentPage = 0,
    SearchMode mode = SearchMode.raw,
    List<String> langs = const [],
  ]) async {
    String where;
    String langFilter = langs.isEmpty
        ? ''
        : "AND lang.iso2 IN (${langs.map((l) => "'$l'").join(',')})";

    Iterable<RegExpMatch> matchesKanji = RegExp(matchKanji).allMatches(input);
    bool hasHiragana = input.runes.any(
      (rune) => kanaKit.isHiragana(String.fromCharCode(rune)),
    );
    bool hasKatakana = input.runes.any(
      (rune) => kanaKit.isKatakana(String.fromCharCode(rune)),
    );
    bool hasRomaji = kanaKit.isRomaji(input);

    if (matchesKanji.isNotEmpty) {
      where =
      "WHERE character.id IN (${matchesKanji.map((m) => "'${m.group(0)}'").join(',')})";
    } else if (hasHiragana && !hasKatakana && !hasRomaji) {
      where =
      '''WHERE character.id IN (SELECT character.id
         FROM character 
         INNER JOIN kun_yomi ON kun_yomi.id_character = character.id 
         WHERE ${_matchCondition("REPLACE(REPLACE(kun_yomi.reading,'-',''),'.','')", mode, input)}
         GROUP BY character.id)''';
    } else if (hasKatakana && !hasHiragana && !hasRomaji) {
      where =
      '''WHERE character.id IN (SELECT character.id
         FROM character 
         INNER JOIN on_yomi ON on_yomi.id_character = character.id 
         WHERE ${_matchCondition('on_yomi.reading', mode, input)}
         GROUP BY character.id)''';
    } else if (hasRomaji && !hasHiragana && !hasKatakana) {
      where =
      '''WHERE character.id IN (SELECT character.id
         FROM character 
         LEFT JOIN meaning ON meaning.id_character = character.id
         LEFT JOIN lang ON meaning.id_lang = lang.id
         WHERE ${_matchCondition('meaning.content', mode, input)} $langFilter
         GROUP BY character.id)''';
    } else {
      String hiraganaInput = kanaKit.toHiragana(input);
      String katakanaInput = kanaKit.toKatakana(input);

      where =
      '''WHERE character.id IN (
         SELECT character.id FROM character 
         INNER JOIN kun_yomi ON kun_yomi.id_character = character.id 
         WHERE ${_matchCondition("REPLACE(REPLACE(kun_yomi.reading,'-',''),'.','')", mode, hiraganaInput)}
         GROUP BY character.id
         UNION
         SELECT character.id FROM character 
         INNER JOIN on_yomi ON on_yomi.id_character = character.id 
         WHERE ${_matchCondition('on_yomi.reading', mode, katakanaInput)}
         GROUP BY character.id
      )''';
    }

    String sql =
    '''SELECT character.*,
           GROUP_CONCAT(DISTINCT character_radical.id_radical) as radicals,
           GROUP_CONCAT(DISTINCT on_yomi.reading) AS on_reading,
           GROUP_CONCAT(DISTINCT kun_yomi.reading) AS kun_reading,
           GROUP_CONCAT(DISTINCT meaning.content || '|' || lang.iso2) AS meanings
           FROM character
           LEFT JOIN character_radical ON character.id = character_radical.id_character
           LEFT JOIN on_yomi ON character.id = on_yomi.id_character
           LEFT JOIN kun_yomi ON kun_yomi.id_character = character.id
           LEFT JOIN meaning ON meaning.id_character = character.id
           LEFT JOIN lang ON meaning.id_lang = lang.id
           $where
           ${langs.isEmpty ? '' : "AND lang.iso2 IN (${langs.map((l) => "'$l'").join(',')})"}
           GROUP BY character.id
           ORDER BY character.freq NULLS LAST, character.stroke_count''';

    if (resultsPerPage != null) {
      sql += " LIMIT $resultsPerPage OFFSET ${currentPage * resultsPerPage}";
    }

    log(sql);

    final List<Map<String, dynamic>> kanjiMaps = await database!.rawQuery(sql);

    return List.generate(kanjiMaps.length, (i) {
      return KanjiEntry(kanji: Kanji.fromMap(kanjiMaps[i]));
    });
  }

  @override
  Future<int> count() async {
    try {
      var x = await database!.rawQuery(
        "SELECT count(character.id) from character;",
      );
      return Sqflite.firstIntValue(x) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<List<String>> getAvailableLangs() async {
    try {
      final results = await database!.rawQuery(
        'SELECT iso2 FROM lang ORDER BY id',
      );
      return results.map((row) => row['iso2'] as String).toList();
    } catch (e) {
      log('getAvailableLangs kanji: $e');
      return [];
    }
  }

  @override
  Future<bool> isRegexpAvailable() async {
    try {
      await database!.rawQuery(
        "SELECT id FROM character WHERE id REGEXP '.*' LIMIT 1",
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isGlobAvailable() async => true;

  @override
  Future<List<Kanji>> getCharactersFromLiterals(List<String> characters) async {
    String sql =
    '''SELECT character.*,
        GROUP_CONCAT(DISTINCT character_radical.id_radical) as radicals,
        GROUP_CONCAT(DISTINCT on_yomi.reading) AS on_reading,
        GROUP_CONCAT(DISTINCT kun_yomi.reading) AS kun_reading,
        GROUP_CONCAT(DISTINCT meaning.content || '|' || lang.iso2) AS meanings
        FROM character
        LEFT JOIN character_radical ON character.id = character_radical.id_character
        LEFT JOIN on_yomi ON character.id = on_yomi.id_character
        LEFT JOIN kun_yomi ON kun_yomi.id_character = character.id
        LEFT JOIN meaning ON meaning.id_character = character.id
        LEFT JOIN lang ON meaning.id_lang = lang.id
        WHERE character.id IN (${characters.map((char) => "'$char'").join(',')})
        GROUP BY character.id''';

    final List<Map<String, dynamic>> kanjiMaps = await database!.rawQuery(sql);

    return List.generate(kanjiMaps.length, (i) {
      return Kanji.fromMap(kanjiMaps[i]);
    });
  }

  @override
  Future<List<String>> getCharactersFromRadicals(List<String> radicals) async {
    if (radicals.isEmpty) {
      return <String>[];
    }

    String sql = 'SELECT id FROM character WHERE id IN (';
    radicals.asMap().forEach((i, radical) {
      sql +=
      "SELECT id_character FROM character_radical WHERE id_radical = '$radical'";
      sql += i < radicals.length - 1
          ? ' INTERSECT '
          : ') ORDER BY stroke_count;';
    });

    final List<Map<String, dynamic>> kanjiMaps = await database!.rawQuery(sql);

    return List.generate(kanjiMaps.length, (i) {
      return kanjiMaps[i]["id"];
    });
  }

  @override
  Future<List<Kanji>> getRadicals() async {
    final List<Map<String, dynamic>> radicalMaps = await database!.rawQuery(
      '''SELECT radical.id, 
                radical.stroke_count,
                GROUP_CONCAT(DISTINCT on_yomi.reading) AS on_reading,
                GROUP_CONCAT(DISTINCT kun_yomi.reading) AS kun_reading,
                GROUP_CONCAT(DISTINCT meaning.content || '|' || lang.iso2) AS meanings
                FROM radical 
                LEFT JOIN on_yomi ON radical.id = on_yomi.id_character
                LEFT JOIN kun_yomi ON kun_yomi.id_character = radical.id
                LEFT JOIN meaning ON meaning.id_character = radical.id
                LEFT JOIN lang ON meaning.id_lang = lang.id
                GROUP BY radical.id
                ORDER BY stroke_count''',
    );

    return List.generate(radicalMaps.length, (i) {
      return Kanji.fromMap(radicalMaps[i]);
    });
  }

  @override
  Future<List<String?>> getRadicalsCharacter() async {
    final List<Map<String, dynamic>> radicalMaps = await database!.rawQuery(
      'SELECT id FROM radical',
    );

    return List.generate(radicalMaps.length, (i) {
      return radicalMaps[i]['id'];
    });
  }

  @override
  Future<List<String?>> getRadicalsForSelection(
    List<String> selectedRadicals,
  ) async {
    String sql =
        'SELECT DISTINCT id_radical FROM character_radical WHERE id_character IN (';
    selectedRadicals.asMap().forEach((i, radical) {
      sql +=
      "SELECT DISTINCT id_character FROM character_radical WHERE id_radical = '$radical'";
      if (i < selectedRadicals.length - 1) sql += ' INTERSECT ';
    });
    sql += ')';

    final List<Map<String, dynamic>> radicalIdMaps = await database!.rawQuery(
      sql,
    );

    return List.generate(radicalIdMaps.length, (i) {
      return radicalIdMaps[i]['id_radical'];
    });
  }
}
