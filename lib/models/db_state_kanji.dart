import 'package:equatable/equatable.dart';

import '../models/entry.dart';
import '../models/kanji.dart';
import '../services/database_interface.dart';

// States
abstract class KanjiState extends Equatable {
  const KanjiState();

  @override
  List<Object?> get props => [];
}

class KanjiInitial extends KanjiState {}

class KanjiLoading extends KanjiState {}

class KanjiLoaded extends KanjiState {
  final List<KanjiEntry> entries;
  final int totalCount;
  final String query;
  final int currentPage;
  final int? resultsPerPage;

  const KanjiLoaded({
    required this.entries,
    required this.totalCount,
    required this.query,
    required this.currentPage,
    this.resultsPerPage,
  });

  @override
  List<Object?> get props => [entries, totalCount, query, currentPage, resultsPerPage];
}

class KanjiRadicalSearchLoaded extends KanjiState {
  final List<String> characters;
  final List<String> selectedRadicals;

  const KanjiRadicalSearchLoaded({
    required this.characters,
    required this.selectedRadicals,
  });

  @override
  List<Object?> get props => [characters, selectedRadicals];
}

class KanjiRadicalsLoaded extends KanjiState {
  final List<Kanji> radicals;
  final List<String> availableRadicals;
  final List<String> selectedRadicals;

  const KanjiRadicalsLoaded({
    required this.radicals,
    required this.availableRadicals,
    required this.selectedRadicals,
  });

  @override
  List<Object?> get props => [radicals, availableRadicals, selectedRadicals];
}

class KanjiCharactersLoaded extends KanjiState {
  final List<Kanji> characters;

  const KanjiCharactersLoaded({required this.characters});

  @override
  List<Object?> get props => [characters];
}

class KanjiError extends KanjiState {
  final String message;
  final DatabaseStatus? status;

  const KanjiError({
    required this.message,
    this.status,
  });

  @override
  List<Object?> get props => [message, status];
}

class KanjiDatabaseNotReady extends KanjiState {
  final DatabaseStatus status;
  final String? log;

  const KanjiDatabaseNotReady({
    required this.status,
    this.log,
  });

  @override
  List<Object?> get props => [status, log];
}
