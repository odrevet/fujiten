import '../models/entry.dart';
import '../models/kanji.dart';
import '../string_utils.dart';
import 'database_interface.dart';

class DatabaseInterfaceKanji extends DatabaseInterface {
  DatabaseInterfaceKanji({super.database});

  @override
  Future<List<KanjiEntry>> search(String input, [resultsPerPage = 10, currentPage = 0]) async {
    String where;

    Iterable<RegExpMatch> matchesKanji = RegExp(regexKanji).allMatches(input);

    if (matchesKanji.isNotEmpty) {
      where = "WHERE character.id IN (${matchesKanji.map((m) => "'${m.group(0)}'").join(',')})";
    } else if (kanaKit.isHiragana(input)) {
      where = '''WHERE character.id IN (SELECT character.id
        FROM character 
        INNER JOIN kun_yomi ON kun_yomi.id_character = character.id 
        WHERE REPLACE(kun_yomi.reading,'.','') = "$input"
        GROUP BY character.id)''';
    } else if (kanaKit.isKatakana(input)) {
      where = '''WHERE character.id IN (SELECT character.id
        FROM character 
        INNER JOIN on_yomi ON on_yomi.id_character = character.id 
        WHERE on_yomi.reading = "$input"
        GROUP BY character.id)''';
    } else if (kanaKit.isRomaji(input)) {
      where = '''WHERE character.id IN (SELECT character.id
        FROM character 
        LEFT JOIN meaning ON meaning.id_character = character.id
        WHERE meaning.content REGEXP "$input"
        GROUP BY character.id)''';
    } else {
      where = 'WHERE character.id REGEXP "$input"';
    }

    String sql = '''SELECT character.*,
        GROUP_CONCAT(DISTINCT character_radical.id_radical) as radicals,
        GROUP_CONCAT(DISTINCT on_yomi.reading) AS on_reading,
        GROUP_CONCAT(DISTINCT kun_yomi.reading) AS kun_reading,
        GROUP_CONCAT(DISTINCT meaning.content) AS meanings
        FROM character
        LEFT JOIN character_radical ON character.id = character_radical.id_character
        LEFT JOIN on_yomi ON character.id = on_yomi.id_character
        LEFT JOIN kun_yomi ON kun_yomi.id_character = character.id
        LEFT JOIN meaning ON meaning.id_character = character.id
        $where
        GROUP BY character.id
        ORDER BY character.freq NULLS LAST, character.stroke_count
        LIMIT $resultsPerPage OFFSET ${currentPage * resultsPerPage}''';

    final List<Map<String, dynamic>> kanjiMaps = await database!.rawQuery(sql);

    return List.generate(kanjiMaps.length, (i) {
      return KanjiEntry(kanji: Kanji.fromMap(kanjiMaps[i]));
    });
  }

  Future<Kanji> getKanjiFromCharacter(String character) async {
    String sqlKanji = '''SELECT character.*,
        GROUP_CONCAT(DISTINCT character_radical.id_radical) as radicals,
        GROUP_CONCAT(DISTINCT on_yomi.reading) AS on_reading,
        GROUP_CONCAT(DISTINCT kun_yomi.reading) AS kun_reading,
        GROUP_CONCAT(DISTINCT meaning.content) AS meanings
        FROM character
        LEFT JOIN character_radical ON character.id = character_radical.id_character
        LEFT JOIN on_yomi ON character.id = on_yomi.id_character
        LEFT JOIN kun_yomi ON kun_yomi.id_character = character.id
        LEFT JOIN meaning ON meaning.id_character = character.id
        WHERE character.id = '$character';''';

    final List<Map<String, dynamic>> kanjiMaps = await database!.rawQuery(sqlKanji);
    return Kanji.fromMap(kanjiMaps.first);
  }

  Future<List<Kanji>> getKanjiFromCharacters(List<String> characters) async {
    String sqlKanji = '''SELECT character.*,
        GROUP_CONCAT(DISTINCT character_radical.id_radical) as radicals,
        GROUP_CONCAT(DISTINCT on_yomi.reading) AS on_reading,
        GROUP_CONCAT(DISTINCT kun_yomi.reading) AS kun_reading,
        GROUP_CONCAT(DISTINCT meaning.content) AS meanings
        FROM character
        LEFT JOIN character_radical ON character.id = character_radical.id_character
        LEFT JOIN on_yomi ON character.id = on_yomi.id_character
        LEFT JOIN kun_yomi ON kun_yomi.id_character = character.id
        LEFT JOIN meaning ON meaning.id_character = character.id
        WHERE character.id IN (${characters.map((char) => "'$char'").join(',')})
        GROUP BY character.id''';

    final List<Map<String, dynamic>> kanjiMaps = await database!.rawQuery(sqlKanji);

    return List.generate(kanjiMaps.length, (i) {
      return Kanji.fromMap(kanjiMaps[i]);
    });
  }

  Future<String> getKanjiFromRadicals(String radicals) async {
    String sql = ' SELECT id FROM character WHERE id IN (';
    radicals.split('').asMap().forEach((i, radical) {
      sql += "SELECT id_character FROM character_radical WHERE id_radical = '$radical'";
      sql += i < radicals.length - 1 ? ' INTERSECT ' : ') ORDER BY stroke_count;';
    });

    final List<Map<String, dynamic>> kanjiMaps = await database!.rawQuery(sql);

    return List.generate(kanjiMaps.length, (i) {
      return kanjiMaps[i]["id"];
    }).join();
  }

  Future<List<Kanji>> getRadicals() async {
    final List<Map<String, dynamic>> radicalMaps = await database!.rawQuery('''SELECT radical.id, 
                                    radical.stroke_count,
                                    GROUP_CONCAT(DISTINCT on_yomi.reading) AS on_reading,
                                    GROUP_CONCAT(DISTINCT kun_yomi.reading) AS kun_reading,
                                    GROUP_CONCAT(DISTINCT meaning.content) AS meanings
                                    FROM radical 
                                    LEFT JOIN on_yomi ON radical.id = on_yomi.id_character
                                    LEFT JOIN kun_yomi ON kun_yomi.id_character = radical.id
                                    LEFT JOIN meaning ON meaning.id_character = radical.id
                                    GROUP BY radical.id
                                    ORDER BY stroke_count''');

    return List.generate(radicalMaps.length, (i) {
      return Kanji.fromMap(radicalMaps[i]);
    });
  }

  Future<List<String?>> getRadicalsCharacter() async {
    final List<Map<String, dynamic>> radicalMaps =
        await database!.rawQuery('SELECT id FROM radical');

    return List.generate(radicalMaps.length, (i) {
      return radicalMaps[i]['id'];
    });
  }

  Future<List<String?>> getRadicalsForSelection(selectedRadicals) async {
    String sql = 'SELECT DISTINCT id_radical FROM character_radical WHERE id_character IN (';
    selectedRadicals.asMap().forEach((i, radical) {
      sql += 'SELECT DISTINCT id_character FROM character_radical WHERE id_radical = "$radical"';
      if (i < selectedRadicals.length - 1) sql += ' INTERSECT ';
    });
    sql += ')';

    final List<Map<String, dynamic>> radicalIdMaps = await database!.rawQuery(sql);

    return List.generate(radicalIdMaps.length, (i) {
      return radicalIdMaps[i]['id_radical'];
    });
  }
}
