import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';

import '../models/search.dart';
import '../services/queries.dart';

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
      String formattedInput, bool kanjiSearch, Database? dbKanji, Database? dbExpression) {
    emit(state.copyWith(
        input: formattedInput,
        isLoading: true,
        isLoadingNextPage: false,
        totalResult: 0,
        searchResults: []));

    if (kanjiSearch) {
      searchKanji(dbKanji!, formattedInput, 10, 0).then((searchResults) {
        emit(state.copyWith(
            isLoading: false,
            isLoadingNextPage: false,
            totalResult: searchResults.length,
            searchResults: searchResults));
      });
    } else {
      searchExpression(dbExpression!, formattedInput, 10, 0).then((searchResults) {
        emit(state.copyWith(
            isLoading: false,
            isLoadingNextPage: false,
            totalResult: searchResults.length,
            searchResults: searchResults));
      });
    }
  }
}
