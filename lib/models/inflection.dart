/// Japanese Verb Inflector
/// Based on verb conjugation patterns for deinflection

/// Inflection entry containing conjugation pattern
class InflectionEntry {
  final String conjugation;
  final String dictionaryForm;
  final int type;
  final String label;

  const InflectionEntry({
    required this.conjugation,
    required this.dictionaryForm,
    required this.type,
    required this.label,
  });
}

class JapaneseVerbInflector {
  /// Inflection types with their labels
  static const Map<int, String> inflectionLabels = {
    0: "plain, negative, nonpast",
    1: "polite, non-past",
    2: "conditional",
    3: "volitional",
    4: "te-form",
    5: "plain, past",
    6: "plain, negative, past",
    7: "passive",
    8: "causative",
    9: "potential or imperative",
    10: "imperative",
    11: "polite, past",
    12: "polite, negative, non-past",
    13: "polite, negative, past",
    14: "adj. -> adverb",
    15: "adj. -> adverb",
    16: "adj., past",
    17: "polite",
    18: "polite, volitional",
    19: "passive or potential",
    20: "passive (or potential if Grp 2)",
    21: "adj., negative",
    22: "adj., negative, past",
    23: "adj., past",
    24: "plain verb",
    25: "polite, te-form",
  };

  /// inflection patterns
  static const List<InflectionEntry> inflectionRules = [
    // る verb patterns
    InflectionEntry(
      conjugation: "た",
      dictionaryForm: "る",
      type: 5,
      label: "plain, past",
    ),
    InflectionEntry(
      conjugation: "て",
      dictionaryForm: "る",
      type: 4,
      label: "te-form",
    ),
    InflectionEntry(
      conjugation: "ない",
      dictionaryForm: "る",
      type: 0,
      label: "plain, negative, nonpast",
    ),
    InflectionEntry(
      conjugation: "なか",
      dictionaryForm: "る",
      type: 6,
      label: "plain, negative, past",
    ),
    InflectionEntry(
      conjugation: "ます",
      dictionaryForm: "る",
      type: 1,
      label: "polite, non-past",
    ),
    InflectionEntry(
      conjugation: "ました",
      dictionaryForm: "る",
      type: 11,
      label: "polite, past",
    ),
    InflectionEntry(
      conjugation: "ませんでした",
      dictionaryForm: "る",
      type: 13,
      label: "polite, negative, past",
    ),
    InflectionEntry(
      conjugation: "ません",
      dictionaryForm: "る",
      type: 12,
      label: "polite, negative, non-past",
    ),
    InflectionEntry(
      conjugation: "ましょう",
      dictionaryForm: "る",
      type: 18,
      label: "polite, volitional",
    ),
    InflectionEntry(
      conjugation: "れば",
      dictionaryForm: "る",
      type: 2,
      label: "conditional",
    ),
    InflectionEntry(
      conjugation: "よう",
      dictionaryForm: "る",
      type: 3,
      label: "volitional",
    ),
    InflectionEntry(
      conjugation: "られ",
      dictionaryForm: "る",
      type: 20,
      label: "passive (or potential if Grp 2)",
    ),
    InflectionEntry(
      conjugation: "させ",
      dictionaryForm: "る",
      type: 8,
      label: "causative",
    ),
    InflectionEntry(
      conjugation: "ろ",
      dictionaryForm: "る",
      type: 10,
      label: "imperative",
    ),
    InflectionEntry(
      conjugation: "らま",
      dictionaryForm: "る",
      type: 17,
      label: "polite",
    ),
    InflectionEntry(
      conjugation: "れ",
      dictionaryForm: "る",
      type: 9,
      label: "potential or imperative",
    ),

    // く verb patterns
    InflectionEntry(
      conjugation: "かない",
      dictionaryForm: "く",
      type: 0,
      label: "plain, negative, nonpast",
    ),
    InflectionEntry(
      conjugation: "かなか",
      dictionaryForm: "く",
      type: 6,
      label: "plain, negative, past",
    ),
    InflectionEntry(
      conjugation: "きます",
      dictionaryForm: "く",
      type: 1,
      label: "polite, non-past",
    ),
    InflectionEntry(
      conjugation: "きました",
      dictionaryForm: "く",
      type: 11,
      label: "polite, past",
    ),
    InflectionEntry(
      conjugation: "きまして",
      dictionaryForm: "く",
      type: 25,
      label: "polite, te-form",
    ),
    InflectionEntry(
      conjugation: "きませんでした",
      dictionaryForm: "く",
      type: 13,
      label: "polite, negative, past",
    ),
    InflectionEntry(
      conjugation: "きません",
      dictionaryForm: "く",
      type: 12,
      label: "polite, negative, non-past",
    ),
    InflectionEntry(
      conjugation: "きましょう",
      dictionaryForm: "く",
      type: 18,
      label: "polite, volitional",
    ),
    InflectionEntry(
      conjugation: "けば",
      dictionaryForm: "く",
      type: 2,
      label: "conditional",
    ),
    InflectionEntry(
      conjugation: "こう",
      dictionaryForm: "く",
      type: 3,
      label: "volitional",
    ),
    InflectionEntry(
      conjugation: "いて",
      dictionaryForm: "く",
      type: 4,
      label: "te-form",
    ),
    InflectionEntry(
      conjugation: "って",
      dictionaryForm: "く",
      type: 4,
      label: "te-form",
    ),
    InflectionEntry(
      conjugation: "いた",
      dictionaryForm: "く",
      type: 5,
      label: "plain, past",
    ),
    InflectionEntry(
      conjugation: "った",
      dictionaryForm: "く",
      type: 5,
      label: "plain, past",
    ),
    InflectionEntry(
      conjugation: "かれ",
      dictionaryForm: "く",
      type: 7,
      label: "passive",
    ),
    InflectionEntry(
      conjugation: "かせ",
      dictionaryForm: "く",
      type: 8,
      label: "causative",
    ),
    InflectionEntry(
      conjugation: "け",
      dictionaryForm: "く",
      type: 9,
      label: "potential or imperative",
    ),

    // す verb patterns
    InflectionEntry(
      conjugation: "さない",
      dictionaryForm: "す",
      type: 0,
      label: "plain, negative, nonpast",
    ),
    InflectionEntry(
      conjugation: "さなか",
      dictionaryForm: "す",
      type: 6,
      label: "plain, negative, past",
    ),
    InflectionEntry(
      conjugation: "します",
      dictionaryForm: "す",
      type: 1,
      label: "polite, non-past",
    ),
    InflectionEntry(
      conjugation: "しました",
      dictionaryForm: "す",
      type: 11,
      label: "polite, past",
    ),
    InflectionEntry(
      conjugation: "しまして",
      dictionaryForm: "す",
      type: 25,
      label: "polite, te-form",
    ),
    InflectionEntry(
      conjugation: "しませんでした",
      dictionaryForm: "す",
      type: 13,
      label: "polite, negative, past",
    ),
    InflectionEntry(
      conjugation: "しません",
      dictionaryForm: "す",
      type: 12,
      label: "polite, negative, non-past",
    ),
    InflectionEntry(
      conjugation: "しましょう",
      dictionaryForm: "す",
      type: 18,
      label: "polite, volitional",
    ),
    InflectionEntry(
      conjugation: "せば",
      dictionaryForm: "す",
      type: 2,
      label: "conditional",
    ),
    InflectionEntry(
      conjugation: "そう",
      dictionaryForm: "す",
      type: 3,
      label: "volitional",
    ),
    InflectionEntry(
      conjugation: "して",
      dictionaryForm: "す",
      type: 4,
      label: "te-form",
    ),
    InflectionEntry(
      conjugation: "した",
      dictionaryForm: "す",
      type: 5,
      label: "plain, past",
    ),
    InflectionEntry(
      conjugation: "され",
      dictionaryForm: "す",
      type: 7,
      label: "passive",
    ),
    InflectionEntry(
      conjugation: "させ",
      dictionaryForm: "す",
      type: 8,
      label: "causative",
    ),
    InflectionEntry(
      conjugation: "せ",
      dictionaryForm: "す",
      type: 9,
      label: "potential or imperative",
    ),

    // つ verb patterns
    InflectionEntry(
      conjugation: "たない",
      dictionaryForm: "つ",
      type: 0,
      label: "plain, negative, nonpast",
    ),
    InflectionEntry(
      conjugation: "たなか",
      dictionaryForm: "つ",
      type: 6,
      label: "plain, negative, past",
    ),
    InflectionEntry(
      conjugation: "ちます",
      dictionaryForm: "つ",
      type: 1,
      label: "polite, non-past",
    ),
    InflectionEntry(
      conjugation: "ちました",
      dictionaryForm: "つ",
      type: 11,
      label: "polite, past",
    ),
    InflectionEntry(
      conjugation: "ちまして",
      dictionaryForm: "つ",
      type: 25,
      label: "polite, te-form",
    ),
    InflectionEntry(
      conjugation: "ちませんでした",
      dictionaryForm: "つ",
      type: 13,
      label: "polite, negative, past",
    ),
    InflectionEntry(
      conjugation: "ちません",
      dictionaryForm: "つ",
      type: 12,
      label: "polite, negative, non-past",
    ),
    InflectionEntry(
      conjugation: "ちましょう",
      dictionaryForm: "つ",
      type: 18,
      label: "polite, volitional",
    ),
    InflectionEntry(
      conjugation: "てば",
      dictionaryForm: "つ",
      type: 2,
      label: "conditional",
    ),
    InflectionEntry(
      conjugation: "とう",
      dictionaryForm: "つ",
      type: 3,
      label: "volitional",
    ),
    InflectionEntry(
      conjugation: "って",
      dictionaryForm: "つ",
      type: 4,
      label: "te-form",
    ),
    InflectionEntry(
      conjugation: "った",
      dictionaryForm: "つ",
      type: 5,
      label: "plain, past",
    ),
    InflectionEntry(
      conjugation: "たれ",
      dictionaryForm: "つ",
      type: 7,
      label: "passive",
    ),
    InflectionEntry(
      conjugation: "たせ",
      dictionaryForm: "つ",
      type: 8,
      label: "causative",
    ),
    InflectionEntry(
      conjugation: "て",
      dictionaryForm: "つ",
      type: 9,
      label: "potential or imperative",
    ),

    // ぬ verb patterns
    InflectionEntry(
      conjugation: "なない",
      dictionaryForm: "ぬ",
      type: 0,
      label: "plain, negative, nonpast",
    ),
    InflectionEntry(
      conjugation: "ななか",
      dictionaryForm: "ぬ",
      type: 6,
      label: "plain, negative, past",
    ),
    InflectionEntry(
      conjugation: "にます",
      dictionaryForm: "ぬ",
      type: 1,
      label: "polite, non-past",
    ),
    InflectionEntry(
      conjugation: "にました",
      dictionaryForm: "ぬ",
      type: 11,
      label: "polite, past",
    ),
    InflectionEntry(
      conjugation: "にまして",
      dictionaryForm: "ぬ",
      type: 25,
      label: "polite, te-form",
    ),
    InflectionEntry(
      conjugation: "にませんでした",
      dictionaryForm: "ぬ",
      type: 13,
      label: "polite, negative, past",
    ),
    InflectionEntry(
      conjugation: "にません",
      dictionaryForm: "ぬ",
      type: 12,
      label: "polite, negative, non-past",
    ),
    InflectionEntry(
      conjugation: "にましょう",
      dictionaryForm: "に",
      type: 18,
      label: "polite, volitional",
    ),
    InflectionEntry(
      conjugation: "ねば",
      dictionaryForm: "ぬ",
      type: 2,
      label: "conditional",
    ),
    InflectionEntry(
      conjugation: "のう",
      dictionaryForm: "ぬ",
      type: 3,
      label: "volitional",
    ),
    InflectionEntry(
      conjugation: "んで",
      dictionaryForm: "ぬ",
      type: 4,
      label: "te-form",
    ),
    InflectionEntry(
      conjugation: "んだ",
      dictionaryForm: "ぬ",
      type: 5,
      label: "plain, past",
    ),
    InflectionEntry(
      conjugation: "なれ",
      dictionaryForm: "ぬ",
      type: 7,
      label: "passive",
    ),
    InflectionEntry(
      conjugation: "なせ",
      dictionaryForm: "ぬ",
      type: 8,
      label: "causative",
    ),
    InflectionEntry(
      conjugation: "ね",
      dictionaryForm: "ぬ",
      type: 9,
      label: "potential or imperative",
    ),

    // む verb patterns
    InflectionEntry(
      conjugation: "まない",
      dictionaryForm: "む",
      type: 0,
      label: "plain, negative, nonpast",
    ),
    InflectionEntry(
      conjugation: "まなか",
      dictionaryForm: "む",
      type: 6,
      label: "plain, negative, past",
    ),
    InflectionEntry(
      conjugation: "みます",
      dictionaryForm: "む",
      type: 1,
      label: "polite, non-past",
    ),
    InflectionEntry(
      conjugation: "みました",
      dictionaryForm: "む",
      type: 11,
      label: "polite, past",
    ),
    InflectionEntry(
      conjugation: "みまして",
      dictionaryForm: "む",
      type: 25,
      label: "polite, te-form",
    ),
    InflectionEntry(
      conjugation: "みませんでした",
      dictionaryForm: "む",
      type: 13,
      label: "polite, negative, past",
    ),
    InflectionEntry(
      conjugation: "みません",
      dictionaryForm: "む",
      type: 12,
      label: "polite, negative, non-past",
    ),
    InflectionEntry(
      conjugation: "みましょう",
      dictionaryForm: "む",
      type: 18,
      label: "polite, volitional",
    ),
    InflectionEntry(
      conjugation: "めば",
      dictionaryForm: "む",
      type: 2,
      label: "conditional",
    ),
    InflectionEntry(
      conjugation: "もう",
      dictionaryForm: "む",
      type: 3,
      label: "volitional",
    ),
    InflectionEntry(
      conjugation: "んで",
      dictionaryForm: "む",
      type: 4,
      label: "te-form",
    ),
    InflectionEntry(
      conjugation: "んだ",
      dictionaryForm: "む",
      type: 5,
      label: "plain, past",
    ),
    InflectionEntry(
      conjugation: "まれ",
      dictionaryForm: "む",
      type: 7,
      label: "passive",
    ),
    InflectionEntry(
      conjugation: "ませ",
      dictionaryForm: "む",
      type: 8,
      label: "causative",
    ),
    InflectionEntry(
      conjugation: "め",
      dictionaryForm: "む",
      type: 9,
      label: "potential or imperative",
    ),

    // う verb patterns
    InflectionEntry(
      conjugation: "わない",
      dictionaryForm: "う",
      type: 0,
      label: "plain, negative, nonpast",
    ),
    InflectionEntry(
      conjugation: "わなか",
      dictionaryForm: "う",
      type: 6,
      label: "plain, negative, past",
    ),
    InflectionEntry(
      conjugation: "います",
      dictionaryForm: "う",
      type: 1,
      label: "polite, non-past",
    ),
    InflectionEntry(
      conjugation: "いました",
      dictionaryForm: "う",
      type: 11,
      label: "polite, past",
    ),
    InflectionEntry(
      conjugation: "いまして",
      dictionaryForm: "う",
      type: 25,
      label: "polite, te-form",
    ),
    InflectionEntry(
      conjugation: "いませんでした",
      dictionaryForm: "う",
      type: 13,
      label: "polite, negative, past",
    ),
    InflectionEntry(
      conjugation: "いません",
      dictionaryForm: "う",
      type: 12,
      label: "polite, negative, non-past",
    ),
    InflectionEntry(
      conjugation: "いましょう",
      dictionaryForm: "う",
      type: 18,
      label: "polite, volitional",
    ),
    InflectionEntry(
      conjugation: "えば",
      dictionaryForm: "う",
      type: 2,
      label: "conditional",
    ),
    InflectionEntry(
      conjugation: "おう",
      dictionaryForm: "う",
      type: 3,
      label: "volitional",
    ),
    InflectionEntry(
      conjugation: "って",
      dictionaryForm: "う",
      type: 4,
      label: "te-form",
    ),
    InflectionEntry(
      conjugation: "った",
      dictionaryForm: "う",
      type: 5,
      label: "plain, past",
    ),
    InflectionEntry(
      conjugation: "われ",
      dictionaryForm: "う",
      type: 7,
      label: "passive",
    ),
    InflectionEntry(
      conjugation: "わせ",
      dictionaryForm: "う",
      type: 8,
      label: "causative",
    ),
    InflectionEntry(
      conjugation: "え",
      dictionaryForm: "う",
      type: 9,
      label: "potential or imperative",
    ),

    // ぐ verb patterns
    InflectionEntry(
      conjugation: "がない",
      dictionaryForm: "ぐ",
      type: 0,
      label: "plain, negative, nonpast",
    ),
    InflectionEntry(
      conjugation: "がなか",
      dictionaryForm: "ぐ",
      type: 6,
      label: "plain, negative, past",
    ),
    InflectionEntry(
      conjugation: "ぎます",
      dictionaryForm: "ぐ",
      type: 1,
      label: "polite, non-past",
    ),
    InflectionEntry(
      conjugation: "ぎました",
      dictionaryForm: "ぐ",
      type: 11,
      label: "polite, past",
    ),
    InflectionEntry(
      conjugation: "ぎまして",
      dictionaryForm: "ぐ",
      type: 25,
      label: "polite, te-form",
    ),
    InflectionEntry(
      conjugation: "ぎませんでした",
      dictionaryForm: "ぐ",
      type: 13,
      label: "polite, negative, past",
    ),
    InflectionEntry(
      conjugation: "ぎません",
      dictionaryForm: "ぐ",
      type: 12,
      label: "polite, negative, non-past",
    ),
    InflectionEntry(
      conjugation: "ぎましょう",
      dictionaryForm: "ぐ",
      type: 18,
      label: "polite, volitional",
    ),
    InflectionEntry(
      conjugation: "げば",
      dictionaryForm: "ぐ",
      type: 2,
      label: "conditional",
    ),
    InflectionEntry(
      conjugation: "ごう",
      dictionaryForm: "ぐ",
      type: 3,
      label: "volitional",
    ),
    InflectionEntry(
      conjugation: "いで",
      dictionaryForm: "ぐ",
      type: 4,
      label: "te-form",
    ),
    InflectionEntry(
      conjugation: "いだ",
      dictionaryForm: "ぐ",
      type: 5,
      label: "plain, past",
    ),
    InflectionEntry(
      conjugation: "がれ",
      dictionaryForm: "ぐ",
      type: 7,
      label: "passive",
    ),
    InflectionEntry(
      conjugation: "がせ",
      dictionaryForm: "ぐ",
      type: 8,
      label: "causative",
    ),
    InflectionEntry(
      conjugation: "げ",
      dictionaryForm: "ぐ",
      type: 9,
      label: "potential or imperative",
    ),

    // ぶ verb patterns
    InflectionEntry(
      conjugation: "ばない",
      dictionaryForm: "ぶ",
      type: 0,
      label: "plain, negative, nonpast",
    ),
    InflectionEntry(
      conjugation: "ばなか",
      dictionaryForm: "ぶ",
      type: 6,
      label: "plain, negative, past",
    ),
    InflectionEntry(
      conjugation: "びます",
      dictionaryForm: "ぶ",
      type: 1,
      label: "polite, non-past",
    ),
    InflectionEntry(
      conjugation: "びました",
      dictionaryForm: "ぶ",
      type: 11,
      label: "polite, past",
    ),
    InflectionEntry(
      conjugation: "びまして",
      dictionaryForm: "ぶ",
      type: 25,
      label: "polite, te-form",
    ),
    InflectionEntry(
      conjugation: "びませんでした",
      dictionaryForm: "ぶ",
      type: 13,
      label: "polite, negative, past",
    ),
    InflectionEntry(
      conjugation: "びません",
      dictionaryForm: "ぶ",
      type: 12,
      label: "polite, negative, non-past",
    ),
    InflectionEntry(
      conjugation: "びましょう",
      dictionaryForm: "ぶ",
      type: 18,
      label: "polite, volitional",
    ),
    InflectionEntry(
      conjugation: "べば",
      dictionaryForm: "ぶ",
      type: 2,
      label: "conditional",
    ),
    InflectionEntry(
      conjugation: "ぼう",
      dictionaryForm: "ぶ",
      type: 3,
      label: "volitional",
    ),
    InflectionEntry(
      conjugation: "んで",
      dictionaryForm: "ぶ",
      type: 4,
      label: "te-form",
    ),
    InflectionEntry(
      conjugation: "んだ",
      dictionaryForm: "ぶ",
      type: 5,
      label: "plain, past",
    ),
    InflectionEntry(
      conjugation: "ばれ",
      dictionaryForm: "ぶ",
      type: 7,
      label: "passive",
    ),
    InflectionEntry(
      conjugation: "ばせ",
      dictionaryForm: "ぶ",
      type: 8,
      label: "causative",
    ),
    InflectionEntry(
      conjugation: "べ",
      dictionaryForm: "ぶ",
      type: 9,
      label: "potential or imperative",
    ),

    // Adjective patterns
    InflectionEntry(
      conjugation: "くなか",
      dictionaryForm: "い",
      type: 22,
      label: "adj., negative, past",
    ),
    InflectionEntry(
      conjugation: "くな",
      dictionaryForm: "い",
      type: 21,
      label: "adj., negative",
    ),
    InflectionEntry(
      conjugation: "かった",
      dictionaryForm: "い",
      type: 23,
      label: "adj., past",
    ),
    InflectionEntry(
      conjugation: "く",
      dictionaryForm: "い",
      type: 15,
      label: "adj. -> adverb",
    ),

    // Ichidan verb patterns (eru/iru ending verbs)
    InflectionEntry(
      conjugation: "ける",
      dictionaryForm: "ける",
      type: 1,
      label: "polite, non-past",
    ),
    InflectionEntry(
      conjugation: "けます",
      dictionaryForm: "ける",
      type: 1,
      label: "polite, non-past",
    ),
    InflectionEntry(
      conjugation: "けました",
      dictionaryForm: "ける",
      type: 11,
      label: "polite, past",
    ),
    InflectionEntry(
      conjugation: "けませんでした",
      dictionaryForm: "ける",
      type: 13,
      label: "polite, negative, past",
    ),
    InflectionEntry(
      conjugation: "けません",
      dictionaryForm: "ける",
      type: 12,
      label: "polite, negative, non-past",
    ),
    InflectionEntry(
      conjugation: "けましょう",
      dictionaryForm: "ける",
      type: 18,
      label: "polite, volitional",
    ),
    InflectionEntry(
      conjugation: "けない",
      dictionaryForm: "ける",
      type: 0,
      label: "plain, negative, nonpast",
    ),
    InflectionEntry(
      conjugation: "けなか",
      dictionaryForm: "ける",
      type: 6,
      label: "plain, negative, past",
    ),
    InflectionEntry(
      conjugation: "けれ",
      dictionaryForm: "ける",
      type: 2,
      label: "conditional",
    ),
    InflectionEntry(
      conjugation: "けよ",
      dictionaryForm: "ける",
      type: 3,
      label: "volitional",
    ),
    InflectionEntry(
      conjugation: "けて",
      dictionaryForm: "ける",
      type: 4,
      label: "te-form",
    ),
    InflectionEntry(
      conjugation: "けた",
      dictionaryForm: "ける",
      type: 5,
      label: "plain, past",
    ),
    InflectionEntry(
      conjugation: "けら",
      dictionaryForm: "ける",
      type: 19,
      label: "passive or potential",
    ),
    InflectionEntry(
      conjugation: "けさ",
      dictionaryForm: "ける",
      type: 8,
      label: "causative",
    ),
    InflectionEntry(
      conjugation: "けろ",
      dictionaryForm: "ける",
      type: 10,
      label: "imperative",
    ),
  ];

  /// Inflect a Japanese verb stem to a specific form
  ///
  /// [verbStem] - the verb stem (without the final character)
  /// [verbEnding] - the final character of the verb (る, く, す, etc.)
  /// [inflectionType] - the desired inflection type (0-25)
  ///
  /// Returns the inflected form or null if no matching rule found
  static String? inflect(
    String verbStem,
    String verbEnding,
    int inflectionType,
  ) {
    for (final rule in inflectionRules) {
      if (rule.dictionaryForm == verbEnding && rule.type == inflectionType) {
        return verbStem + rule.conjugation;
      }
    }
    return null;
  }

  /// Get all possible inflections for a verb
  ///
  /// [verbStem] - the verb stem (without the final character)
  /// [verbEnding] - the final character of the verb
  ///
  /// Returns a map of inflection type to inflected form
  static Map<int, String> getAllInflections(
    String verbStem,
    String verbEnding,
  ) {
    final inflections = <int, String>{};

    for (final rule in inflectionRules) {
      if (rule.dictionaryForm == verbEnding) {
        inflections[rule.type] = verbStem + rule.conjugation;
      }
    }

    return inflections;
  }

  /// Get the label for an inflection type
  static String? getInflectionLabel(int type) {
    return inflectionLabels[type];
  }

  /// Deinflect a conjugated verb form back to its dictionary form
  ///
  /// [conjugatedForm] - the conjugated verb
  ///
  /// Returns a list of possible dictionary forms with their inflection info
  static List<DeinflectionResult> deinflect(String conjugatedForm) {
    final results = <DeinflectionResult>[];

    for (final rule in inflectionRules) {
      if (conjugatedForm.endsWith(rule.conjugation)) {
        final stem = conjugatedForm.substring(
          0,
          conjugatedForm.length - rule.conjugation.length,
        );
        final dictionaryForm = stem + rule.dictionaryForm;

        results.add(
          DeinflectionResult(
            dictionaryForm: dictionaryForm,
            originalForm: conjugatedForm,
            inflectionType: rule.type,
            inflectionLabel: rule.label,
            verbStem: stem,
            verbEnding: rule.dictionaryForm,
          ),
        );
      }
    }

    return results;
  }
}

/// Result of deinflection operation
class DeinflectionResult {
  final String dictionaryForm;
  final String originalForm;
  final int inflectionType;
  final String inflectionLabel;
  final String verbStem;
  final String verbEnding;

  const DeinflectionResult({
    required this.dictionaryForm,
    required this.originalForm,
    required this.inflectionType,
    required this.inflectionLabel,
    required this.verbStem,
    required this.verbEnding,
  });

  @override
  String toString() {
    return 'DeinflectionResult(dictionaryForm: $dictionaryForm, inflectionType: $inflectionType, label: $inflectionLabel)';
  }
}
