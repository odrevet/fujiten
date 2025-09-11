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
    ),
  );

  void nextPage() {
    emit(state.copyWith(page: ++state.page, isLoadingNextPage: true));
  }

  void runSearch(
    DatabaseInterface databaseInterface,
    String formattedInput,
    int resultsPerPage,
    bool useRegexp,
  ) {
    emit(state.copyWith(isLoading: true));

    databaseInterface
        .search(formattedInput, resultsPerPage, state.page, useRegexp)
        .then((searchResults) {
          emit(
            state.copyWith(
              isLoading: false,
              isLoadingNextPage: false,
              totalResult: searchResults.length,
              searchResults: [...state.searchResults, ...searchResults],
            ),
          );
        });
  }
}
