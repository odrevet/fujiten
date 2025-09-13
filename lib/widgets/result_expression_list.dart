import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/entry.dart';
import '../models/sense.dart';
import '../string_utils.dart' show kanaKit;
import 'kanji_dialog.dart';

class ResultExpressionList extends StatefulWidget {
  final ExpressionEntry searchResult;

  const ResultExpressionList({required this.searchResult, super.key});

  @override
  State<ResultExpressionList> createState() => _ResultExpressionListState();
}

class _ResultExpressionListState extends State<ResultExpressionList> {
  late TextStyle _styleFieldInformation;
  late TextStyle _posStyle;
  late TextStyle _referenceStyle;

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
    _referenceStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.indigo,
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
      builder: (_) => AlertDialog(
        title: const Center(child: Text('Kanji')),
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

  Widget _buildMainReading() {
    if (widget.searchResult.reading.isEmpty) return const SizedBox.shrink();

    final mainReading = widget.searchResult.reading[0];
    final literals = _extractKanjiFromReading(mainReading);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () => _showKanjiDialog(literals),
        onLongPress: () => _copyToClipboard(mainReading),
        child: Text(
          mainReading,
          style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
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
            child: Text(reading),
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
              child: Text(
                reference,
                style: TextStyle(
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
              child: Text(
                reference,
                style: TextStyle(
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

  Widget _buildSenseGroup(String? pos, List<Sense> senses) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.withValues(alpha:0.05),
        border: Border.all(color: Colors.grey.withValues(alpha:0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pos != null && pos.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(pos, style: _posStyle),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sense.glosses.join(', '),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.3),
                        ),
                        if (sense.dial.isNotEmpty || sense.misc.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Wrap(
                              spacing: 8.0,
                              children: [
                                if (sense.dial.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                      vertical: 2.0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.orange.withValues(alpha:0.1),
                                    ),
                                    child: Text(
                                      sense.dial.join(', '),
                                      style: _styleFieldInformation.copyWith(
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ),
                                if (sense.misc.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                      vertical: 2.0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.purple.withValues(alpha:0.1),
                                    ),
                                    child: Text(
                                      sense.misc.join(', '),
                                      style: _styleFieldInformation.copyWith(
                                        color: Colors.purple[700],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
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
    // Group senses by part of speech
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