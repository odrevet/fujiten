

import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kanji.dart';
import 'search.dart';
import 'stringUtils.dart';

Future<List<KanjiEntry>> searchKanji(Database dbKanji, String input) async {
  String where;

  if (isHiraganaString(input))
    where = '''WHERE kanji.id IN (SELECT kanji.id
        FROM kanji 
        INNER JOIN kun_yomi ON kun_yomi.id_kanji = kanji.id 
        WHERE REPLACE(kun_yomi.reading,'.','') = "$input"
        GROUP BY kanji.id)''';
  else if (isKatakanaString(input))
    where = '''WHERE kanji.id IN (SELECT kanji.id
        FROM kanji 
        INNER JOIN on_yomi ON on_yomi.id_kanji = kanji.id 
        WHERE on_yomi.reading = "$input"
        GROUP BY kanji.id)''';
  else if (isLatinString(input))
    where = '''WHERE kanji.id IN (SELECT kanji.id
        FROM kanji 
        LEFT JOIN meaning ON meaning.id_kanji = kanji.id
        WHERE meaning.meaning REGEXP ".*$input.*"
        GROUP BY kanji.id)''';
  else
    where = 'WHERE kanji.id REGEXP "$input"';

  String sql = '''SELECT kanji.*,
        GROUP_CONCAT(DISTINCT kanji_radical.id_radical) as radicals,
        GROUP_CONCAT(DISTINCT on_yomi.reading) AS on_reading,
        GROUP_CONCAT(DISTINCT kun_yomi.reading) AS kun_reading,
        GROUP_CONCAT(DISTINCT meaning.meaning) AS meanings
        FROM kanji
        LEFT JOIN kanji_radical ON kanji.id = kanji_radical.id_kanji
        LEFT JOIN on_yomi ON kanji.id = on_yomi.id_kanji
        LEFT JOIN kun_yomi ON kun_yomi.id_kanji = kanji.id
        LEFT JOIN meaning ON meaning.id_kanji = kanji.id
        $where
        GROUP BY kanji.id
        ORDER BY kanji.stroke''';

  final List<Map<String, dynamic>> kanjiMaps = await dbKanji.rawQuery(sql);

  return List.generate(kanjiMaps.length, (i) {
    return KanjiEntry(kanji: Kanji.fromMap(kanjiMaps[i]));
  });
}

Future<List<ExpressionEntry>> searchExpression(
    Database dbExpression, String input, String lang,
    [resultsPerPage = 10, currentPage = 0]) async {
  List<ExpressionEntry> entries = [];

  String where;

  if (isLatinString(input))
    where = 'WHERE glosses REGEXP ".*$input.*" AND lang="$lang"';
  else {
    SharedPreferences _sharedPreferences =
        await SharedPreferences.getInstance();
    List<String> prefLangs = _sharedPreferences.getStringList('langs')!;

    List<String> enabledLangs = <String>[];
    prefLangs.forEach((prefLang) {
      var prefLangParsed = prefLang.split(':');

      if (prefLangParsed[1] == '1') {
        enabledLangs.add(prefLangParsed[0]);
      }
    });

    where =
        'WHERE (kanji REGEXP "$input" OR reading REGEXP "$input") AND lang IN ${sqlIn(enabledLangs)}';
  }

  String sql =
      '''SELECT e.id as expression_id, e.kanji, e.reading, s.glosses, s.pos, s.lang
      FROM expression e
      JOIN sense s ON s.id_expression = e.id
      $where
      ORDER BY LENGTH(kanji)
      LIMIT $resultsPerPage OFFSET ${currentPage * resultsPerPage}''';

  List<Map<String, dynamic>> expressionMaps;
  try {
    expressionMaps = await dbExpression.rawQuery(sql);
  } catch (e) {
    throw ('ERROR $e');
  }

  late List<Sense> senses;
  int? expressionId;

  expressionMaps.forEach((expressionMap) {
    if (expressionId == null || expressionMap['expression_id'] != expressionId) {
      senses = <Sense>[];
      senses.add(
        Sense(
            glosses: expressionMap['glosses'],
            posses: expressionMap['pos'].replaceAll(RegExp(' '), '').split(','),
            lang: expressionMap['lang']),
      );
      entries.add(ExpressionEntry(
          kanji: expressionMap['kanji'] ?? '',
          reading: expressionMap['reading'],
          senses: senses));
    } else {
      senses.add(
        Sense(
            glosses: expressionMap['glosses'],
            posses: expressionMap['pos'].replaceAll(RegExp(' '), '').split(','),
            lang: expressionMap['lang']),
      );
    }
    expressionId = expressionMap['expression_id'];
  });

  return entries;
}

Future<Kanji> getKanjiFromCharacter(Database dbKanji, String character) async {
  String sqlKanji = '''SELECT kanji.*,
        GROUP_CONCAT(DISTINCT kanji_radical.id_radical) as radicals,
        GROUP_CONCAT(DISTINCT on_yomi.reading) AS on_reading,
        GROUP_CONCAT(DISTINCT kun_yomi.reading) AS kun_reading,
        GROUP_CONCAT(DISTINCT meaning.meaning) AS meanings
        FROM kanji
        LEFT JOIN kanji_radical ON kanji.id = kanji_radical.id_kanji
        LEFT JOIN on_yomi ON kanji.id = on_yomi.id_kanji
        LEFT JOIN kun_yomi ON kun_yomi.id_kanji = kanji.id
        LEFT JOIN meaning ON meaning.id_kanji = kanji.id
        WHERE kanji.id = "$character"''';

  final List<Map<String, dynamic>> kanjiMaps = await dbKanji.rawQuery(sqlKanji);
  return Kanji.fromMap(kanjiMaps.first);
}

Future<List<Kanji>> getKanjiFromCharacters(
    Database dbKanji, List<String> characters) async {
  String sqlKanji = '''SELECT kanji.*,
        GROUP_CONCAT(DISTINCT kanji_radical.id_radical) as radicals,
        GROUP_CONCAT(DISTINCT on_yomi.reading) AS on_reading,
        GROUP_CONCAT(DISTINCT kun_yomi.reading) AS kun_reading,
        GROUP_CONCAT(DISTINCT meaning.meaning) AS meanings
        FROM kanji
        LEFT JOIN kanji_radical ON kanji.id = kanji_radical.id_kanji
        LEFT JOIN on_yomi ON kanji.id = on_yomi.id_kanji
        LEFT JOIN kun_yomi ON kun_yomi.id_kanji = kanji.id
        LEFT JOIN meaning ON meaning.id_kanji = kanji.id
        WHERE kanji.id IN ${sqlIn(characters)}
        GROUP BY kanji.id''';

  final List<Map<String, dynamic>> kanjiMaps = await dbKanji.rawQuery(sqlKanji);

  return List.generate(kanjiMaps.length, (i) {
    return Kanji.fromMap(kanjiMaps[i]);
  });
}

Future<String> getKanjiFromRadicals(Database dbKanji, String radicals) async {
  String sql = ' SELECT id FROM kanji WHERE id IN (';
  radicals.split('').asMap().forEach((i, radical) {
    sql += "SELECT id_kanji FROM kanji_radical WHERE id_radical = '$radical'";
    sql += i < radicals.length - 1 ? ' INTERSECT ' : ') ORDER BY stroke;';
  });

  final List<Map<String, dynamic>> kanjiMaps = await dbKanji.rawQuery(sql);

  return List.generate(kanjiMaps.length, (i) {
    return kanjiMaps[i]["id"];
  }).join();
}

Future<List<Kanji>> getRadicals(Database dbKanji) async {
  final List<Map<String, dynamic>> radicalMaps =
      await dbKanji.rawQuery('SELECT * FROM radical ORDER BY stroke');

  return List.generate(radicalMaps.length, (i) {
    return Kanji.fromMap(radicalMaps[i]);
  });
}

Future<List<String?>> getRadicalsCharacter(Database dbKanji) async {
  final List<Map<String, dynamic>> radicalMaps =
      await dbKanji.rawQuery('SELECT id FROM radical');

  return List.generate(radicalMaps.length, (i) {
    return radicalMaps[i]['id'];
  });
}
