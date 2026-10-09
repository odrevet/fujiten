import '../models/entry.dart';
import '../models/states/search_options_state.dart';
import 'database_interface.dart';

abstract class DatabaseInterfaceExpression extends DatabaseInterface {
  DatabaseInterfaceExpression();

  @override
  Future<List<ExpressionEntry>> search(
    String input,
    int resultsPerPage,
    int currentPage,
    SearchMode mode,
    List<String> langs,
  );
}
