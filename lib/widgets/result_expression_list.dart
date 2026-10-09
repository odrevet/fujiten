import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ruby_text/ruby_text.dart';

import '../cubits/favorites_cubit.dart';
import '../cubits/search_options_cubit.dart';
import '../models/entry.dart';
import '../models/favorite.dart';
import '../models/sense.dart';
import '../string_utils.dart' show kanaKit;
import 'favorites/favorite_picker_dialog.dart';
import 'kanji_dialog.dart';

Widget buildRubyText(String mainReading) {
  List<String> parts = mainReading.split(' ');
  List<RubyTextData> rubyTextDataList = [];

  for (String part in parts) {
    if (part.contains(':')) {
      List<String> kanjiReading = part.split(':');
      if (kanjiReading.length == 2) {
        rubyTextDataList.add(
          RubyTextData(kanjiReading[0], ruby: kanjiReading[1]),
        );
      } else {
        rubyTextDataList.add(RubyTextData(part));
      }
    } else {
      rubyTextDataList.add(RubyTextData(part));
    }

    if (part != parts.last) {
      rubyTextDataList.add(RubyTextData(' '));
    }
  }

  return SelectionArea(
    child: RubyText(
      rubyTextDataList,
      style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.w500),
      rubyStyle: const TextStyle(fontSize: 12.0),
      textAlign: TextAlign.center,
    ),
  );
}

class ResultExpressionList extends StatefulWidget {
  final ExpressionEntry searchResult;

  const ResultExpressionList({required this.searchResult, super.key});

  @override
  State<ResultExpressionList> createState() => _ResultExpressionListState();
}

class _ResultExpressionListState extends State<ResultExpressionList> {
  late TextStyle _styleFieldInformation;
  late TextStyle _posStyle;

  @override
  initState() {
    super.initState();
    _styleFieldInformation = const TextStyle(
      fontSize: 11,
      fontStyle: FontStyle.italic,
      color: Colors.grey,
    );
    _posStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.blueGrey,
    );
  }

  List<String> _extractKanjiFromReading(String reading) {
    List<String> literals = [];
    for (int i = 0; i < reading.length; i++) {
      if (kanaKit.isKanji(reading[i])) {
        literals.add(reading[i]);
      }
    }
    return literals;
  }

  void _showKanjiDialog(List<String> literals) {
    if (literals.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Center(child: Text('Details for ${literals.join()}')),
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
        content: KanjiDialog(literals: literals),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _addToFavorites() {
    showDialog(
      context: context,
      builder: (context) => FavoritePickerDialog(
        favorite: Favorite.fromExpression(widget.searchResult),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    final favorite = Favorite.fromExpression(widget.searchResult);
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, state) {
        final isFavorite = state.isFavoriteAnywhere(favorite.id);
        return IconButton(
          onPressed: _addToFavorites,
          icon: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite ? Colors.amber : null,
          ),
          tooltip: 'Add to favorites',
        );
      },
    );
  }

  Widget _buildMainReading() {
    if (widget.searchResult.reading.isEmpty) return const SizedBox.shrink();

    final mainReading = widget.searchResult.reading[0];
    final literals = _extractKanjiFromReading(mainReading);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Stack(
        children: [
          Center(
            child: GestureDetector(
              onLongPress: () => _copyToClipboard(mainReading),
              child: buildRubyText(mainReading),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFavoriteButton(),
                if (literals.isNotEmpty)
                  IconButton(
                    onPressed: () => _showKanjiDialog(literals),
                    icon: const Icon(Icons.info_outline),
                    tooltip: 'Show Kanji',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAlternativeReadings() {
    if (widget.searchResult.reading.length <= 1) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8.0,
        runSpacing: 4.0,
        children: widget.searchResult.reading.skip(1).map<Widget>((reading) {
          final literals = _extractKanjiFromReading(reading);

          return GestureDetector(
            onTap: () => _showKanjiDialog(literals),
            onLongPress: () => _copyToClipboard(reading),
            child: SelectableText(reading),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReferences() {
    final hasXref = widget.searchResult.xref.isNotEmpty;
    final hasAnt = widget.searchResult.ant.isNotEmpty;

    if (!hasXref && !hasAnt) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8.0,
        runSpacing: 4.0,
        children: [
          ...widget.searchResult.xref.map<Widget>((reference) {
            final literals = _extractKanjiFromReading(reference);

            return GestureDetector(
              onTap: () => _showKanjiDialog(literals),
              onLongPress: () => _copyToClipboard(reference),
              child: SelectableText(
                reference,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
          ...widget.searchResult.ant.map<Widget>((reference) {
            final literals = _extractKanjiFromReading(reference);

            return GestureDetector(
              onTap: () => _showKanjiDialog(literals),
              onLongPress: () => _copyToClipboard(reference),
              child: SelectableText(
                reference,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _infoTag(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.1),
      ),
      child: SelectableText(
        text,
        style: _styleFieldInformation.copyWith(color: color[700]),
      ),
    );
  }

  Widget _buildGlosses(Sense sense) {
    final showLangTags =
        context.read<SearchOptionsCubit>().state.selectedLangsExpression.length >
            1;

    final groups = <String, List<String>>{};
    for (final gloss in sense.glosses) {
      groups.putIfAbsent(gloss.lang, () => []).add(gloss.content);
    }

    final glossStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(height: 1.3);

    final extraTags = <Widget>[
      if (sense.dial.isNotEmpty) _infoTag(sense.dial.join(', '), Colors.orange),
      if (sense.misc.isNotEmpty) _infoTag(sense.misc.join(', '), Colors.purple),
      if (sense.fields.isNotEmpty)
        _infoTag(sense.fields.join(', '), Colors.green),
    ];

    final entries = groups.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List<Widget>.generate(entries.length, (i) {
        final entry = entries[i];
        final isLast = i == entries.length - 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 2.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...entry.value.map<Widget>(
                    (content) => SelectableText(content, style: glossStyle),
              ),
              if (showLangTags && entry.key.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 1.0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.teal.withValues(alpha: 0.1),
                  ),
                  child: SelectableText(
                    entry.key,
                    style: _styleFieldInformation.copyWith(
                      color: Colors.teal[700],
                    ),
                  ),
                ),
              if (isLast) ...extraTags,
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSenseGroup(String? pos, List<Sense> senses) {
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
          if (pos != null && pos.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SelectableText(pos, style: _posStyle),
            ),
          ...senses.asMap().entries.map((entry) {
            final index = entry.key;
            final sense = entry.value;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < senses.length - 1 ? 8.0 : 0,
                left: 8.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (senses.length > 1)
                    Container(
                      margin: const EdgeInsets.only(top: 2.0, right: 8.0),
                      child: Text(
                        '${index + 1}.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Expanded(child: _buildGlosses(sense)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String?, List<Sense>> sensesGroupedByPosses = <String?, List<Sense>>{};
    for (var sense in widget.searchResult.senses) {
      String? posString = sense.posses.join(', ');
      if (!sensesGroupedByPosses.containsKey(posString)) {
        sensesGroupedByPosses[posString] = <Sense>[];
      }
      sensesGroupedByPosses[posString]?.add(sense);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainReading(),
            buildAlternativeReadings(),
            _buildReferences(),
            ...sensesGroupedByPosses.entries.map((entry) {
              return _buildSenseGroup(entry.key, entry.value);
            }),
          ],
        ),
      ),
    );
  }
}