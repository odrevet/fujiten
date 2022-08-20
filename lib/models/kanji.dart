class Meaning {
  String meaning;

  Meaning({required this.meaning});
}

class Kanji {
  final String literal;
  final int strokeCount;
  final List<String>? radicals;
  final List<String>? on;
  final List<String>? kun;
  final List<String>? meanings;

  Kanji(
      {required this.literal,
      required this.strokeCount,
      this.radicals = const [],
      this.on = const [],
      this.kun = const [],
      this.meanings = const []});

  factory Kanji.fromMap(Map<String, dynamic> map) {
    return Kanji(
      literal: map['id'],
      strokeCount: map['stroke_count'],
      radicals: map['radicals']?.split(','),
      on: map['on_reading']?.split(','),
      kun: map['kun_reading']?.split(','),
      meanings: map['meanings']?.split(','),
    );
  }

  @override
  String toString() {
    return literal;
  }
}
