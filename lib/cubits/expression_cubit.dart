import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/services/database_interface.dart';

import '../models/states/db_state_expression.dart';
import '../models/states/search_options_state.dart';
import '../services/database_interface_expression.dart';
import '../services/database_interface_factory.dart';
class ExpressionCubit extends Cubit<ExpressionState> {
  DatabaseInterfaceExpression databaseInterface;

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
            log: databaseInterface.logMessage,
          ),
        );
      } else {
        emit(ExpressionReady());
      }
    } catch (e) {
      emit(
        ExpressionError(message: 'Failed to open database: ${e.toString()}'),
      );
    }
  }

  Future<void> configure(
    DatabaseBackend backend, {
    String? url,
    String? anonKey,
    String? path,
  }) async {
    databaseInterface = createExpressionInterface(
      backend,
      url: url,
      anonKey: anonKey,
    );
    await openDatabase(path ?? '');
  }

  Future<void> search(
    String input,
    int resultsPerPage,
    int currentPage,
    SearchMode mode,
    List<String> langs,
  ) async {
    if (databaseInterface.status != DatabaseStatus.ok) {
      emit(
        ExpressionDatabaseNotReady(
          status: databaseInterface.status ?? DatabaseStatus.pathNotSet,
          log: databaseInterface.logMessage,
        ),
      );
      return;
    }

    if (input.trim().isEmpty) {
      emit(ExpressionReady());
      return;
    }

    emit(ExpressionLoading());

    try {
      final entries = await databaseInterface.search(
        input,
        resultsPerPage,
        currentPage,
        mode,
        langs,
      );
      final totalCount = await databaseInterface.count();

      emit(
        ExpressionLoaded(
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
      emit(ExpressionReady());
    } else {
      emit(ExpressionError(message: "ERROR"));
    }
  }
}
