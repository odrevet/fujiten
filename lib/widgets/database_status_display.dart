import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/expression_cubit.dart';
import '../cubits/kanji_cubit.dart';
import '../models/db_state_expression.dart';
import '../models/db_state_kanji.dart';
import '../services/database_interface.dart';

class DatabaseStatusItem extends StatelessWidget {
  final String title;
  final DatabaseStatus? status;
  final String kanjiChar;

  const DatabaseStatusItem({
    required this.title,
    required this.status,
    required this.kanjiChar,
    super.key,
  });

  String _getDatabaseStatusMessage(DatabaseStatus? status) {
    switch (status) {
      case DatabaseStatus.ok:
        return "Ready";
      case DatabaseStatus.noResults:
        return "Invalid database (no entries found)";
      case DatabaseStatus.pathNotSet:
        return "No database selected";
      default:
        return "No database configured";
    }
  }

  Color _getStatusColor(BuildContext context, DatabaseStatus? status) {
    return status == DatabaseStatus.ok
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
  }

  IconData _getStatusIcon(DatabaseStatus? status) {
    return status == DatabaseStatus.ok ? Icons.check_circle : Icons.error;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context, status);
    final statusIcon = _getStatusIcon(status);
    final statusMessage = _getDatabaseStatusMessage(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status == DatabaseStatus.ok
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Theme.of(
                context,
              ).colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        statusMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                kanjiChar,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DatabaseStatusDisplay extends StatelessWidget {
  const DatabaseStatusDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Expression Database Status
            BlocBuilder<ExpressionCubit, ExpressionState>(
              builder: (context, state) {
                DatabaseStatus status;
                if (state is ExpressionLoaded || state is ExpressionReady) {
                  status = DatabaseStatus.ok;
                } else {
                  status = DatabaseStatus.pathNotSet;
                }

                return DatabaseStatusItem(
                  title: 'Expression Database',
                  status: status,
                  kanjiChar: '言',
                );
              },
            ),

            const SizedBox(height: 16),

            // Kanji Database Status
            BlocBuilder<KanjiCubit, KanjiState>(
              builder: (context, state) {
                print("-------------");
                print(state.runtimeType);
                DatabaseStatus status;
                if (state is KanjiLoaded || state is KanjiReady) {
                  status = DatabaseStatus.ok;
                } else {
                  status = DatabaseStatus.pathNotSet;
                }
                return DatabaseStatusItem(
                  title: 'Kanji Database',
                  status: status,
                  kanjiChar: '漢',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
