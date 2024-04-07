import 'dart:developer';

import 'package:sqflite/sqflite.dart';

import '../models/entry.dart';
import '../models/sense.dart';
import '../string_utils.dart';
import 'database_interface.dart';

class DatabaseInterfaceExpression extends DatabaseInterface {
  DatabaseInterfaceExpression({super.database});

  String subQuery(String input, int? resultsPerPage, int currentPage) {
    String sql;
    if (kanaKit.isRomaji(input)) {
      sql =
          "SELECT DISTINCT sense.id_entry FROM sense JOIN gloss ON gloss.id_sense = sense.id WHERE gloss.content REGEXP '$input'";
    } else {
      // if the input does not contains a kanji do not search in the reb
      var regExp = RegExp(regexKanji);
      var hasKanji = regExp.hasMatch(input);
      sql =
          '''SELECT DISTINCT  entry_sub.id FROM entry entry_sub JOIN sense sense_sub ON entry_sub.id = sense_sub.id_entry JOIN r_ele on entry_sub.id = r_ele.id_entry
         LEFT JOIN k_ele ON entry_sub.id = k_ele.id_entry WHERE (keb REGEXP '$input' ${hasKanji ? "" : "OR reb REGEXP '$input'"})''';
    }

    if (resultsPerPage != null) {
      sql += " LIMIT $resultsPerPage OFFSET ${currentPage * resultsPerPage}";
    }
    return sql;
  }

  @override
  Future<List<ExpressionEntry>> search(String input,
      [int? resultsPerPage, int currentPage = 0]) async {
    String sql = '''SELECT entry.id as entry_id,
                  sense.id as sense_id, 
                  (
                    SELECT
                      GROUP_CONCAT(IFNULL(keb || ':', '') || reb)
                    FROM
                      r_ele r_ele_sub
                      LEFT JOIN r_ele_k_ele ON r_ele_k_ele.id_r_ele = r_ele_sub.id
                      LEFT JOIN k_ele k_ele_sub ON r_ele_k_ele.id_k_ele = k_ele_sub.id
                    WHERE
                      r_ele_sub.id_entry = entry.id
                  ) keb_reb_group,
                  GROUP_CONCAT(DISTINCT gloss.content) gloss_group,
                  GROUP_CONCAT(DISTINCT pos.description) pos_group,
                  GROUP_CONCAT(DISTINCT dial.name) dial_group,
                  GROUP_CONCAT(DISTINCT field.name) field_group,
                  GROUP_CONCAT(DISTINCT misc.name) misc_group
                  FROM entry
                  JOIN sense ON sense.id_entry = entry.id
                  JOIN gloss ON gloss.id_sense = sense.id
                  LEFT JOIN sense_pos on sense.id = sense_pos.id_sense 
                  LEFT JOIN pos on sense_pos.id_pos = pos.id
                  LEFT JOIN sense_dial on sense.id = sense_dial.id_sense 
                  LEFT JOIN dial on sense_dial.id_dial = dial.id
                  LEFT JOIN sense_field on sense.id = sense_field.id_sense 
                  LEFT JOIN field on sense_field.id_field = field.id
                  LEFT JOIN sense_misc on sense.id = sense_misc.id_sense 
                  LEFT JOIN misc on sense_misc.id_misc = misc.id
                  WHERE entry.id IN (${subQuery(input, resultsPerPage, currentPage)})
                  GROUP BY sense.id''';

    log(sql);
    List<Map<String, dynamic>> queryResults;
    try {
      queryResults = await database!.rawQuery(sql);
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
            reading: queryResult['keb_reb_group'] != null
                ? queryResult['keb_reb_group'].split(',')
                : [],
            senses: senses));
        entryId = queryResult['entry_id'];
      }

      if (queryResult['sense_id'] != senseId) {
        glosses = [];
        senseId = queryResult['sense_id'];
        senses.add(Sense(
            glosses: glosses,
            posses: queryResult['pos_group'].split(','),
            dial: queryResult['dial_group'] != null
                ? queryResult['dial_group'].split(',')
                : [],
            misc: queryResult['misc_group'] != null
                ? queryResult['misc_group'].split(',')
                : [],
            lang: "eng"));
      }

      glosses.add(queryResult['gloss_group']);
    }

    return entries;
  }

  @override
  Future<int> count() async {
    try {
      var x = await database!.rawQuery("SELECT count(entry.id) from entry;");
      return Sqflite.firstIntValue(x) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
