import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/services/database_interface.dart';

import '../models/db_state_kanji.dart';
import '../services/database_interface_kanji.dart';

class KanjiCubit extends Cubit<KanjiState> {
  final DatabaseInterfaceKanji databaseInterface;

  KanjiCubit(this.databaseInterface) : super(KanjiInitial());

  Future<void> openDatabase(String path) async {
    emit(KanjiLoading());

    try {
      await databaseInterface.open(path);
      await databaseInterface.setStatus();

      if (databaseInterface.status != DatabaseStatus.ok) {
        emit(
          KanjiDatabaseNotReady(
            status: databaseInterface.status!,
            log: databaseInterface.log,
          ),
        );
      } else {
        emit(KanjiReady());
      }
    } catch (e) {
      emit(KanjiError(message: 'Failed to open database: ${e.toString()}'));
    }
  }

  Future<void> search(
    String input, {
    int? resultsPerPage = 10,
    int currentPage = 0,
  }) async {
    if (databaseInterface.status != DatabaseStatus.ok) {
      emit(
        KanjiDatabaseNotReady(
          status: databaseInterface.status ?? DatabaseStatus.pathNotSet,
          log: databaseInterface.log,
        ),
      );
      return;
    }

    if (input.trim().isEmpty) {
      emit(KanjiInitial());
      return;
    }

    emit(KanjiLoading());

    try {
      final entries = await databaseInterface.search(
        input,
        resultsPerPage,
        currentPage,
      );
      final totalCount = await databaseInterface.count();

      emit(
        KanjiLoaded(
          entries: entries,
          totalCount: totalCount,
          query: input,
          currentPage: currentPage,
          resultsPerPage: resultsPerPage,
        ),
      );
    } catch (e) {
      emit(KanjiError(message: 'Search failed: ${e.toString()}'));
    }
  }

  Future<void> loadCharactersFromLiterals(List<String> characters) async {
    if (databaseInterface.status != DatabaseStatus.ok) {
      emit(
        KanjiDatabaseNotReady(
          status: databaseInterface.status ?? DatabaseStatus.pathNotSet,
          log: databaseInterface.log,
        ),
      );
      return;
    }

    emit(KanjiLoading());

    try {
      final kanjiList = await databaseInterface.getCharactersFromLiterals(
        characters,
      );
      emit(KanjiCharactersLoaded(characters: kanjiList));
    } catch (e) {
      emit(KanjiError(message: 'Failed to load characters: ${e.toString()}'));
    }
  }

  Future<void> searchByRadicals(List<String> radicals) async {
    if (databaseInterface.status != DatabaseStatus.ok) {
      emit(
        KanjiDatabaseNotReady(
          status: databaseInterface.status ?? DatabaseStatus.pathNotSet,
          log: databaseInterface.log,
        ),
      );
      return;
    }

    emit(KanjiLoading());

    try {
      final characters = await databaseInterface.getCharactersFromRadicals(
        radicals,
      );
      emit(
        KanjiRadicalSearchLoaded(
          characters: characters,
          selectedRadicals: radicals,
        ),
      );
    } catch (e) {
      emit(KanjiError(message: 'Radical search failed: ${e.toString()}'));
    }
  }

  Future<void> loadRadicals({List<String> selectedRadicals = const []}) async {
    if (databaseInterface.status != DatabaseStatus.ok) {
      emit(
        KanjiDatabaseNotReady(
          status: databaseInterface.status ?? DatabaseStatus.pathNotSet,
          log: databaseInterface.log,
        ),
      );
      return;
    }

    emit(KanjiLoading());

    try {
      final radicals = await databaseInterface.getRadicals();
      List<String> availableRadicals;

      if (selectedRadicals.isEmpty) {
        // Get all radicals if none selected
        final allRadicalCharacters = await databaseInterface
            .getRadicalsCharacter();
        availableRadicals = allRadicalCharacters.whereType<String>().toList();
      } else {
        // Get radicals that can be combined with selected ones
        final compatibleRadicals = await databaseInterface
            .getRadicalsForSelection(selectedRadicals);
        availableRadicals = compatibleRadicals.whereType<String>().toList();
      }

      emit(
        KanjiRadicalsLoaded(
          radicals: radicals,
          availableRadicals: availableRadicals,
          selectedRadicals: selectedRadicals,
        ),
      );
    } catch (e) {
      emit(KanjiError(message: 'Failed to load radicals: ${e.toString()}'));
    }
  }

  Future<void> addRadicalToSelection(String radical) async {
    final currentState = state;
    if (currentState is KanjiRadicalsLoaded) {
      final newSelection = [...currentState.selectedRadicals, radical];
      await loadRadicals(selectedRadicals: newSelection);
    }
  }

  Future<void> removeRadicalFromSelection(String radical) async {
    final currentState = state;
    if (currentState is KanjiRadicalsLoaded) {
      final newSelection = currentState.selectedRadicals
          .where((r) => r != radical)
          .toList();
      await loadRadicals(selectedRadicals: newSelection);
    }
  }

  Future<void> clearRadicalSelection() async {
    await loadRadicals();
  }

  Future<void> loadNextPage() async {
    final currentState = state;
    if (currentState is KanjiLoaded) {
      await search(
        currentState.query,
        resultsPerPage: currentState.resultsPerPage,
        currentPage: currentState.currentPage + 1,
      );
    }
  }

  Future<void> loadPreviousPage() async {
    final currentState = state;
    if (currentState is KanjiLoaded && currentState.currentPage > 0) {
      await search(
        currentState.query,
        resultsPerPage: currentState.resultsPerPage,
        currentPage: currentState.currentPage - 1,
      );
    }
  }

  Future<void> refreshSearch() async {
    final currentState = state;
    if (currentState is KanjiLoaded) {
      await search(
        currentState.query,
        resultsPerPage: currentState.resultsPerPage,
        currentPage: currentState.currentPage,
      );
    }
  }

  void clearSearch() {
    emit(KanjiInitial());
  }

  Future<void> dispose() async {
    await databaseInterface.dispose();
  }

  @override
  Future<void> close() async {
    await dispose();
    return super.close();
  }

  void refreshDatabaseStatus() async {
    await databaseInterface.setStatus();

    if (databaseInterface.status == DatabaseStatus.ok) {
      emit(KanjiReady());
    }
    else{
      emit(KanjiError(message: "ERROR"));
    }
  }

}
