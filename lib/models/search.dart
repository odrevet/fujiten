import 'entry.dart';

class Search {
  String input;
  int totalResult;
  List<Entry> searchResults;
  bool isLoading;
  bool isLoadingNextPage;
  int page;
  int resultsPerPage;

  Search(
      {this.input = '',
      this.totalResult = 0,
      this.isLoadingNextPage = false,
      this.isLoading = false,
      this.page = 0,
      this.resultsPerPage = 20,
      this.searchResults = const []});

  Search copyWith(
      {String? input,
      bool? isLoading,
      bool? isLoadingNextPage,
      List<Entry>? searchResults,
      int? page,
      int? resultsPerPage,
      int? totalResult}) {
    return Search(
        input: input ?? this.input,
        isLoading: isLoading ?? this.isLoading,
        isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
        totalResult: totalResult ?? this.totalResult,
        page: page ?? this.page,
        resultsPerPage: resultsPerPage ?? this.resultsPerPage,
        searchResults: searchResults ?? this.searchResults);
  }
}
