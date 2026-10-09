import 'package:equatable/equatable.dart';

enum SearchType { expression, kanji }

enum SearchMode { raw, regexp, glob }

// SearchOptions state class
class SearchOptionsState extends Equatable {
  final SearchMode expressionSearchMode;
  final SearchMode kanjiSearchMode;
  final int resultsPerPageKanji;
  final int resultsPerPageExpression;
  final SearchType searchType;
  final List<String> selectedLangsExpression;
  final List<String> selectedLangsKanji;

  const SearchOptionsState({
    required this.expressionSearchMode,
    required this.kanjiSearchMode,
    required this.resultsPerPageKanji,
    required this.resultsPerPageExpression,
    required this.searchType,
    required this.selectedLangsExpression,
    required this.selectedLangsKanji,
  });

  // Default constructor with initial values
  const SearchOptionsState.initial()
    : expressionSearchMode = SearchMode.regexp,
      kanjiSearchMode = SearchMode.regexp,
      resultsPerPageKanji = 20,
      resultsPerPageExpression = 20,
      searchType = SearchType.expression,
      selectedLangsExpression = const [],
      selectedLangsKanji = const [];

  // CopyWith method for immutable state updates
  SearchOptionsState copyWith({
    SearchMode? expressionSearchMode,
    SearchMode? kanjiSearchMode,
    int? resultsPerPageKanji,
    int? resultsPerPageExpression,
    SearchType? searchType,
    List<String>? selectedLangsExpression,
    List<String>? selectedLangsKanji,
  }) {
    return SearchOptionsState(
      expressionSearchMode:
          expressionSearchMode ?? this.expressionSearchMode,
      kanjiSearchMode: kanjiSearchMode ?? this.kanjiSearchMode,
      resultsPerPageKanji: resultsPerPageKanji ?? this.resultsPerPageKanji,
      resultsPerPageExpression:
          resultsPerPageExpression ?? this.resultsPerPageExpression,
      searchType: searchType ?? this.searchType,
      selectedLangsExpression:
          selectedLangsExpression ?? this.selectedLangsExpression,
      selectedLangsKanji: selectedLangsKanji ?? this.selectedLangsKanji,
    );
  }

  @override
  List<Object> get props => [
    expressionSearchMode,
    kanjiSearchMode,
    resultsPerPageKanji,
    resultsPerPageExpression,
    searchType,
    selectedLangsExpression,
    selectedLangsKanji,
  ];
}
