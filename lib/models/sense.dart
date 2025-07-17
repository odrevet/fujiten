class Sense {
  List<String> glosses;
  List<String> posses;
  List<String> dial;
  List<String> misc;
  String lang;

  Sense({
    required this.glosses,
    required this.posses,
    required this.dial,
    required this.misc,
    this.lang = "eng",
  });
}
