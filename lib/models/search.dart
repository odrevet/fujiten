import 'entry.dart';

enum SearchType { expression, kanji }

class Search {
  String input;
  int totalResult;
  List<Entry> searchResults;
  bool isLoading;
  bool isLoadingNextPage;
  int page;
  int resultsPerPage;
  SearchType? searchType;

  Search(
      {this.input = '',
      this.totalResult = 0,
      this.isLoadingNextPage = false,
      this.isLoading = false,
      this.page = 0,
      this.resultsPerPage = 20,
      this.searchResults = const [],
      this.searchType});

  Search copyWith(
      {String? input,
      bool? isLoading,
      bool? isLoadingNextPage,
      List<Entry>? searchResults,
      int? page,
      int? resultsPerPage,
      int? totalResult,
      SearchType? searchType}) {
    return Search(
        input: input ?? this.input,
        isLoading: isLoading ?? this.isLoading,
        isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
        totalResult: totalResult ?? this.totalResult,
        page: page ?? this.page,
        resultsPerPage: resultsPerPage ?? this.resultsPerPage,
        searchType: searchType ?? this.searchType,
        searchResults: searchResults ?? this.searchResults);
  }
}
