import 'kanji.dart';

class Search {
  String input;
  int totalResult;
  List<Entry> searchResults;
  bool isLoading;
  bool isLoadingNextPage;

  Search(
      {this.input = '',
      this.totalResult = 0,
      this.isLoadingNextPage = false,
      this.isLoading = false,
      this.searchResults = const []});

  Search copyWith(
      {String? input,
      bool? isLoading,
      bool? isLoadingNextPage,
      List<Entry>? searchResults,
      int? totalResult}) {
    return Search(
        input: input ?? this.input,
        isLoading: isLoading ?? this.isLoading,
        isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
        totalResult: totalResult ?? this.totalResult,
        searchResults: searchResults ?? this.searchResults);
  }
}

abstract class Entry {}

class ExpressionEntry extends Entry {
  List<String>? kanji;
  List<String> reading;
  List<Sense> senses;

  ExpressionEntry({this.kanji, required this.reading, required this.senses});
}

class Sense {
  List<String> glosses;
  List<String> posses;
  List<String> dial;
  List<String> misc;
  String lang;

  Sense(
      {required this.glosses,
      required this.posses,
      required this.dial,
      required this.misc,
      this.lang = "eng"});
}

class KanjiEntry extends Entry {
  Kanji kanji;

  KanjiEntry({required this.kanji});
}
