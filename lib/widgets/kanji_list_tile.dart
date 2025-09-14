import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kanji_drawing_animation/kanji_drawing_animation.dart';

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
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _toggleAnimationView() {
    setState(() {
      _showAnimation = !_showAnimation;
    });

    if (_showAnimation) {
      _slideController.forward();
    } else {
      _slideController.reverse();
    }
  }

  void _copyToClipboard() async {
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16.0),
            child: _showAnimation
                ? _buildAnimationView(context)
                : _buildNormalView(context),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalView(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kanji character with enhanced interaction
        _buildInteractiveKanjiCharacter(context),
        const SizedBox(width: 16.0),

        // Kanji details
        Expanded(child: _buildKanjiDetails(context)),
      ],
    );
  }

  Widget _buildAnimationView(BuildContext context) {
    final theme = Theme.of(context);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Column(
        children: [
          // Header with close button
          Row(
            children: [
              Icon(
                Icons.brush,
                color: theme.colorScheme.primary,
                size: 20.0,
              ),
              const SizedBox(width: 8.0),
              Text(
                'Drawing Animation',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _toggleAnimationView,
                icon: const Icon(Icons.close),
                iconSize: 20.0,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
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
              child: KanjiDrawingAnimation(widget.kanji.literal),
            ),
          ),

          const SizedBox(height: 12.0),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                context,
                'Copy',
                Icons.copy,
                _copyToClipboard,
                theme.colorScheme.secondary,
              ),
              _buildActionButton(
                context,
                'Details',
                Icons.info_outline,
                _toggleAnimationView,
                theme.colorScheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      String label,
      IconData icon,
      VoidCallback onPressed,
      Color color,
      ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18.0),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.1),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _buildInteractiveKanjiCharacter(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _toggleAnimationView,
      onLongPress: _copyToClipboard,
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
            // Subtle animation indicator
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow,
                  size: 8.0,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
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
        if (_getMeaning().isNotEmpty) _buildMeaningSection(context),
      ],
    );
  }

  Widget _buildInfoChip(
      BuildContext context,
      String text,
      IconData icon,
      Color color,
      ) {
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