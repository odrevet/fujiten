import 'package:fujiten/models/kanji.dart';
import 'package:fujiten/models/sense.dart';

abstract class Entry {}

class ExpressionEntry extends Entry {
  List<String> reading;
  List<Sense> senses;
  List<String> xref = [];
  List<String> ant = [];

  ExpressionEntry({
    required this.reading,
    required this.senses,
    required this.xref,
    required this.ant,
  });
}

class KanjiEntry extends Entry {
  Kanji kanji;

  KanjiEntry({required this.kanji});
}
