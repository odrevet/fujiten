class Meaning {
  final String content;
  final String lang;

  Meaning({required this.content, required this.lang});
}

class Kanji {
  final String literal;
  final int strokeCount;
  final int? freq;
  final List<String>? radicals;
  final List<String>? on;
  final List<String>? kun;
  final List<Meaning>? meanings;

  Kanji({
    required this.literal,
    required this.strokeCount,
    this.freq,
    this.radicals = const [],
    this.on = const [],
    this.kun = const [],
    this.meanings = const [],
  });

  factory Kanji.fromMap(Map<String, dynamic> map) {
    return Kanji(
      literal: map['id'],
      strokeCount: map['stroke_count'],
      freq: map['freq'],
      radicals: map['radicals']?.split(','),
      on: map['on_reading']?.split(','),
      kun: map['kun_reading']?.split(','),
      meanings: (map['meanings'] as String?)
          ?.split(',')
          .map((meaning) {
            final parts = meaning.split('|');
            return Meaning(
              content: parts[0],
              lang: parts.length > 1 ? parts[1] : '',
            );
          })
          .toList(),
    );
  }

  @override
  String toString() {
    return literal;
  }
}
