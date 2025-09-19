import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/services/database_interface.dart';

import '../models/search.dart';

class SearchCubit extends Cubit<Search> {
  SearchCubit() : super(Search());

  void reset() => emit(
    state.copyWith(
      searchResults: [],
      isLoading: false,
      isLoadingNextPage: false,
      totalResult: 0,
      page: 0,
      hasMoreResults: true, // Reset this when starting a new search
      searchInput: '', // Reset search input
    ),
  );

  void nextPage() {
    // Only increment page if there are more results to load
    if (state.hasMoreResults && !state.isLoadingNextPage) {
      emit(state.copyWith(page: state.page + 1, isLoadingNextPage: true));
    }
  }

  void runSearch(
      DatabaseInterface databaseInterface,
      String formattedInput,
      int resultsPerPage,
      bool useRegexp,
      ) {
    // Don't run search if we know there are no more results
    if (state.page > 0 && !state.hasMoreResults) {
      return;
    }

    emit(state.copyWith(
      isLoading: state.page == 0,
      isLoadingNextPage: state.page > 0,
      searchInput: formattedInput, // Update search input
    ));

    databaseInterface
        .search(formattedInput, resultsPerPage, state.page, useRegexp)
        .then((searchResults) {
      // Check if we got fewer results than requested, indicating end of results
      final hasMoreResults = searchResults.length == resultsPerPage;

      emit(
        state.copyWith(
          isLoading: false,
          isLoadingNextPage: false,
          totalResult: state.searchResults.length + searchResults.length,
          searchResults: [...state.searchResults, ...searchResults],
          hasMoreResults: hasMoreResults,
        ),
      );
    });
  }
}