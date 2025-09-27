import 'dart:convert';

class ConjugationRule {
  final String kanaIn;
  final String kanaOut;
  final List<String> rulesIn;
  final List<String> rulesOut;

  ConjugationRule({
    required this.kanaIn,
    required this.kanaOut,
    required this.rulesIn,
    required this.rulesOut,
  });

  factory ConjugationRule.fromJson(Map<String, dynamic> json) {
    return ConjugationRule(
      kanaIn: json['kanaIn'] as String,
      kanaOut: json['kanaOut'] as String,
      rulesIn: List<String>.from(json['rulesIn'] as List),
      rulesOut: List<String>.from(json['rulesOut'] as List),
    );
  }
}

class DeinflectionResult {
  final String word;
  final int originalLength;
  final int numConjugations;

  DeinflectionResult(this.word, this.originalLength, this.numConjugations);

  @override
  String toString() => 'DeinflectionResult(word: $word, originalLength: $originalLength, numConjugations: $numConjugations)';
}

class JapaneseDeconjugator {
  final Map<String, List<ConjugationRule>> conjugationRules = {};

  JapaneseDeconjugator(String conjugationJson) {
    _loadConjugations(conjugationJson);
  }

  void _loadConjugations(String jsonString) {
    final Map<String, dynamic> data = jsonDecode(jsonString);

    data.forEach((key, value) {
      final List<dynamic> rules = value as List<dynamic>;
      conjugationRules[key] = rules
          .map((rule) => ConjugationRule.fromJson(rule as Map<String, dynamic>))
          .toList();
    });
  }

  /// Main deconjugation function - returns all possible deinflected forms
  static List<DeinflectionResult> deinflect(
      String word,
      Map<String, List<ConjugationRule>> conjugationRules,
      ) {
    final Set<String> seen = {word};
    final List<String> possibilities = [word];
    final List<DeinflectionResult> results = [];
    int numConjugations = 0;

    // Add the original word
    results.add(DeinflectionResult(word, word.length, 0));

    while (possibilities.isNotEmpty) {
      final String currentWord = possibilities.removeLast();

      // Try all conjugation rules
      for (final entry in conjugationRules.entries) {
        for (final rule in entry.value) {
          if (currentWord.endsWith(rule.kanaIn)) {
            // Create new word by replacing the ending
            final String newWord = currentWord.substring(
              0,
              currentWord.length - rule.kanaIn.length,
            ) + rule.kanaOut;

            numConjugations++;

            // Skip if we've seen this word before or if it's empty
            if (seen.contains(newWord) || newWord.isEmpty) {
              continue;
            }

            possibilities.add(newWord);
            seen.add(newWord);

            // Add all possible deinflections
            results.add(DeinflectionResult(newWord, word.length, numConjugations));
          }
        }
      }
    }

    // Sort results: longer original text first, then fewer conjugations
    results.sort((a, b) {
      final lengthComparison = b.originalLength.compareTo(a.originalLength);
      if (lengthComparison != 0) return lengthComparison;
      return a.numConjugations.compareTo(b.numConjugations);
    });

    return results;
  }

  /// Convenience method that uses the instance's conjugation rules
  List<DeinflectionResult> deconjugateWord(String word) {
    return deinflect(word, conjugationRules);
  }
}