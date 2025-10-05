import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_kanjivg/flutter_kanjivg.dart';

import '../cubits/expression_cubit.dart';
import '../cubits/search_options_cubit.dart';
import '../models/entry.dart'; // Add your entry model import
import '../models/kanji.dart';
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

class _KanjiListTileState extends State<KanjiListTile>
    with TickerProviderStateMixin {
  bool _showAnimation = false;
  List<ExpressionEntry>? _expressions; // Store the fetched expressions
  bool _loadingExpressions = false;
  bool _expressionsLoaded = false;

  late KanjiController _controller;
  KvgData? _data;

  @override
  void initState() {
    super.initState();
    _loadKanjiSvg();
    _loadExpressions();
  }

  Future<void> _loadKanjiSvg() async {
    final parser = const KanjiParser();
    final codepoint = widget.kanji.literal
        .codeUnitAt(0)
        .toRadixString(16)
        .padLeft(5, '0');
    final source = await rootBundle.loadString('assets/kanji/$codepoint.svg');
    final data = parser.parse(source);

    setState(() {
      _data = data;
      _controller =
          KanjiController(vsync: this, duration: const Duration(seconds: 5))
            ..load(data)
            ..repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimationView(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _toggleAnimationView,
              icon: const Icon(Icons.close),
              iconSize: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'How to write ${widget.kanji.literal}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: SizedBox.square(
            dimension: 150,
            child: _data == null
                ? const Center(child: CircularProgressIndicator())
                : KanjiCanvas(
                    controller: _controller,
                    size: 150,
                    thickness: 4,
                    color: theme.colorScheme.primary,
                    hintColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadExpressions() async {
    if (_expressionsLoaded) return;

    setState(() {
      _loadingExpressions = true;
    });

    try {
      final expressionCubit = context.read<ExpressionCubit>();
      var wildcard = context.read<SearchOptionsCubit>().state.useRegexp
          ? '.*'
          : '*';
      final entries = await expressionCubit.databaseInterface.search(
        '$wildcard${widget.kanji.literal}$wildcard',
        3,
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
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1),
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
          const SnackBar(
            content: Text('Copied to clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: widget.selected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2.0,
              )
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: widget.selected
              ? Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _showAnimation
              ? _buildAnimationView(context)
              : _buildNormalView(context),
        ),
      ),
    );
  }

  Widget _buildNormalView(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;

        if (isWideScreen) {
          // Wide screen layout - kanji on left side
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kanji character with enhanced interaction
              _buildInteractiveKanjiCharacter(context),
              const SizedBox(width: 16.0),

              // Kanji details
              Expanded(
                flex: 2,
                child: _buildKanjiDetails(context, showCompactExamples: false),
              ),

              // Expression examples for wide screen
              if (_expressions != null && _expressions!.isNotEmpty)
                Expanded(
                  flex: 1,
                  child: _buildExpressionsDetailedView(context),
                ),
            ],
          );
        } else {
          // Small screen layout - kanji as title above content
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kanji character as title
              _buildKanjiTitle(context),
              const SizedBox(height: 12.0),

              // Kanji details
              _buildKanjiDetails(context, showCompactExamples: true),
            ],
          );
        }
      },
    );
  }

  Widget _buildKanjiTitle(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: GestureDetector(
        onTap: _toggleAnimationView,
        onLongPress: _copyKanjiToClipboard,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: KanjiCharacterWidget(
            kanji: widget.kanji,
            onTap: widget.onTapLeading,
            style: TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
              color: widget.selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveKanjiCharacter(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _toggleAnimationView,
      onLongPress: _copyKanjiToClipboard,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: Center(
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
        ),
      ),
    );
  }

  Widget _buildKanjiDetails(
    BuildContext context, {
    required bool showCompactExamples,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Readings, meanings, stroke count, and radicals sections (grouped like senses)
        _buildKanjiInfoGroup(context),

        // Expressions section for mobile/narrow screens only
        if (showCompactExamples) ...[
          const SizedBox(height: 8.0),
          _buildExpressionsSection(context),
        ],
      ],
    );
  }

  Widget _buildKanjiInfoGroup(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.withValues(alpha: 0.05),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Readings section
          if (_getOnReading().isNotEmpty || _getKunReading().isNotEmpty) ...[
            if (_getOnReading().isNotEmpty)
              _buildReadingRow(
                context,
                'On-yomi',
                _getOnReading(),
                Theme.of(context).colorScheme.primary,
              ),
            if (_getOnReading().isNotEmpty && _getKunReading().isNotEmpty)
              const SizedBox(height: 8.0),
            if (_getKunReading().isNotEmpty)
              _buildReadingRow(
                context,
                'Kun-yomi',
                _getKunReading(),
                Theme.of(context).colorScheme.secondary,
              ),
          ],

          // Stroke count section
          if ((_getOnReading().isNotEmpty || _getKunReading().isNotEmpty))
            const SizedBox(height: 8.0),
          _buildReadingRow(
            context,
            'Strokes',
            '${widget.kanji.strokeCount}',
            Theme.of(context).colorScheme.tertiary,
          ),

          // Radicals section
          if (_getRadicals().isNotEmpty) ...[
            const SizedBox(height: 8.0),
            _buildReadingRow(
              context,
              'Radicals',
              _getRadicals(),
              Theme.of(context).colorScheme.outline,
              onLongPress: _copyRadicalsToClipboard,
            ),
          ],

          // Meanings section
          if (_getMeaning().isNotEmpty) ...[
            const SizedBox(height: 12.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    'Meanings:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    _getMeaning(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.3),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 4.0,
            ),
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

  Widget _buildExpressionDetailedItem(
    BuildContext context,
    ExpressionEntry expression,
  ) {
    final theme = Theme.of(context);
    final reading = expression.reading.isNotEmpty
        ? expression.reading.first
        : '';
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
            softWrap: true,
            overflow: TextOverflow.visible,
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
              overflow: TextOverflow.visible,
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
                  widget.kanji.literal,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                iconSize: 20.0,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
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
                      padding: EdgeInsets.only(
                        bottom: index < _expressions!.length - 1 ? 16.0 : 0.0,
                      ),
                      child: _buildDialogExpressionItem(context, expression),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogExpressionItem(
    BuildContext context,
    ExpressionEntry expression,
  ) {
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
            ...expression.reading.map(
              (reading) => Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                child: Text(
                  reading,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
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

  Widget _buildReadingRow(
    BuildContext context,
    String label,
    String reading,
    Color color, {
    VoidCallback? onLongPress,
  }) {
    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          margin: const EdgeInsets.only(right: 8.0),
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.3),
          ),
        ),
      ],
    );

    if (onLongPress != null) {
      return GestureDetector(onLongPress: onLongPress, child: content);
    }

    return content;
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
