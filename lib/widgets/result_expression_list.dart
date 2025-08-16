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
  TextStyle? _styleFieldInformation;

  @override
  initState() {
    _styleFieldInformation = const TextStyle(
      fontSize: 12,
      fontStyle: FontStyle.italic,
      color: Colors.blue,
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //group glosses by pos
    Map sensesGroupedByPosses = <String?, List<Sense>>{};
    for (var sense in widget.searchResult.senses) {
      String? posString = sense.posses.join(', ');
      if (!sensesGroupedByPosses.containsKey(posString)) {
        sensesGroupedByPosses[posString] = <Sense>[];
      }
      sensesGroupedByPosses[posString].add(sense);
    }

    /// filter reading to keep only kanji characters
    List<String> literals = [];
    for (int i = 0; i < widget.searchResult.reading[0].length; i++) {
      if (kanaKit.isKanji(widget.searchResult.reading[0][i])) {
        literals.add(widget.searchResult.reading[0][i]);
      }
    }

    return ListTile(
      title: Column(
        children: <Widget>[
          InkWell(
            onTap: () => literals.isNotEmpty
                ? showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Center(child: Text('Kanji')),
                      content: KanjiDialog(literals: literals),
                    ),
                  )
                : null,
            onDoubleTap: () => Clipboard.setData(
              ClipboardData(text: widget.searchResult.reading.toString()),
            ),
            child: Text(
              widget.searchResult.reading.isNotEmpty
                  ? widget.searchResult.reading[0]
                  : '',
              style: const TextStyle(fontSize: 20.0),
            ),
          ),
          // Other japanese reading forms
          Wrap(
            alignment: WrapAlignment.center,
            children: widget.searchResult.reading.skip(1).map<Widget>((
              reading,
            ) {
              List<String> literals = [];
              for (int i = 0; i < reading.length; i++) {
                if (kanaKit.isKanji(reading[i])) {
                  literals.add(reading[i]);
                }
              }
              return InkWell(
                onTap: () => literals.isNotEmpty
                    ? showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Center(child: Text('Kanji')),
                          content: KanjiDialog(literals: literals),
                        ),
                      )
                    : null,
                child: Text(
                  " $reading ",
                  style: const TextStyle(fontSize: 16.0),
                ),
              );
            }).toList(),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sensesGroupedByPosses.entries.map((
                glossesGroupedByPos,
              ) {
                String? pos = glossesGroupedByPos.key;
                List<Sense> senses = glossesGroupedByPos.value;

                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: RichText(
                    text: TextSpan(
                      text: '$pos\n',
                      style: _styleFieldInformation,
                      children: List.generate(
                        glossesGroupedByPos.value.length,
                        (i) {
                          return TextSpan(
                            text: '• ${senses[i].glosses.join(",")}',
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: " ${senses[i].dial.join(",")}",
                                style: _styleFieldInformation,
                              ),
                              TextSpan(
                                text: " ${senses[i].misc.join(",")}",
                                style: _styleFieldInformation,
                              ),
                              const TextSpan(text: "\n"),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
