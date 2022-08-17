import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:japanese_dictionary/services/database_interface.dart';

import '../models/search.dart';

class SearchCubit extends Cubit<Search> {
  SearchCubit() : super(Search());

  void reset() => emit(state.copyWith(
      input: '', searchResults: [], isLoading: false, isLoadingNextPage: false, totalResult: 0));

  void setInput(String input) => emit(state.copyWith(input: input));

  void nextPage() {
    emit(state.copyWith(page: ++state.page, isLoadingNextPage: true));
  }

  void runSearch(DatabaseInterface databaseInterface) {
    emit(state.copyWith(
      isLoading: true,
    ));

    databaseInterface.search(state.input, state.resultsPerPage, state.page).then((searchResults) {
      emit(state.copyWith(
          isLoading: false,
          isLoadingNextPage: false,
          totalResult: searchResults.length,
          searchResults: [...state.searchResults, ...searchResults]));
    });
  }

  void toggleSearchType() => emit(state.copyWith(
      searchType: state.searchType == SearchType.kanji ? SearchType.expression : SearchType.kanji));
}
