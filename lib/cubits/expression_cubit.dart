import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/services/database_interface.dart';

import '../models/db_state_expression.dart';
import '../services/database_interface_expression.dart';

class ExpressionCubit extends Cubit<ExpressionState> {
  final DatabaseInterfaceExpression databaseInterface;

  ExpressionCubit(this.databaseInterface) : super(ExpressionInitial());

  Future<void> openDatabase(String path) async {
    emit(ExpressionLoading());

    try {
      await databaseInterface.open(path);
      await databaseInterface.setStatus();

      if (databaseInterface.status != DatabaseStatus.ok) {
        emit(
          ExpressionDatabaseNotReady(
            status: databaseInterface.status!,
            log: databaseInterface.log,
          ),
        );
      } else {
        emit(ExpressionInitial());
      }
    } catch (e) {
      emit(
        ExpressionError(message: 'Failed to open database: ${e.toString()}'),
      );
    }
  }

  Future<void> search(
    String input, {
    int? resultsPerPage = 10,
    int currentPage = 0,
  }) async {
    if (databaseInterface.status != DatabaseStatus.ok) {
      emit(
        ExpressionDatabaseNotReady(
          status: databaseInterface.status ?? DatabaseStatus.pathNotSet,
          log: databaseInterface.log,
        ),
      );
      return;
    }

    if (input.trim().isEmpty) {
      emit(ExpressionInitial());
      return;
    }

    emit(ExpressionLoading());

    try {
      final entries = await databaseInterface.search(
        input,
        resultsPerPage,
        currentPage,
      );
      final totalCount = await databaseInterface.count();

      emit(
        ExpressionReady(
          entries: entries,
          totalCount: totalCount,
          query: input,
          currentPage: currentPage,
          resultsPerPage: resultsPerPage,
        ),
      );
    } catch (e) {
      emit(ExpressionError(message: 'Search failed: ${e.toString()}'));
    }
  }

  Future<void> loadNextPage() async {
    final currentState = state;
    if (currentState is ExpressionReady) {
      await search(
        currentState.query,
        resultsPerPage: currentState.resultsPerPage,
        currentPage: currentState.currentPage + 1,
      );
    }
  }

  Future<void> loadPreviousPage() async {
    final currentState = state;
    if (currentState is ExpressionReady && currentState.currentPage > 0) {
      await search(
        currentState.query,
        resultsPerPage: currentState.resultsPerPage,
        currentPage: currentState.currentPage - 1,
      );
    }
  }

  Future<void> refreshSearch() async {
    final currentState = state;
    if (currentState is ExpressionReady) {
      await search(
        currentState.query,
        resultsPerPage: currentState.resultsPerPage,
        currentPage: currentState.currentPage,
      );
    }
  }

  void clearSearch() {
    emit(ExpressionInitial());
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
      emit(ExpressionInitial());
    } else {
      emit(ExpressionError(message: "ERROR"));
    }
  }
}
