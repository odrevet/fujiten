class Meaning {
  String meaning;

  Meaning({required this.meaning});
}

class Kanji {
  final String character;
  final int stroke;
  final List<String>? radicals;
  final List<String>? on;
  final List<String>? kun;
  final List<String>? meanings;

  Kanji(
      {required this.character,
      required this.stroke,
      this.radicals = const [],
      this.on = const [],
      this.kun = const [],
      this.meanings = const []});

  factory Kanji.fromMap(Map<String, dynamic> map) {
    return Kanji(
      character: map['id'],
      stroke: map['stroke_count'],
      radicals: map['radicals']?.split(','),
      on: map['on_reading']?.split(','),
      kun: map['kun_reading']?.split(','),
      meanings: map['meanings']?.split(','),
    );
  }

  @override
  String toString() {
    return character;
  }
}
