import 'package:flutter/material.dart';
import 'package:fujiten/services/database_interface_expression.dart';

import '../services/database_interface.dart';
import '../services/database_interface_kanji.dart';

class DatabaseStatusDisplay extends StatelessWidget {
  final DatabaseInterfaceKanji databaseInterfaceKanji;
  final DatabaseInterfaceExpression databaseInterfaceExpression;

  const DatabaseStatusDisplay({
    required this.databaseInterfaceExpression,
    required this.databaseInterfaceKanji,
    super.key,
  });

  String _getDatabaseStatusMessage(DatabaseStatus? status) {
    switch (status) {
      case null:
      case DatabaseStatus.pathNotSet:
        return "No database configured";
      case DatabaseStatus.ok:
        return "Ready";
      case DatabaseStatus.noResults:
        return "Invalid database (no entries found)";
      default:
        return "Unknown status: $status";
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

  Widget _buildDatabaseStatusItem({
    required BuildContext context,
    required String title,
    required DatabaseStatus? status,
    required String kanjiChar,
  }) {
    final statusColor = _getStatusColor(context, status);
    final statusIcon = _getStatusIcon(status);
    final statusMessage = _getDatabaseStatusMessage(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status == DatabaseStatus.ok
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
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
          const SizedBox(width: 12),
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
                    Icon(
                      statusIcon,
                      size: 16,
                      color: statusColor,
                    ),
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
        ],
      ),
    );
  }

  Widget _buildOverallStatus(BuildContext context) {
    final bool allOk = databaseInterfaceKanji.status == DatabaseStatus.ok &&
        databaseInterfaceExpression.status == DatabaseStatus.ok;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allOk
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            allOk ? Icons.check_circle : Icons.warning,
            color: allOk
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            allOk
                ? 'All databases ready'
                : 'Database configuration required',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: allOk
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.storage,
                  size: 28
                ),
                const SizedBox(width: 12),
                Text(
                  'Database Status',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Kanji Database Status
            _buildDatabaseStatusItem(
              context: context,
              title: 'Kanji Database',
              status: databaseInterfaceKanji.status,
              kanjiChar: '漢',
            ),

            const SizedBox(height: 12),

            // Expression Database Status
            _buildDatabaseStatusItem(
              context: context,
              title: 'Expression Database',
              status: databaseInterfaceExpression.status,
              kanjiChar: '言',
            ),

            const SizedBox(height: 20),

            // Overall Status
            _buildOverallStatus(context),

            // Help text for incomplete setup
            if (databaseInterfaceKanji.status != DatabaseStatus.ok ||
                databaseInterfaceExpression.status != DatabaseStatus.ok) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Configure databases in the settings menu to continue',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}