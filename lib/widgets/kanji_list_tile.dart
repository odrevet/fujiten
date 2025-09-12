import 'package:flutter/material.dart';

import '../models/kanji.dart';
import 'kanji_widget.dart';

class KanjiListTile extends StatelessWidget {
  final Kanji kanji;
  final VoidCallback? onTap;
  final VoidCallback? onTapLeading;
  final bool selected;

  const KanjiListTile({
    required this.kanji,
    this.onTap,
    this.onTapLeading,
    this.selected = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: selected
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : Colors.transparent,
        border: selected
            ? Border.all(color: colorScheme.primary, width: 2.0)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kanji character
                _buildKanjiCharacter(context),
                const SizedBox(width: 16.0),

                // Kanji details
                Expanded(
                  child: _buildKanjiDetails(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKanjiCharacter(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Center(
        child: KanjiCharacterWidget(
          kanji: kanji,
          onTap: onTapLeading,
          style: TextStyle(
            fontSize: 32.0,
            fontWeight: FontWeight.bold,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildKanjiDetails(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stroke count and radicals row
        Row(
          children: [
            _buildInfoChip(
              context,
              _getStrokeText(),
              Icons.edit,
              theme.colorScheme.secondary,
            ),
            const SizedBox(width: 8.0),
            if (_getRadicals().isNotEmpty)
              _buildInfoChip(
                context,
                _getRadicals(),
                Icons.category,
                theme.colorScheme.tertiary,
              ),
          ],
        ),
        const SizedBox(height: 12.0),

        // Readings section
        if (_getOnReading().isNotEmpty || _getKunReading().isNotEmpty)
          _buildReadingsSection(context),

        const SizedBox(height: 8.0),

        // Meanings section
        if (_getMeaning().isNotEmpty)
          _buildMeaningSection(context),
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: color),
          const SizedBox(width: 4.0),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_getOnReading().isNotEmpty)
          _buildReadingRow(
            context,
            'On',
            _getOnReading(),
            theme.colorScheme.primary,
          ),
        if (_getOnReading().isNotEmpty && _getKunReading().isNotEmpty)
          const SizedBox(height: 4.0),
        if (_getKunReading().isNotEmpty)
          _buildReadingRow(
            context,
            'Kun',
            _getKunReading(),
            theme.colorScheme.secondary,
          ),
      ],
    );
  }

  Widget _buildReadingRow(BuildContext context, String label, String reading, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 35,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            reading,
            style: TextStyle(
              fontSize: 13.0,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeaningSection(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.translate,
          size: 16.0,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: SelectableText(
            _getMeaning(),
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods for data formatting
  String _getStrokeText() {
    final count = kanji.strokeCount;
    return '$count stroke${count > 1 ? 's' : ''}';
  }

  String _getOnReading() {
    return kanji.on?.join('・') ?? '';
  }

  String _getKunReading() {
    return kanji.kun?.join('・') ?? '';
  }

  String _getRadicals() {
    return kanji.radicals?.join('') ?? '';
  }

  String _getMeaning() {
    return kanji.meanings?.join(', ') ?? '';
  }
}