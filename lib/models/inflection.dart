class ConjugationRule {
  final String suffix;
  final String replacement;
  final int typeId;
  final String description;

  ConjugationRule({
    required this.suffix,
    required this.replacement,
    required this.typeId,
    required this.description,
  });
}

class DeinflectionResult {
  final String dictionaryForm;
  final List<int> conjugationPath;
  final List<String> descriptions;

  DeinflectionResult({
    required this.dictionaryForm,
    required this.conjugationPath,
    required this.descriptions,
  });

  @override
  String toString() {
    return 'Dictionary Form: $dictionaryForm\n'
        'Path: ${conjugationPath.join(' -> ')}\n'
        'Steps: ${descriptions.join(' -> ')}';
  }
}

enum WordType { verb, adjective }

class JapaneseDeinflector {
  static Map<int, String>? _typeDescriptions;
  static List<ConjugationRule>? _rules;
  static bool _isInitialized = false;

  // Private constructor to prevent direct instantiation
  JapaneseDeinflector._();

  static void initialize(String configData) {
    if (_isInitialized) return; // Already initialized

    _typeDescriptions = {};
    _rules = [];
    _parseConfig(configData);
    _isInitialized = true;
  }

  static void _parseConfig(String configData) {
    final lines = configData.split('\n');
    bool inRulesSection = false;

    for (final line in lines) {
      final trimmed = line.trim();

      // Skip comments and empty lines
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      // Check for rules section start
      if (trimmed == r'$') {
        inRulesSection = true;
        continue;
      }

      if (!inRulesSection) {
        // Parse type descriptions (number + description)
        final match = RegExp(r'^(\d+)\s+(.+)$').firstMatch(trimmed);
        if (match != null) {
          final id = int.parse(match.group(1)!);
          final description = match.group(2)!;
          _typeDescriptions![id] = description;
        }
      } else {
        // Parse conjugation rules (suffix + replacement + type_id)
        final parts = trimmed.split('\t');
        if (parts.length >= 3) {
          final suffix = parts[0];
          final replacement = parts[1];
          final typeId = int.parse(parts[2]);
          final description = _typeDescriptions![typeId] ?? 'Unknown';

          _rules!.add(ConjugationRule(
            suffix: suffix,
            replacement: replacement,
            typeId: typeId,
            description: description,
          ));
        }
      }
    }
  }

  static DeinflectionResult? deinflect(String word, WordType wordType) {
    if (!_isInitialized) {
      throw StateError('JapaneseDeinflector must be initialized first with initialize()');
    }
    String currentWord = word;
    final List<int> conjugationPath = [];
    final List<String> descriptions = [];
    final int maxPasses = 10; // Prevent infinite loops

    for (int pass = 0; pass < maxPasses; pass++) {
      final result = _findLongestMatch(currentWord, wordType);

      if (result == null) {
        // No more matches found, we're done
        break;
      }

      currentWord = result.transformedWord;
      conjugationPath.add(result.rule.typeId);
      descriptions.add(result.rule.description);
    }

    if (conjugationPath.isEmpty) {
      // No transformations applied, word is already in dictionary form
      return DeinflectionResult(
        dictionaryForm: word,
        conjugationPath: [],
        descriptions: ['Already in dictionary form'],
      );
    }

    return DeinflectionResult(
      dictionaryForm: currentWord,
      conjugationPath: conjugationPath,
      descriptions: descriptions,
    );
  }

  static _MatchResult? _findLongestMatch(String word, WordType wordType) {
    ConjugationRule? bestRule;
    String? transformedWord;

    // Sort rules by suffix length (longest first) for proper matching
    final sortedRules = List<ConjugationRule>.from(_rules!);
    sortedRules.sort((a, b) => b.suffix.length.compareTo(a.suffix.length));

    for (final rule in sortedRules) {
      if (_isRuleApplicable(rule, wordType) && word.endsWith(rule.suffix)) {
        // Found a match - apply the transformation
        final baseWord = word.substring(0, word.length - rule.suffix.length);
        transformedWord = baseWord + rule.replacement;
        bestRule = rule;
        break; // Take the first (longest) match
      }
    }

    if (bestRule != null && transformedWord != null) {
      return _MatchResult(
        rule: bestRule,
        transformedWord: transformedWord,
      );
    }

    return null;
  }

  static bool _isRuleApplicable(ConjugationRule rule, WordType wordType) {
    // Determine if a rule applies to the given word type
    // This is a simplified heuristic - you might want to refine this
    // based on the specific type IDs in your configuration

    switch (wordType) {
      case WordType.adjective:
      // Adjective rules typically have type IDs 15-23
        return rule.typeId >= 15 && rule.typeId <= 24;
      case WordType.verb:
      // Verb rules typically have type IDs 0-14, 19-20, 24-25
        return (rule.typeId >= 0 && rule.typeId <= 14) ||
            (rule.typeId >= 19 && rule.typeId <= 20) ||
            rule.typeId == 24 || rule.typeId == 25;
    }
  }

  // Helper method to get all possible deinflections (for ambiguous cases)
  static List<DeinflectionResult> getAllPossibleDeinflections(String word) {
    final results = <DeinflectionResult>[];

    // Try as verb
    final verbResult = deinflect(word, WordType.verb);
    if (verbResult != null) {
      results.add(verbResult);
    }

    // Try as adjective
    final adjResult = deinflect(word, WordType.adjective);
    if (adjResult != null) {
      results.add(adjResult);
    }

    return results;
  }

  static void printRules() {
    if (!_isInitialized) {
      print('JapaneseDeinflector not initialized');
      return;
    }

    print('Type Descriptions:');
    _typeDescriptions!.forEach((id, desc) {
      print('  $id: $desc');
    });

    print('\nConjugation Rules (first 10):');
    for (int i = 0; i < _rules!.length && i < 10; i++) {
      final rule = _rules![i];
      print('  "${rule.suffix}" -> "${rule.replacement}" (${rule.typeId}: ${rule.description})');
    }
    print('... and ${_rules!.length - 10} more rules');
  }
}

class _MatchResult {
  final ConjugationRule rule;
  final String transformedWord;

  _MatchResult({
    required this.rule,
    required this.transformedWord,
  });
}