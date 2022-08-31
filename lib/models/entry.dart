import 'package:fujiten/models/kanji.dart';
import 'package:fujiten/models/sense.dart';

abstract class Entry {}

class ExpressionEntry extends Entry {
  List<String> reading;
  List<Sense> senses;

  ExpressionEntry({required this.reading, required this.senses});
}

class KanjiEntry extends Entry {
  Kanji kanji;

  KanjiEntry({required this.kanji});
}
