import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ruby_text/ruby_text.dart';

import '../models/entry.dart';
import '../models/inflection.dart';
import '../models/sense.dart';
import '../string_utils.dart' show kanaKit;
import 'kanji_dialog.dart';

Widget buildRubyText(String mainReading) {
  // Split the string by spaces or other delimiters to handle multiple words/phrases
  List<String> parts = mainReading.split(' ');
  List<RubyTextData> rubyTextDataList = [];

  for (String part in parts) {
    if (part.contains(':')) {
      // Split by colon - format is kanji:reading
      List<String> kanjiReading = part.split(':');
      if (kanjiReading.length == 2) {
        rubyTextDataList.add(
          RubyTextData(
            kanjiReading[0], // kanji
            ruby: kanjiReading[1], // reading
          ),
        );
      } else {
        // If format is incorrect, treat as plain text
        rubyTextDataList.add(RubyTextData(part));
      }
    } else {
      // No colon, treat as plain text
      rubyTextDataList.add(RubyTextData(part));
    }

    // Add space between parts (except for the last part)
    if (part != parts.last) {
      rubyTextDataList.add(RubyTextData(' '));
    }
  }

  return SelectionArea(
    child: RubyText(
      rubyTextDataList,
      style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.w500),
      rubyStyle: const TextStyle(fontSize: 12.0), // Smaller font for ruby text
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

  Widget _buildMainReading() {
    if (widget.searchResult.reading.isEmpty) return const SizedBox.shrink();

    final mainReading = widget.searchResult.reading[0];
    final literals = _extractKanjiFromReading(mainReading);

    final entry = widget.searchResult;
    final isVerb = entry.senses.any(
      (s) =>
          s.posses.contains("v1") ||
          s.posses.contains("vt") ||
          s.posses.contains("v5s"),
    );

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
                if (isVerb)
                  IconButton(
                    onPressed: () => _showInflectionDialog(
                      mainReading.contains(':')
                          ? mainReading.split(':').first
                          : mainReading,
                    ),
                    icon: const Icon(Icons.list_alt_outlined),
                    tooltip: 'Show Inflection',
                  ),
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

  void _showInflectionDialog(String reading) {
    final stem = reading.substring(0, reading.length - 1);
    final ending = reading.substring(reading.length - 1);
    final inflections = JapaneseVerbInflector.getAllInflections(stem, ending);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Inflections for $reading",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Table(
                        border: TableBorder.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        columnWidths: const {
                          0: IntrinsicColumnWidth(),
                          1: FlexColumnWidth(),
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: inflections.entries.map((e) {
                          final inflected = e.value;

                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  JapaneseVerbInflector.getInflectionLabel(e.key)!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(inflected),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
              child: SelectableText(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          sense.glosses.join(', '),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.3),
                        ),
                        if (sense.dial.isNotEmpty ||
                            sense.misc.isNotEmpty ||
                            sense.fields.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              // Added for better vertical spacing
                              children: [
                                if (sense.dial.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                      vertical: 2.0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.orange.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                    child: SelectableText(
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
                                      color: Colors.purple.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                    child: SelectableText(
                                      sense.misc.join(', '),
                                      style: _styleFieldInformation.copyWith(
                                        color: Colors.purple[700],
                                      ),
                                    ),
                                  ),
                                if (sense.fields.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                      vertical: 2.0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.green.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                    child: SelectableText(
                                      sense.fields.join(', '),
                                      style: _styleFieldInformation.copyWith(
                                        color: Colors.green[700],
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
