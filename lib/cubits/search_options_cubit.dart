import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/states/search_options_state.dart';

class SearchOptionsCubit extends Cubit<SearchOptionsState> {
  SearchOptionsCubit() : super(const SearchOptionsState.initial());

  // Update useRegexp
  void setUseRegexp(bool value) {
    emit(state.copyWith(useRegexp: value));
  }

  // Update resultsPerPageKanji
  void setResultsPerPageKanji(int value) {
    emit(state.copyWith(resultsPerPageKanji: value));
  }

  // Update resultsPerPageExpression
  void setResultsPerPageExpression(int value) {
    emit(state.copyWith(resultsPerPageExpression: value));
  }

  // Update searchType
  void setSearchType(SearchType type) {
    emit(state.copyWith(searchType: type));
  }

  // Update selected languages for expression
  void setSelectedLangsExpression(List<String> langs) {
    emit(state.copyWith(selectedLangsExpression: langs));
  }

  // Update selected languages for kanji
  void setSelectedLangsKanji(List<String> langs) {
    emit(state.copyWith(selectedLangsKanji: langs));
  }

  // Update multiple fields at once
  void updateSearchOptions({
    bool? useRegexp,
    int? resultsPerPageKanji,
    int? resultsPerPageExpression,
    SearchType? searchType,
    List<String>? selectedLangsExpression,
    List<String>? selectedLangsKanji,
  }) {
    emit(
      state.copyWith(
        useRegexp: useRegexp,
        resultsPerPageKanji: resultsPerPageKanji,
        resultsPerPageExpression: resultsPerPageExpression,
        searchType: searchType,
        selectedLangsExpression: selectedLangsExpression,
        selectedLangsKanji: selectedLangsKanji,
      ),
    );
  }

  // Reset to initial state
  void reset() {
    emit(const SearchOptionsState.initial());
  }

  // Get current results per page based on search type
  int get currentResultsPerPage {
    switch (state.searchType) {
      case SearchType.kanji:
        return state.resultsPerPageKanji;
      case SearchType.expression:
        return state.resultsPerPageExpression;
    }
  }

  void toggleSearchType() => emit(
    state.copyWith(
      searchType: state.searchType == SearchType.kanji
          ? SearchType.expression
          : SearchType.kanji,
    ),
  );
}
