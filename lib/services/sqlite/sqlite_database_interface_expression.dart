

import 'dart:developer';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../models/entry.dart';
import '../../models/sense.dart';
import '../../models/states/search_options_state.dart';
import '../../string_utils.dart';
import '../database_interface.dart';
import '../database_interface_expression.dart';

class SqliteDatabaseInterfaceExpression extends DatabaseInterfaceExpression {
  Database? database;

  SqliteDatabaseInterfaceExpression({this.database});

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

  String subQuery(
    String input,
    int? resultsPerPage,
    int currentPage,
    SearchMode mode,
    List<String> langs,
  ) {
    String sql;
    String langFilter = langs.isEmpty
        ? ''
        : "AND lang.iso3 IN (${langs.map((l) => "'$l'").join(',')})";

    if (kanaKit.isRomaji(input)) {
      sql = '''SELECT DISTINCT sense.id_entry 
             FROM sense JOIN gloss ON gloss.id_sense = sense.id 
             JOIN lang ON gloss.id_lang = lang.id
             WHERE ${_matchCondition('gloss.content', mode, input)} $langFilter''';
    } else {
      var regExp = RegExp(matchKanji);
      var hasKanji = regExp.hasMatch(input);
      sql = '''SELECT DISTINCT entry_sub.id 
             FROM entry entry_sub
             JOIN sense sense_sub ON entry_sub.id = sense_sub.id_entry 
             JOIN r_ele on entry_sub.id = r_ele.id_entry
             LEFT JOIN k_ele ON entry_sub.id = k_ele.id_entry 
             WHERE (${_matchCondition('keb', mode, input)} ${hasKanji ? "" : "OR ${_matchCondition('reb', mode, input)}"})''';
    }

    if (resultsPerPage != null) {
      sql += " LIMIT $resultsPerPage OFFSET ${currentPage * resultsPerPage}";
    }
    return sql;
  }

  @override
  Future<List<String>> getAvailableLangs() async {
    try {
      final results = await database!.rawQuery(
        'SELECT iso3 FROM lang ORDER BY id',
      );
      return results.map((row) => row['iso3'] as String).toList();
    } catch (e) {
      log('getAvailableLangs expression: $e');
      return [];
    }
  }

  @override
  Future<List<ExpressionEntry>> search(
    String input,
    int resultsPerPage,
    int currentPage,
    SearchMode mode,
    List<String> langs,
  ) async {
    String sql =
    '''SELECT
                    entry.id AS entry_id,
                    sense.id AS sense_id,
                    GROUP_CONCAT(DISTINCT COALESCE(k_ele.keb || ':', '') || r_ele.reb) keb_reb_group,
                    GROUP_CONCAT(DISTINCT gloss.content || '|' || lang.iso3) AS gloss_group,
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
                    JOIN lang ON gloss.id_lang = lang.id
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
                WHERE entry.id IN (${subQuery(input, resultsPerPage, currentPage, mode, langs)})
                ${langs.isEmpty ? '' : "AND lang.iso3 IN (${langs.map((l) => "'$l'").join(',')})"}
                GROUP BY entry.id, sense.id;''';
    List<Map<String, dynamic>> queryResults;
    try {
      queryResults = await database!.rawQuery(sql);
    } catch (e) {
      log('search expression: $e');
      return [];
    }

    int? entryId;
    int? senseId;
    List<ExpressionEntry> entries = [];
    List<Gloss> glosses = [];
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
            xref: queryResult['xref_group'] != null
                ? queryResult['xref_group'].split(',')
                : [],
            ant: queryResult['ant_group'] != null
                ? queryResult['ant_group'].split(',')
                : [],
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
            fields: queryResult['field_group'] != null
                ? queryResult['field_group'].split(',')
                : [],
          ),
        );
      }

      if (queryResult['gloss_group'] != null) {
        for (var gloss in queryResult['gloss_group'].split(',')) {
          final parts = gloss.split('|');
          glosses.add(
            Gloss(
              content: parts[0],
              lang: parts.length > 1 ? parts[1] : '',
            ),
          );
        }
      }
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

  @override
  Future<bool> isRegexpAvailable() async {
    try {
      await database!.rawQuery(
        "SELECT id FROM gloss WHERE content REGEXP '.*' LIMIT 1",
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isGlobAvailable() async => true;
}
