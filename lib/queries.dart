//import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'kanji.dart';
import 'search.dart';
import 'string_utils.dart';

Future<List<KanjiEntry>> searchKanji(Database dbKanji, String input) async {
  String where;

  if (kanaKit.isHiragana(input)) {
    where = '''WHERE kanji.id IN (SELECT kanji.id
        FROM kanji 
        INNER JOIN kun_yomi ON kun_yomi.id_kanji = kanji.id 
        WHERE REPLACE(kun_yomi.reading,'.','') = "$input"
        GROUP BY kanji.id)''';
  } else if (kanaKit.isKatakana(input)) {
    where = '''WHERE kanji.id IN (SELECT kanji.id
        FROM kanji 
        INNER JOIN on_yomi ON on_yomi.id_kanji = kanji.id 
        WHERE on_yomi.reading = "$input"
        GROUP BY kanji.id)''';
  } else if (kanaKit.isRomaji(input)) {
    where = '''WHERE kanji.id IN (SELECT kanji.id
        FROM kanji 
        LEFT JOIN meaning ON meaning.id_kanji = kanji.id
        WHERE meaning.meaning REGEXP ".*$input.*"
        GROUP BY kanji.id)''';
  } else {
    where = 'WHERE kanji.id REGEXP "$input"';
  }

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
  String where;

  if (kanaKit.isRomaji(input)) {
    where =
        'WHERE expression.id IN (SELECT sense.id_expression FROM sense JOIN gloss ON gloss.id_sense = sense.id WHERE gloss.gloss REGEXP "$input") AND gloss.lang="$lang"';
  } else {
    /*SharedPreferences _sharedPreferences =
        await SharedPreferences.getInstance();
    List<String> prefLangs = _sharedPreferences.getStringList('langs')!;

    List<String> enabledLangs = <String>[];
    prefLangs.forEach((prefLang) {
      var prefLangParsed = prefLang.split(':');

      if (prefLangParsed[1] == '1') {
        enabledLangs.add(prefLangParsed[0]);
      }
    });*/

    List<String> enabledLangs = <String>['eng'];
    where =
        'WHERE (kanji REGEXP "$input" OR reading REGEXP "$input") AND lang IN ${sqlIn(enabledLangs)}';
  }

  String sql = '''SELECT expression.id as expression_id,
                  sense.id as sense_id, 
                  expression.kanji, 
                  expression.reading, 
                  sense.pos, 
                  gloss.gloss, 
                  gloss.lang
                  FROM expression
                  JOIN sense ON id_expression = expression.id
                  JOIN gloss ON id_sense = sense.id
                  $where
                  ORDER BY expression.id''';

  List<Map<String, dynamic>> queryResults;
  try {
    queryResults = await dbExpression.rawQuery(sql);
  } catch (e) {
    //throw ('ERROR $e');
    return [];
  }

  int? expressionId;
  int? senseId;
  List<ExpressionEntry> entries = [];
  List<String> glosses = [];
  List<Sense> senses = [];

  for (var queryResult in queryResults) {
    if (queryResult['expression_id'] != expressionId) {
      senses = [];
      entries.add(ExpressionEntry(
          kanji: queryResult['kanji'],
          reading: queryResult['reading'],
          senses: senses));
      expressionId = queryResult['expression_id'];
    }

    if (queryResult['sense_id'] != senseId) {
      glosses = [];
      senseId = queryResult['sense_id'];
      senses.add(Sense(glosses: glosses, posses: [], lang: "eng"));
    }

    glosses.add(queryResult['gloss']);
  }


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
