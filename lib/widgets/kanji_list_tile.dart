import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kanji_drawing_animation/kanji_drawing_animation.dart';

import '../models/kanji.dart';
import '../cubits/expression_cubit.dart';
import '../cubits/search_options_cubit.dart';
import '../models/entry.dart'; // Add your entry model import
import 'kanji_widget.dart';

class KanjiListTile extends StatefulWidget {
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
  State<KanjiListTile> createState() => _KanjiListTileState();
}

class _KanjiListTileState extends State<KanjiListTile> {
  bool _showAnimation = false;
  List<ExpressionEntry>? _expressions; // Store the fetched expressions
  bool _loadingExpressions = false;
  bool _expressionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadExpressions();
  }

  Future<void> _loadExpressions() async {
    if (_expressionsLoaded) return;

    setState(() {
      _loadingExpressions = true;
    });

    try {
      final expressionCubit = context.read<ExpressionCubit>();
      var wildcard = context.read<SearchOptionsCubit>().state.useRegexp ? '.*' : '*';
      final entries = await expressionCubit.databaseInterface.search(
        '$wildcard${widget.kanji.literal}$wildcard',
        5,
        0,
        context.read<SearchOptionsCubit>().state.useRegexp,
      );

      if (mounted) {
        setState(() {
          _expressions = entries.whereType<ExpressionEntry>().toList();
          _loadingExpressions = false;
          _expressionsLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _expressions = [];
          _loadingExpressions = false;
          _expressionsLoaded = true;
        });
      }
    }
  }

  void _toggleAnimationView() {
    setState(() {
      _showAnimation = !_showAnimation;
    });
  }

  void _copyKanjiToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.kanji.literal));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied "${widget.kanji.literal}" to clipboard'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16.0),
        ),
      );
    }
  }

  void _copyRadicalsToClipboard() async {
    final radicals = _getRadicals();
    if (radicals.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: radicals));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied radicals "$radicals" to clipboard'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16.0),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: widget.selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        border: widget.selected
            ? Border.all(color: colorScheme.primary, width: 2.0)
            : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: _showAnimation
            ? _buildAnimationView(context)
            : _buildNormalView(context),
      ),
    );
  }

  Widget _buildNormalView(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;

        if (isWideScreen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kanji character with enhanced interaction
              _buildInteractiveKanjiCharacter(context),
              const SizedBox(width: 16.0),

              // Kanji details
              Expanded(flex: 2, child: _buildKanjiDetails(context, showCompactExamples: false)),

              // Expression examples for wide screen
              if (_expressions != null && _expressions!.isNotEmpty)
                Expanded(flex: 1, child: _buildExpressionsDetailedView(context)),
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kanji character with enhanced interaction
              _buildInteractiveKanjiCharacter(context),
              const SizedBox(width: 16.0),

              // Kanji details
              Expanded(child: _buildKanjiDetails(context, showCompactExamples: true)),
            ],
          );
        }
      },
    );
  }

  Widget _buildAnimationView(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header with close button
        Row(
          children: [
            IconButton(
              onPressed: _toggleAnimationView,
              icon: const Icon(Icons.close),
              iconSize: 20.0,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 8.0),
            Text(
              'How to write ${widget.kanji.literal}',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),

        // Animation container
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: KanjiDrawingAnimation(widget.kanji.literal, speed: 50),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveKanjiCharacter(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _copyKanjiToClipboard,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: widget.selected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: KanjiCharacterWidget(
                kanji: widget.kanji,
                onTap: widget.onTapLeading,
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                  color: widget.selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanjiDetails(BuildContext context, {required bool showCompactExamples}) {
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
              onTap: _toggleAnimationView,
              onLongPress: null,
            ),
            const SizedBox(width: 8.0),
            if (_getRadicals().isNotEmpty)
              _buildSelectableInfoChip(
                context,
                _getRadicals(),
                Icons.category,
                theme.colorScheme.tertiary,
                onLongPress: _copyRadicalsToClipboard,
              ),
          ],
        ),
        const SizedBox(height: 12.0),

        // Readings section
        if (_getOnReading().isNotEmpty || _getKunReading().isNotEmpty)
          _buildReadingsSection(context),

        const SizedBox(height: 8.0),

        // Meanings section
        if (_getMeaning().isNotEmpty) _buildMeaningSection(context),

        // Expressions section for mobile/narrow screens only
        if (showCompactExamples) ...[
          const SizedBox(height: 8.0),
          _buildExpressionsSection(context),
        ],
      ],
    );
  }

  Widget _buildExpressionsSection(BuildContext context) {
    final theme = Theme.of(context);

    if (_loadingExpressions) {
      return Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16.0,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8.0),
          SizedBox(
            height: 12.0,
            width: 12.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8.0),
          Text(
            'Loading examples...',
            style: TextStyle(
              fontSize: 12.0,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    if (_expressions == null || _expressions!.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if no expressions
    }

    return Row(
      children: [
        Icon(
          Icons.lightbulb_outline,
          size: 16.0,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8.0),
        TextButton(
          onPressed: () => _showAllExpressionsDialog(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'See examples',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 4.0),
              Icon(
                Icons.arrow_forward_ios,
                size: 12.0,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpressionsDetailedView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._expressions!.take(3).map((expression) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildExpressionDetailedItem(context, expression),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExpressionDetailedItem(BuildContext context, ExpressionEntry expression) {
    final theme = Theme.of(context);
    final reading = expression.reading.isNotEmpty ? expression.reading.first : '';
    final meanings = expression.senses
        .expand((sense) => sense.glosses)
        .take(1)
        .join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            reading,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          if (meanings.isNotEmpty) ...[
            const SizedBox(height: 2.0),
            Text(
              meanings,
              style: TextStyle(
                fontSize: 10.0,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              softWrap: true,
            ),
          ],
        ],
      ),
    );
  }

  void _showAllExpressionsDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: theme.colorScheme.primary,
                size: 20.0,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Examples with "${widget.kanji.literal}"',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: theme.colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._expressions!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final expression = entry.value;

                    return Padding(
                      padding: EdgeInsets.only(bottom: index < _expressions!.length - 1 ? 16.0 : 0.0),
                      child: _buildDialogExpressionItem(context, expression),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogExpressionItem(BuildContext context, ExpressionEntry expression) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Readings section
          if (expression.reading.isNotEmpty) ...[
            Text(
              'Reading${expression.reading.length > 1 ? 's' : ''}:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4.0),
            ...expression.reading.map((reading) => Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
              child: Text(
                reading,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            )),
          ],

          // Spacing between readings and meanings
          if (expression.reading.isNotEmpty && expression.senses.isNotEmpty)
            const SizedBox(height: 8.0),

          // Meanings section
          if (expression.senses.isNotEmpty) ...[
            Text(
              'Meaning${expression.senses.length > 1 ? 's' : ''}:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4.0),
            ...expression.senses.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final sense = entry.value;
              final glosses = sense.glosses.join(', ');

              if (glosses.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                child: Text(
                  expression.senses.length > 1 ? '$index. $glosses' : glosses,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: theme.colorScheme.onSurface,
                    height: 1.2,
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectableInfoChip(
      BuildContext context,
      String text,
      IconData icon,
      Color color, {
        VoidCallback? onLongPress,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: color),
          const SizedBox(width: 4.0),
          GestureDetector(
            onLongPress: onLongPress,
            child: SelectableText(
              text,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
      BuildContext context,
      String text,
      IconData icon,
      Color color, {
        VoidCallback? onTap,
        VoidCallback? onLongPress,
      }) {
    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

    if (onTap != null || onLongPress != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: chip,
        ),
      );
    }

    return chip;
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

  Widget _buildReadingRow(
      BuildContext context,
      String label,
      String reading,
      Color color,
      ) {
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
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
    final count = widget.kanji.strokeCount;
    return '$count stroke${count > 1 ? 's' : ''}';
  }

  String _getOnReading() {
    return widget.kanji.on?.join('・') ?? '';
  }

  String _getKunReading() {
    return widget.kanji.kun?.join('・') ?? '';
  }

  String _getRadicals() {
    return widget.kanji.radicals?.join('') ?? '';
  }

  String _getMeaning() {
    return widget.kanji.meanings?.join(', ') ?? '';
  }
}