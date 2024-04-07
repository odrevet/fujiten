class Input {
  int searchIndex;
  List<String> inputs;
  String formattedInput;

  Input(
      {this.searchIndex = 0, this.inputs = const [], this.formattedInput = ""});

  Input copyWith({
    int? searchIndex,
    List<String>? inputs,
    String? formattedInput,
  }) {
    return Input(
      searchIndex: searchIndex ?? this.searchIndex,
      inputs: inputs ?? this.inputs,
      formattedInput: formattedInput ?? this.formattedInput,
    );
  }
}
