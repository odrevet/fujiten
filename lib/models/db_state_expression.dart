import 'package:equatable/equatable.dart';

import '../models/entry.dart';
import '../services/database_interface.dart';

// States
abstract class ExpressionState extends Equatable {
  const ExpressionState();

  @override
  List<Object?> get props => [];
}

class ExpressionInitial extends ExpressionState {}

class ExpressionLoading extends ExpressionState {}

class ExpressionLoaded extends ExpressionState {
  final List<ExpressionEntry> entries;
  final int totalCount;
  final String query;
  final int currentPage;
  final int? resultsPerPage;

  const ExpressionLoaded({
    required this.entries,
    required this.totalCount,
    required this.query,
    required this.currentPage,
    this.resultsPerPage,
  });

  @override
  List<Object?> get props => [
    entries,
    totalCount,
    query,
    currentPage,
    resultsPerPage,
  ];
}

class ExpressionError extends ExpressionState {
  final String message;
  final DatabaseStatus? status;

  const ExpressionError({required this.message, this.status});

  @override
  List<Object?> get props => [message, status];
}

class ExpressionDatabaseNotReady extends ExpressionState {
  final DatabaseStatus status;
  final String? log;

  const ExpressionDatabaseNotReady({required this.status, this.log});

  @override
  List<Object?> get props => [status, log];
}
