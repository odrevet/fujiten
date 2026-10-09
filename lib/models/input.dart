class SearchSession {
  String name;
  String currentInput;
  List<String> history;

  SearchSession({
    this.name = '',
    this.currentInput = '',
    this.history = const [],
  });

  SearchSession copyWith({
    String? name,
    String? currentInput,
    List<String>? history,
  }) {
    return SearchSession(
      name: name ?? this.name,
      currentInput: currentInput ?? this.currentInput,
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'currentInput': currentInput,
    'history': history,
  };

  factory SearchSession.fromJson(Map<String, dynamic> json) => SearchSession(
    name: json['name'] as String? ?? '',
    currentInput: json['currentInput'] as String? ?? '',
    history: (json['history'] as List?)?.cast<String>() ?? [],
  );
}

class Input {
  int searchIndex;
  List<SearchSession> sessions;
  String formattedInput;

  Input({
    this.searchIndex = 0,
    this.sessions = const [],
    this.formattedInput = "",
  });

  Input copyWith({
    int? searchIndex,
    List<SearchSession>? sessions,
    String? formattedInput,
  }) {
    return Input(
      searchIndex: searchIndex ?? this.searchIndex,
      sessions: sessions ?? this.sessions,
      formattedInput: formattedInput ?? this.formattedInput,
    );
  }
}
