import 'kanji.dart';

class Search {
  String input;
  int totalResult;
  List<Entry> searchResults = [];

  Search({required this.input, this.totalResult = 0});
}

abstract class Entry {}

class ExpressionEntry extends Entry {
  String? kanji;
  String reading;
  List<Sense> senses;

  ExpressionEntry(
      {this.kanji, required this.reading, required this.senses});
}

class Sense {
  List<String> glosses;
  List<String> posses;
  String lang;

  Sense({required this.glosses, required this.posses, required this.lang});
}

class KanjiEntry extends Entry {
  Kanji kanji;

  KanjiEntry({required this.kanji});
}
