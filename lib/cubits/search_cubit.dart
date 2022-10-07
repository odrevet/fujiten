import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/services/database_interface.dart';

import '../models/search.dart';

class SearchCubit extends Cubit<Search> {
  SearchCubit() : super(Search());

  void reset() => emit(state.copyWith(
      searchResults: [], isLoading: false, isLoadingNextPage: false, totalResult: 0, page: 0));

  void setInput(String input) {
    var inputs = [...state.inputs];
    inputs[state.searchIndex] = input;
    emit(state.copyWith(input: inputs));
  }

  void setFormattedInput(String input) {
    emit(state.copyWith(formattedInput: input));
  }

  void addInput() => emit(state.copyWith(input: [...state.inputs, '']));

  void removeInput(int at) => emit(state.copyWith(input: [...state.inputs]..removeAt(at)));

  void setSearchIndex(int searchIndex) => emit(state.copyWith(searchIndex: searchIndex));

  void nextPage() {
    emit(state.copyWith(page: ++state.page, isLoadingNextPage: true));
  }

  void runSearch(DatabaseInterface databaseInterface) {
    emit(state.copyWith(
      isLoading: true,
    ));

    databaseInterface
        .search(state.formattedInput, state.resultsPerPage, state.page)
        .then((searchResults) {
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
