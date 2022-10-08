import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/input.dart';

class InputCubit extends Cubit<Input> {
  InputCubit() : super(Input());

  void setInput(String input) {
    var inputs = [...state.inputs];
    inputs[state.searchIndex] = input;
    emit(state.copyWith(inputs: inputs));
  }

  void setFormattedInput(String input) {
    emit(state.copyWith(formattedInput: input));
  }

  void addInput() => emit(state.copyWith(inputs: [...state.inputs, '']));

  void removeInput([int? at]) =>
      emit(state.copyWith(inputs: [...state.inputs]..removeAt(at ?? state.searchIndex)));

  void setSearchIndex(int searchIndex) => emit(state.copyWith(searchIndex: searchIndex));
}
