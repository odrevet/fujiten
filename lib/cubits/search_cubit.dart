import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';

import '../models/search.dart';
import '../services/database.dart';

class SearchCubit extends Cubit<Search> {
  SearchCubit()
      : super(Search(
            input: '',
            isLoading: false,
            isLoadingNextPage: false,
            searchResults: [],
            totalResult: 0));

  void reset() => emit(Search(
      input: '', searchResults: [], isLoading: false, isLoadingNextPage: false, totalResult: 0));

  void runSearch(
      String formattedInput, bool kanjiSearch, Database database) {
    emit(state.copyWith(
        input: formattedInput,
        isLoading: true,
        isLoadingNextPage: false,
        totalResult: 0,
        searchResults: []));

    Function searchFunction = kanjiSearch ? searchKanji : searchExpression;
    searchFunction(database, formattedInput, 10, 0).then((searchResults) {
      emit(state.copyWith(
          isLoading: false,
          totalResult: searchResults.length,
          searchResults: searchResults));
    });
  }
}
