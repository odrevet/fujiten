import 'package:fujiten/models/entry.dart';
import 'package:fujiten/models/kanji.dart';
import 'package:fujiten/models/sense.dart';

class FavoriteGloss {
  final String content;
  final String lang;

  FavoriteGloss({required this.content, required this.lang});

  Map<String, dynamic> toJson() => {'content': content, 'lang': lang};

  factory FavoriteGloss.fromJson(Map<String, dynamic> json) => FavoriteGloss(
    content: json['content'] as String? ?? '',
    lang: json['lang'] as String? ?? '',
  );
}

class FavoriteSense {
  final List<FavoriteGloss> glosses;
  final List<String> posses;
  final List<String> dial;
  final List<String> misc;
  final List<String> fields;

  FavoriteSense({
    required this.glosses,
    required this.posses,
    required this.dial,
    required this.misc,
    required this.fields,
  });

  Map<String, dynamic> toJson() => {
    'glosses': glosses.map((g) => g.toJson()).toList(),
    'posses': posses,
    'dial': dial,
    'misc': misc,
    'fields': fields,
  };

  factory FavoriteSense.fromJson(Map<String, dynamic> json) => FavoriteSense(
    glosses: (json['glosses'] as List? ?? [])
        .map((e) => FavoriteGloss.fromJson(e as Map<String, dynamic>))
        .toList(),
    posses: (json['posses'] as List?)?.cast<String>() ?? [],
    dial: (json['dial'] as List?)?.cast<String>() ?? [],
    misc: (json['misc'] as List?)?.cast<String>() ?? [],
    fields: (json['fields'] as List?)?.cast<String>() ?? [],
  );
}

class FavoriteMeaning {
  final String content;
  final String lang;

  FavoriteMeaning({required this.content, required this.lang});

  Map<String, dynamic> toJson() => {'content': content, 'lang': lang};

  factory FavoriteMeaning.fromJson(Map<String, dynamic> json) =>
      FavoriteMeaning(
        content: json['content'] as String? ?? '',
        lang: json['lang'] as String? ?? '',
      );
}

class Favorite {
  final String type; // 'expression' | 'kanji'

  // expression
  final List<String> reading;
  final List<FavoriteSense> senses;
  final List<String> xref;
  final List<String> ant;

  // kanji
  final String literal;
  final int strokeCount;
  final List<String> radicals;
  final List<String> on;
  final List<String> kun;
  final List<FavoriteMeaning> meanings;

  Favorite.expression({
    required this.reading,
    required this.senses,
    required this.xref,
    required this.ant,
  }) : type = 'expression',
       literal = '',
       strokeCount = 0,
       radicals = const [],
       on = const [],
       kun = const [],
       meanings = const [];

  Favorite.kanji({
    required this.literal,
    required this.strokeCount,
    this.radicals = const [],
    this.on = const [],
    this.kun = const [],
    this.meanings = const [],
  }) : type = 'kanji',
       reading = const [],
       senses = const [],
       xref = const [],
       ant = const [];

  factory Favorite.fromExpression(ExpressionEntry e) => Favorite.expression(
    reading: e.reading,
    senses: e.senses
        .map(
          (s) => FavoriteSense(
            glosses: s.glosses
                .map((g) => FavoriteGloss(content: g.content, lang: g.lang))
                .toList(),
            posses: s.posses,
            dial: s.dial,
            misc: s.misc,
            fields: s.fields,
          ),
        )
        .toList(),
    xref: e.xref,
    ant: e.ant,
  );

  factory Favorite.fromKanji(KanjiEntry e) => Favorite.kanji(
    literal: e.kanji.literal,
    strokeCount: e.kanji.strokeCount,
    radicals: e.kanji.radicals ?? [],
    on: e.kanji.on ?? [],
    kun: e.kanji.kun ?? [],
    meanings: (e.kanji.meanings ?? [])
        .map((m) => FavoriteMeaning(content: m.content, lang: m.lang))
        .toList(),
  );

  String get id => type == 'expression'
      ? (reading.isNotEmpty ? reading.join('|') : '')
      : literal;

  Entry toEntry() {
    if (type == 'expression') {
      return ExpressionEntry(
        reading: reading,
        senses: senses
            .map(
              (s) => Sense(
                glosses: s.glosses
                    .map((g) => Gloss(content: g.content, lang: g.lang))
                    .toList(),
                posses: s.posses,
                dial: s.dial,
                misc: s.misc,
                fields: s.fields,
              ),
            )
            .toList(),
        xref: xref,
        ant: ant,
      );
    }
    return KanjiEntry(
      kanji: Kanji(
        literal: literal,
        strokeCount: strokeCount,
        radicals: radicals,
        on: on,
        kun: kun,
        meanings: meanings
            .map((m) => Meaning(content: m.content, lang: m.lang))
            .toList(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'reading': reading,
    'senses': senses.map((s) => s.toJson()).toList(),
    'xref': xref,
    'ant': ant,
    'literal': literal,
    'strokeCount': strokeCount,
    'radicals': radicals,
    'on': on,
    'kun': kun,
    'meanings': meanings.map((m) => m.toJson()).toList(),
  };

  factory Favorite.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'expression';
    if (type == 'kanji') {
      return Favorite.kanji(
        literal: json['literal'] as String? ?? '',
        strokeCount: json['strokeCount'] as int? ?? 0,
        radicals: (json['radicals'] as List?)?.cast<String>() ?? [],
        on: (json['on'] as List?)?.cast<String>() ?? [],
        kun: (json['kun'] as List?)?.cast<String>() ?? [],
        meanings: (json['meanings'] as List? ?? [])
            .map((e) => FavoriteMeaning.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    return Favorite.expression(
      reading: (json['reading'] as List?)?.cast<String>() ?? [],
      senses: (json['senses'] as List? ?? [])
          .map((e) => FavoriteSense.fromJson(e as Map<String, dynamic>))
          .toList(),
      xref: (json['xref'] as List?)?.cast<String>() ?? [],
      ant: (json['ant'] as List?)?.cast<String>() ?? [],
    );
  }
}

class FavoriteList {
  final String name;
  final List<Favorite> items;

  FavoriteList({required this.name, this.items = const []});

  Map<String, dynamic> toJson() => {
    'name': name,
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory FavoriteList.fromJson(Map<String, dynamic> json) => FavoriteList(
    name: json['name'] as String? ?? '',
    items: (json['items'] as List? ?? [])
        .map((e) => Favorite.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
