class Gloss {
  final String content;
  final String lang;

  Gloss({required this.content, required this.lang});
}

class Sense {
  List<Gloss> glosses;
  List<String> posses;
  List<String> dial;
  List<String> misc;
  List<String> fields;

  Sense({
    required this.glosses,
    required this.posses,
    required this.dial,
    required this.misc,
    required this.fields,
  });
}
