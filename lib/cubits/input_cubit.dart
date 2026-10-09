import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/input.dart';

class InputCubit extends Cubit<Input> {
  InputCubit() : super(Input(sessions: [SearchSession()]));

  void setInput(String input) {
    final sessions = [...state.sessions];
    sessions[state.searchIndex] = sessions[state.searchIndex].copyWith(
      currentInput: input,
    );
    emit(state.copyWith(sessions: sessions));
  }

  void setFormattedInput(String input) {
    emit(state.copyWith(formattedInput: input));
  }

  void addSession() {
    final sessions = [...state.sessions, SearchSession()];
    emit(state.copyWith(sessions: sessions, searchIndex: sessions.length - 1));
  }

  void removeSession([int? at]) {
    if (state.sessions.length <= 1) return;
    final index = at ?? state.searchIndex;
    final sessions = [...state.sessions]..removeAt(index);
    final newIndex = index > 0 ? index - 1 : 0;
    emit(state.copyWith(sessions: sessions, searchIndex: newIndex));
  }

  void setSearchIndex(int searchIndex) {
    emit(state.copyWith(searchIndex: searchIndex));
  }

  void renameSession(int index, String name) {
    final sessions = [...state.sessions];
    sessions[index] = sessions[index].copyWith(name: name);
    emit(state.copyWith(sessions: sessions));
  }

  void recordSearch(String term) {
    final sessions = [...state.sessions];
    final session = sessions[state.searchIndex];
    final history = [...session.history];
    if (history.isEmpty || history.last != term) {
      history.add(term);
    }
    sessions[state.searchIndex] = session.copyWith(
      currentInput: term,
      history: history,
    );
    emit(state.copyWith(sessions: sessions));
  }

  void clearSessionHistory([int? at]) {
    final index = at ?? state.searchIndex;
    final sessions = [...state.sessions];
    sessions[index] = sessions[index].copyWith(history: []);
    emit(state.copyWith(sessions: sessions));
  }

  void loadSessions(List<SearchSession> sessions, int searchIndex) {
    emit(state.copyWith(sessions: sessions, searchIndex: searchIndex));
  }
}
