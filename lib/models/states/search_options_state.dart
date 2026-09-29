import 'package:equatable/equatable.dart';

enum SearchType { expression, kanji }

// SearchOptions state class
class SearchOptionsState extends Equatable {
  final bool useRegexp;
  final int resultsPerPageKanji;
  final int resultsPerPageExpression;
  final SearchType searchType;
  final List<String> selectedLangsExpression;
  final List<String> selectedLangsKanji;

  const SearchOptionsState({
    required this.useRegexp,
    required this.resultsPerPageKanji,
    required this.resultsPerPageExpression,
    required this.searchType,
    required this.selectedLangsExpression,
    required this.selectedLangsKanji,
  });

  // Default constructor with initial values
  const SearchOptionsState.initial()
    : useRegexp = false,
      resultsPerPageKanji = 20,
      resultsPerPageExpression = 20,
      searchType = SearchType.expression,
      selectedLangsExpression = const [],
      selectedLangsKanji = const [];

  // CopyWith method for immutable state updates
  SearchOptionsState copyWith({
    bool? useRegexp,
    int? resultsPerPageKanji,
    int? resultsPerPageExpression,
    SearchType? searchType,
    List<String>? selectedLangsExpression,
    List<String>? selectedLangsKanji,
  }) {
    return SearchOptionsState(
      useRegexp: useRegexp ?? this.useRegexp,
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
    useRegexp,
    resultsPerPageKanji,
    resultsPerPageExpression,
    searchType,
    selectedLangsExpression,
    selectedLangsKanji,
  ];
}
