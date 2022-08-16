import 'entry.dart';

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
