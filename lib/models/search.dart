// search.dart
import 'package:fujiten/models/states/search_options_state.dart';
import 'entry.dart';

class Search {
  int totalResult;
  List<Entry> searchResults;
  bool isLoading;
  bool isLoadingNextPage;
  int page;
  int? resultsPerPageKanji;
  int? resultsPerPageExpression;
  SearchType? searchType;
  final bool hasMoreResults;
  final String searchInput; // Added search input tracking

  Search({
    this.totalResult = 0,
    this.isLoadingNextPage = false,
    this.isLoading = false,
    this.page = 0,
    this.resultsPerPageKanji,
    this.resultsPerPageExpression = 10,
    this.searchResults = const [],
    this.hasMoreResults = true,
    this.searchInput = '', // Default empty string
  });

  Search copyWith({
    bool? isLoading,
    bool? isLoadingNextPage,
    List<Entry>? searchResults,
    int? page,
    int? resultsPerPageKanji,
    int? resultsPerPageExpression,
    int? totalResult,
    bool? hasMoreResults,
    String? searchInput, // Added to copyWith
  }) {
    return Search(
      isLoading: isLoading ?? this.isLoading,
      isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
      totalResult: totalResult ?? this.totalResult,
      page: page ?? this.page,
      resultsPerPageKanji: resultsPerPageKanji ?? this.resultsPerPageKanji,
      resultsPerPageExpression:
      resultsPerPageExpression ?? this.resultsPerPageExpression,
      searchResults: searchResults ?? this.searchResults,
      hasMoreResults: hasMoreResults ?? this.hasMoreResults,
      searchInput: searchInput ?? this.searchInput,
    );
  }
}
