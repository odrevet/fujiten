import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/services/database_interface.dart';

import '../models/search.dart';

class SearchCubit extends Cubit<Search> {
  SearchCubit() : super(Search());

  void reset() => emit(state.copyWith(
      searchResults: [],
      isLoading: false,
      isLoadingNextPage: false,
      totalResult: 0,
      page: 0));

  void nextPage() {
    emit(state.copyWith(page: ++state.page, isLoadingNextPage: true));
  }

  void runSearch(DatabaseInterface databaseInterface, String formattedInput) {
    emit(state.copyWith(
      isLoading: true,
    ));

    databaseInterface
        .search(
            formattedInput,
            state.searchType == SearchType.kanji
                ? state.resultsPerPageKanji
                : state.resultsPerPageExpression,
            state.page)
        .then((searchResults) {
      emit(state.copyWith(
          isLoading: false,
          isLoadingNextPage: false,
          totalResult: searchResults.length,
          searchResults: [...state.searchResults, ...searchResults]));
    });
  }

  void toggleSearchType() => emit(state.copyWith(
      searchType: state.searchType == SearchType.kanji
          ? SearchType.expression
          : SearchType.kanji));
}
