import '../models/entry.dart';
import '../models/kanji.dart';
import '../models/states/search_options_state.dart';
import 'database_interface.dart';

abstract class DatabaseInterfaceKanji extends DatabaseInterface {
  DatabaseInterfaceKanji();

  @override
  Future<List<KanjiEntry>> search(
    String input, [
    int? resultsPerPage,
    int currentPage = 0,
    SearchMode mode = SearchMode.raw,
    List<String> langs = const [],
  ]);

  Future<List<Kanji>> getCharactersFromLiterals(List<String> characters);

  Future<List<String>> getCharactersFromRadicals(List<String> radicals);

  Future<List<Kanji>> getRadicals();

  Future<List<String?>> getRadicalsCharacter();

  Future<List<String?>> getRadicalsForSelection(List<String> selectedRadicals);
}
