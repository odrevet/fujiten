import '../models/entry.dart';
import '../models/states/search_options_state.dart';

enum DatabaseStatus { ok, pathNotSet, noResults, error, loading }

enum DatabaseBackend { sqlite, postgres }

abstract class DatabaseInterface {
  DatabaseStatus? status;
  String? logMessage;

  DatabaseBackend get backend;

  bool get isOpen;

  Future<void> open(String path);

  Future<void> dispose();

  Future<List<Entry>> search(
    String input,
    int resultsPerPage,
    int currentPage,
    SearchMode mode,
    List<String> langs,
  );

  Future<List<String>> getAvailableLangs();

  Future<int> count();

  Future<void> setStatus() async {
    if (!isOpen) {
      status = DatabaseStatus.pathNotSet;
      logMessage = 'No services selected';
    } else {
      int nbEntries = await count();
      if (nbEntries == 0) {
        status = DatabaseStatus.noResults;
        logMessage = 'No entry found in services';
      } else {
        status = DatabaseStatus.ok;
        logMessage = 'Database loaded';
      }
    }
  }

  Future<bool> isRegexpAvailable() async => true;

  Future<bool> isGlobAvailable() async => true;
}
