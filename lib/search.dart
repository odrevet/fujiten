import 'kanji.dart';

class Search {
  String input;
  int totalResult;
  List<Entry> searchResults = [];

  Search({this.input, this.totalResult = 0});
}

abstract class Entry {}

class ExpressionEntry extends Entry {
  String kanji;
  String reading;
  List<Sense> senses;

  ExpressionEntry({this.kanji, this.reading, this.senses});
}

class Sense {
  String glosses;
  List<String> posses;
  String lang;

  Sense({this.glosses, this.posses, this.lang});
}

class KanjiEntry extends Entry {
  Kanji kanji;

  KanjiEntry({this.kanji});
}
