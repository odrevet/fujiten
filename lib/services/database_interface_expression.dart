import '../models/entry.dart';
import '../models/sense.dart';
import '../string_utils.dart';
import 'database_interface.dart';

class DatabaseInterfaceExpression extends DatabaseInterface {
  DatabaseInterfaceExpression({super.database});

  @override
  Future<List<ExpressionEntry>> search(String input, [resultsPerPage = 10, currentPage = 0]) async {
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
      // optimize the search: if the input does not contains a kanji it's useless to search in the reb
      var regExp = RegExp(regexKanji);
      var hasKanji = regExp.hasMatch(input);

      where = "WHERE (keb REGEXP '$input' ${hasKanji ? "" : "OR reb REGEXP '$input'"})";
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
}