import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ruby_text/ruby_text.dart';
import 'package:sqflite/sqflite.dart';

import '../kanji.dart';
import '../queries.dart';
import '../search.dart';
import '../string_utils.dart' show kanaKit;
import 'kanji_widget.dart';

class ResultsWidget extends StatefulWidget {
  final Database? _dbKanji;
  final Search? _search;
  final Function _onEndReached;
  final bool? _isLoading;

  const ResultsWidget(this._dbKanji, this._search, this._onEndReached, this._isLoading, {Key? key})
      : super(key: key);

  @override
  State<ResultsWidget> createState() => _ResultsWidgetState();
}

class _ResultsWidgetState extends State<ResultsWidget> {
  ScrollController? _scrollController;
  TextStyle? _styleFieldInformation;

  @override
  initState() {
    _scrollController = ScrollController();
    _scrollController!.addListener(_scrollListener);

    _styleFieldInformation =
        const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blue);

    super.initState();
  }

  @override
  void dispose() {
    _scrollController!.dispose();
    super.dispose();
  }

  _scrollListener() {
    if (_scrollController!.offset >= _scrollController!.position.maxScrollExtent &&
        !_scrollController!.position.outOfRange &&
        !widget._isLoading!) {
      widget._onEndReached();
    }
  }

  Widget _buildResultKanji(result) {
    return KanjiWidget(result.kanji);
  }

  Widget _buildResultExpression(searchResult) {
    var japaneseReading = searchResult.kanji == null
        ? Text(
            searchResult.reading,
            style: const TextStyle(fontSize: 24.0),
          )
        : RubyText(
            [
              RubyTextData(
                searchResult.kanji,
                ruby: searchResult.reading ?? '',
                style: const TextStyle(fontSize: 18.0),
              )
            ],
          );

    //group glosses by pos
    Map sensesGroupedByPosses = <String?, List<Sense>>{};
    searchResult.senses.forEach((sense) {
      String? posString = sense.posses.join(', ');
      if (!sensesGroupedByPosses.containsKey(posString)) {
        sensesGroupedByPosses[posString] = <Sense>[];
      }
      sensesGroupedByPosses[posString].add(sense);
    });

    return ListTile(
        title: Column(
      children: <Widget>[
        InkWell(
          onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                    title: const Text('Kanji'),
                    content: _kanjiDialogContent(searchResult.kanji),
                  )),
          onDoubleTap: () =>
              Clipboard.setData(ClipboardData(text: searchResult.kanji ?? searchResult.reading)),
          child: japaneseReading,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sensesGroupedByPosses.entries.map((glossesGroupedByPos) {
              String? pos = glossesGroupedByPos.key;
              List<Sense> senses = glossesGroupedByPos.value;

              return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: RichText(
                    text: TextSpan(
                        text: '• $pos\n',
                        style: _styleFieldInformation,
                        children: List.generate(glossesGroupedByPos.value.length, (i) {
                          return TextSpan(
                              text: senses[i].glosses.join(","),
                              style: Theme.of(context).textTheme.bodyText2,
                              children: [
                                TextSpan(
                                    text: " ${senses[i].dial.join(",")}",
                                    style: _styleFieldInformation),
                                TextSpan(
                                    text: " ${senses[i].misc.join(",")}",
                                    style: _styleFieldInformation),
                                const TextSpan(text: "\n")
                              ]);
                        })),
                  ));
            }).toList(),
          ),
        ),
      ],
    ));
  }

  Widget _kanjiDialogContent(String kanjiReading) {
    /// filter reading to keep only kanji characters
    List<String> kanjis = [];
    for (int i = 0; i < kanjiReading.length; i++) {
      if (kanaKit.isKanji(kanjiReading[i])) {
        kanjis.add(kanjiReading[i]);
      }
    }

    return SizedBox(
      width: double.maxFinite,
      child: FutureBuilder<List<Kanji>>(
          future: getKanjiFromCharacters(widget._dbKanji!, kanjis),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data == null) {
                return const ListTile(title: Text('Cannot get kanji details'));
              } else {
                return ListView.separated(
                    shrinkWrap: true,
                    separatorBuilder: (context, index) {
                      return const Divider();
                    },
                    itemCount: snapshot.data!.length,
                    itemBuilder: (BuildContext context, int index) {
                      return KanjiWidget(snapshot.data!
                          .firstWhere((kanji) => kanji.character == kanjiReading[index]));
                    });
              }
            } else if (snapshot.hasError) {
              return ListTile(title: Text("${snapshot.error}"));
            }

            return ListView(
              shrinkWrap: true,
              children: const [ListTile(title: Center(child: CircularProgressIndicator()))],
            );
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: widget._isLoading!
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                separatorBuilder: (context, index) {
                  return const Divider();
                },
                controller: _scrollController,
                itemCount: widget._search!.searchResults.length,
                itemBuilder: (BuildContext context, int index) {
                  if (widget._search!.searchResults[index] is KanjiEntry) {
                    KanjiEntry searchResult = widget._search!.searchResults[index] as KanjiEntry;
                    return _buildResultKanji(searchResult);
                  } else {
                    return _buildResultExpression(widget._search!.searchResults[index]);
                  }
                }));
  }
}
