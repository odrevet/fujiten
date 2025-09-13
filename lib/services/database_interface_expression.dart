import 'dart:developer';

import 'package:sqflite/sqflite.dart';

import '../models/entry.dart';
import '../models/sense.dart';
import '../string_utils.dart';
import 'database_interface.dart';

class DatabaseInterfaceExpression extends DatabaseInterface {
  DatabaseInterfaceExpression({super.database});

  String subQuery(
    String input,
    int? resultsPerPage,
    int currentPage,
    bool useRegexp,
  ) {
    String sql;
    String searchOperator = useRegexp ? 'REGEXP' : 'LIKE';

    if (kanaKit.isRomaji(input)) {
      sql =
          '''SELECT DISTINCT sense.id_entry 
             FROM sense JOIN gloss ON gloss.id_sense = sense.id 
             WHERE gloss.content $searchOperator '$input' ''';
    } else {
      // if the input does not contains a kanji do not search in the reb
      var regExp = RegExp(regexKanji);
      var hasKanji = regExp.hasMatch(input);
      sql =
          '''SELECT DISTINCT entry_sub.id 
             FROM entry entry_sub
             JOIN sense sense_sub ON entry_sub.id = sense_sub.id_entry 
             JOIN r_ele on entry_sub.id = r_ele.id_entry
             LEFT JOIN k_ele ON entry_sub.id = k_ele.id_entry 
             WHERE (keb $searchOperator '$input' ${hasKanji ? "" : "OR reb $searchOperator '$input'"})''';
    }

    if (resultsPerPage != null) {
      sql += " LIMIT $resultsPerPage OFFSET ${currentPage * resultsPerPage}";
    }
    return sql;
  }

  @override
  Future<List<ExpressionEntry>> search(
    String input,
    int resultsPerPage,
    int currentPage,
    useRegexp,
  ) async {
    String sql = '''SELECT
                    entry.id AS entry_id,
                    sense.id AS sense_id,
                    GROUP_CONCAT(COALESCE(k_ele.keb || ':', '') || r_ele.reb) keb_reb_group,
                    GROUP_CONCAT(DISTINCT gloss.content) AS gloss_group,
                    GROUP_CONCAT(DISTINCT pos.name) AS pos_group,
                    GROUP_CONCAT(DISTINCT dial.name) AS dial_group,
                    GROUP_CONCAT(DISTINCT misc.name) AS misc_group,
                    GROUP_CONCAT(DISTINCT field.name) AS field_group,
                    GROUP_CONCAT(DISTINCT
                        CASE
                            WHEN sense_xref.reb IS NOT NULL
                            THEN COALESCE(sense_xref.keb, '') || ':' || sense_xref.reb
                            WHEN sense_xref.keb IS NOT NULL
                            THEN sense_xref.keb
                        END
                    ) AS xref_group,
                    GROUP_CONCAT(DISTINCT
                        CASE
                            WHEN sense_ant.reb IS NOT NULL
                            THEN COALESCE(sense_ant.keb, '') || ':' || sense_ant.reb
                            WHEN sense_ant.keb IS NOT NULL
                            THEN sense_ant.keb
                        END
                    ) AS ant_group
                FROM entry
                    JOIN r_ele ON entry.id = r_ele.id_entry
                    JOIN sense ON sense.id_entry = entry.id
                    JOIN gloss ON gloss.id_sense = sense.id
                    LEFT JOIN k_ele ON entry.id = k_ele.id_entry
                    LEFT JOIN sense_pos ON sense.id = sense_pos.id_sense
                    LEFT JOIN pos ON sense_pos.id_pos = pos.id
                    LEFT JOIN sense_dial ON sense.id = sense_dial.id_sense
                    LEFT JOIN dial ON sense_dial.id_dial = dial.id
                    LEFT JOIN sense_misc ON sense.id = sense_misc.id_sense
                    LEFT JOIN misc ON sense_misc.id_misc = misc.id
                    LEFT JOIN sense_field ON sense.id = sense_field.id_sense
                    LEFT JOIN field ON sense_field.id_field = field.id
                    LEFT JOIN sense_xref ON sense.id = sense_xref.id_sense
                    LEFT JOIN sense_ant ON sense.id = sense_ant.id_sense
                WHERE entry.id IN (${subQuery(input, resultsPerPage, currentPage, useRegexp)})
                GROUP BY entry.id, sense.id;''';
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
        entries.add(
          ExpressionEntry(
            reading: queryResult['keb_reb_group'] != null
                ? queryResult['keb_reb_group'].split(',')
                : [],
            senses: senses,
            xref:  queryResult['xref_group'] != null ? queryResult['xref_group'].split(',') : [],
            ant:  queryResult['ant_group'] != null ? queryResult['ant_group'].split(',') : [],
          ),
        );
        entryId = queryResult['entry_id'];
      }

      if (queryResult['sense_id'] != senseId) {
        glosses = [];
        senseId = queryResult['sense_id'];
        senses.add(
          Sense(
            glosses: glosses,
            posses: queryResult['pos_group'].split(','),
            dial: queryResult['dial_group'] != null
                ? queryResult['dial_group'].split(',')
                : [],
            misc: queryResult['misc_group'] != null
                ? queryResult['misc_group'].split(',')
                : [],
            lang: "eng",
          ),
        );
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
