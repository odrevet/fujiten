import 'entry.dart';

enum SearchType { expression, kanji }

class Search {
  int totalResult;
  List<Entry> searchResults;
  bool isLoading;
  bool isLoadingNextPage;
  int page;
  int? resultsPerPageKanji;
  int? resultsPerPageExpression;
  SearchType? searchType;

  Search(
      {this.totalResult = 0,
      this.isLoadingNextPage = false,
      this.isLoading = false,
      this.page = 0,
      this.resultsPerPageKanji,
      this.resultsPerPageExpression = 10,
      this.searchResults = const [],
      this.searchType});

  Search copyWith(
      {bool? isLoading,
      bool? isLoadingNextPage,
      List<Entry>? searchResults,
      int? page,
      int? resultsPerPageKanji,
      int? resultsPerPageExpression,
      int? totalResult,
      SearchType? searchType}) {
    return Search(
        isLoading: isLoading ?? this.isLoading,
        isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
        totalResult: totalResult ?? this.totalResult,
        page: page ?? this.page,
        resultsPerPageKanji: resultsPerPageKanji ?? this.resultsPerPageKanji,
        resultsPerPageExpression: resultsPerPageExpression ?? this.resultsPerPageExpression,
        searchType: searchType ?? this.searchType,
        searchResults: searchResults ?? this.searchResults);
  }
}
