//import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

import 'package:sqflite/sqflite.dart';

import '../models/kanji.dart';
import '../models/search.dart';
import '../string_utils.dart';

Future<List<KanjiEntry>> searchKanji(Database dbKanji, String input) async {
  String where;

  if (kanaKit.isHiragana(input)) {
    where = '''WHERE character.id IN (SELECT character.id
        FROM character 
        INNER JOIN kun_yomi ON kun_yomi.id_character = character.id 
        WHERE REPLACE(kun_yomi.reading,'.','') = "$input"
        GROUP BY character.id)''';
  } else if (kanaKit.isKatakana(input)) {
    where = '''WHERE character.id IN (SELECT character.id
        FROM character 
        INNER JOIN on_yomi ON on_yomi.id_kanji = character.id 
        WHERE on_yomi.reading = "$input"
        GROUP BY character.id)''';
  } else if (kanaKit.isRomaji(input)) {
    where = '''WHERE character.id IN (SELECT character.id
        FROM character 
        LEFT JOIN meaning ON meaning.id_character = character.id
        WHERE meaning.content REGEXP ".*$input.*"
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
        ORDER BY character.freq NULLS LAST, character.stroke_count''';

  final List<Map<String, dynamic>> kanjiMaps = await dbKanji.rawQuery(sql);

  return List.generate(kanjiMaps.length, (i) {
    return KanjiEntry(kanji: Kanji.fromMap(kanjiMaps[i]));
  });
}

Future<List<ExpressionEntry>> searchExpression(Database dbExpression, String input, String lang,
    [resultsPerPage = 10, currentPage = 0]) async {
  String joins = '''JOIN sense ON sense.id_entry = entry.id
                    JOIN gloss ON gloss.id_sense = sense.id
                    LEFT JOIN sense_pos on sense.id = sense_pos.id_sense 
                    LEFT JOIN pos on sense_pos.id_pos = pos.id
                    LEFT JOIN sense_dial on sense.id = sense_dial.id_sense 
                    LEFT JOIN dial on sense_dial.id_dial = dial.id
                    LEFT JOIN sense_field on sense.id = sense_field.id_sense 
                    LEFT JOIN field on sense_field.id_field = field.id
                    LEFT JOIN sense_misc on sense.id = sense_misc.id_sense 
                    LEFT JOIN misc on sense_misc.id_misc = misc.id''';

  String where;
  if (kanaKit.isRomaji(input)) {
    where =
        "WHERE entry.id IN (SELECT sense.id_entry FROM sense JOIN gloss ON gloss.id_sense = sense.id WHERE gloss.content REGEXP '$input')";
  } else {
    where = 'WHERE (keb REGEXP "$input" OR reb REGEXP "$input")';
    joins += '''\nJOIN r_ele on entry.id = r_ele.id_entry
                LEFT JOIN k_ele on entry.id = k_ele.id_entry''';
  }

  String sql = '''SELECT entry.id as entry_id,
                  sense.id as sense_id, 
                  (SELECT GROUP_CONCAT(reb) FROM r_ele WHERE r_ele.id_entry = entry.id AND r_ele.id NOT IN (SELECT DISTINCT id_r_ele FROM k_ele WHERE k_ele.id_entry = entry.id)) reb_group,
                  (SELECT GROUP_CONCAT(keb || ':' || (SELECT reb FROM r_ele WHERE r_ele.id_entry = entry.id AND id = k_ele.id_r_ele), ',') FROM k_ele WHERE k_ele.id_entry = entry.id) keb_reb_group,
                  GROUP_CONCAT(DISTINCT gloss.content) gloss_group,
                  GROUP_CONCAT(DISTINCT pos.name) pos_group,
                  GROUP_CONCAT(DISTINCT dial.name) dial_group,
                  GROUP_CONCAT(DISTINCT field.name) field_group,
                  GROUP_CONCAT(DISTINCT misc.name) misc_group
                  FROM entry
                  $joins
                  $where
                  GROUP BY sense.id
                  LIMIT $resultsPerPage OFFSET ${currentPage * resultsPerPage}''';

  log(sql);

  List<Map<String, dynamic>> queryResults;
  try {
    queryResults = await dbExpression.rawQuery(sql);
  } catch (e) {
    //throw ('ERROR $e');
    return [];
  }

  int? entryId;
  int? senseId;
  List<ExpressionEntry> entries = [];
  List<String> glosses = [];
  List<Sense> senses = [];

  for (var queryResult in queryResults) {
    if (queryResult['entry_id'] != entryId) {
      senses = [];
      entries.add(ExpressionEntry(
          kanji:
              queryResult['keb_reb_group'] != null ? queryResult['keb_reb_group'].split(',') : [],
          reading: queryResult['reb_group'] != null ? queryResult['reb_group'].split(',') : [],
          senses: senses));
      entryId = queryResult['entry_id'];
    }

    if (queryResult['sense_id'] != senseId) {
      glosses = [];
      senseId = queryResult['sense_id'];
      senses.add(Sense(
          glosses: glosses,
          posses: queryResult['pos_group'].split(','),
          dial: queryResult['dial_group'] != null ? queryResult['dial_group'].split(',') : [],
          misc: queryResult['misc_group'] != null ? queryResult['misc_group'].split(',') : [],
          lang: "eng"));
    }

    glosses.add(queryResult['gloss_group']);
  }

  return entries;
}

Future<Kanji> getKanjiFromCharacter(Database dbKanji, String character) async {
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
        WHERE character.id = "$character"''';

  final List<Map<String, dynamic>> kanjiMaps = await dbKanji.rawQuery(sqlKanji);
  return Kanji.fromMap(kanjiMaps.first);
}

Future<List<Kanji>> getKanjiFromCharacters(Database dbKanji, List<String> characters) async {
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
        WHERE character.id IN (${characters.join(',')})
        GROUP BY character.id''';

  final List<Map<String, dynamic>> kanjiMaps = await dbKanji.rawQuery(sqlKanji);

  return List.generate(kanjiMaps.length, (i) {
    return Kanji.fromMap(kanjiMaps[i]);
  });
}

Future<String> getKanjiFromRadicals(Database dbKanji, String radicals) async {
  String sql = ' SELECT id FROM character WHERE id IN (';
  radicals.split('').asMap().forEach((i, radical) {
    sql += "SELECT id_character FROM character_radical WHERE id_radical = '$radical'";
    sql += i < radicals.length - 1 ? ' INTERSECT ' : ') ORDER BY stroke_count;';
  });

  final List<Map<String, dynamic>> kanjiMaps = await dbKanji.rawQuery(sql);

  return List.generate(kanjiMaps.length, (i) {
    return kanjiMaps[i]["id"];
  }).join();
}

Future<List<Kanji>> getRadicals(Database dbKanji) async {
  final List<Map<String, dynamic>> radicalMaps =
      await dbKanji.rawQuery('SELECT * FROM radical ORDER BY stroke_count');

  return List.generate(radicalMaps.length, (i) {
    return Kanji.fromMap(radicalMaps[i]);
  });
}

Future<List<String?>> getRadicalsCharacter(Database dbKanji) async {
  final List<Map<String, dynamic>> radicalMaps = await dbKanji.rawQuery('SELECT id FROM radical');

  return List.generate(radicalMaps.length, (i) {
    return radicalMaps[i]['id'];
  });
}

Future<List<String?>> getRadicalsForSelection(Database dbKanji, selectedRadicals) async {
  String sql = 'SELECT DISTINCT id_radical FROM character_radical WHERE id_character IN (';
  selectedRadicals.asMap().forEach((i, radical) {
    sql += 'SELECT DISTINCT id_character FROM character_radical WHERE id_radical = "$radical"';
    if (i < selectedRadicals.length - 1) sql += ' INTERSECT ';
  });
  sql += ')';

  final List<Map<String, dynamic>> radicalIdMaps = await dbKanji.rawQuery(sql);

  return List.generate(radicalIdMaps.length, (i) {
    return radicalIdMaps[i]['id_radical'];
  });
}