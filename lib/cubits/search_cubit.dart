import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';

import '../models/search.dart';
import '../services/database.dart';

class SearchCubit extends Cubit<Search> {
  SearchCubit() : super(Search());

  void reset() => emit(Search(
      input: '', searchResults: [], isLoading: false, isLoadingNextPage: false, totalResult: 0));

  void setInput(String input) => emit(state.copyWith(input: input));

  void nextPage() {
    emit(state.copyWith(page: ++state.page, isLoadingNextPage: true));
  }

  void runSearch(bool kanjiSearch, Database database) {
    emit(state.copyWith(
      isLoading: true,
    ));

    Function searchFunction = kanjiSearch ? searchKanji : searchExpression;
    searchFunction(database, state.input, state.resultsPerPage, state.page).then((searchResults) {
      emit(state.copyWith(
          isLoading: false,
          isLoadingNextPage: false,
          totalResult: searchResults.length,
          searchResults: [...state.searchResults, ...searchResults]));
    });
  }
}
