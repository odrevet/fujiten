import 'package:equatable/equatable.dart';


enum SearchType { expression, kanji }

// SearchOptions state class
class SearchOptionsState extends Equatable {
  final bool useRegexp;
  final int resultsPerPageKanji;
  final int resultsPerPageExpression;
  final SearchType searchType;

  const SearchOptionsState({
    required this.useRegexp,
    required this.resultsPerPageKanji,
    required this.resultsPerPageExpression,
    required this.searchType,
  });

  // Default constructor with initial values
  const SearchOptionsState.initial()
      : useRegexp = false,
        resultsPerPageKanji = 20,
        resultsPerPageExpression = 20,
        searchType = SearchType.expression;

  // CopyWith method for immutable state updates
  SearchOptionsState copyWith({
    bool? useRegexp,
    int? resultsPerPageKanji,
    int? resultsPerPageExpression,
    SearchType? searchType,
  }) {
    return SearchOptionsState(
      useRegexp: useRegexp ?? this.useRegexp,
      resultsPerPageKanji: resultsPerPageKanji ?? this.resultsPerPageKanji,
      resultsPerPageExpression: resultsPerPageExpression ?? this.resultsPerPageExpression,
      searchType: searchType ?? this.searchType,
    );
  }

  @override
  List<Object> get props => [
    useRegexp,
    resultsPerPageKanji,
    resultsPerPageExpression,
    searchType,
  ];
}