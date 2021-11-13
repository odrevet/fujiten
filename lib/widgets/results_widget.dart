

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ruby_text/ruby_text.dart';
import 'package:sqflite/sqflite.dart';

import '../kanji.dart';
import 'kanji_widget.dart';
import '../lang.dart';
import '../queries.dart';
import '../search.dart';
import '../string_utils.dart' show kanaKit;

class ResultsWidget extends StatefulWidget {
  final Database? _dbKanji;
  final Search? _search;
  final Function _onEndReached;
  final bool? _isLoading;

  ResultsWidget(
      this._dbKanji, this._search, this._onEndReached, this._isLoading);

  @override
  _ResultsWidgetState createState() => _ResultsWidgetState();
}

class _ResultsWidgetState extends State<ResultsWidget> {
  ScrollController? _scrollController;
  TextStyle? _styleFieldInformation;

  @override
  initState() {
    _scrollController = ScrollController();
    _scrollController!.addListener(_scrollListener);

    _styleFieldInformation = TextStyle(
        fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blue);

    super.initState();
  }

  @override
  void dispose() {
    _scrollController!.dispose();
    super.dispose();
  }

  _scrollListener() {
    if (_scrollController!.offset >=
            _scrollController!.position.maxScrollExtent &&
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
            style: TextStyle(fontSize: 26.0),
          )
        : RubyText(
            [
              RubyTextData(
                searchResult.kanji,
                ruby: searchResult.reading ?? '',
                style: TextStyle(fontSize: 26.0),
              )
            ],
          );

    //group glosses by pos
    Map sensesGroupedByPosses = Map<String?, List<Sense>>();
    searchResult.senses.forEach((sense) {
      String? posString = sense.posses.join(', ');
      if (!sensesGroupedByPosses.containsKey(posString))
        sensesGroupedByPosses[posString] = <Sense>[];
      sensesGroupedByPosses[posString].add(sense);
    });

    return ListTile(
        title: Column(
      children: <Widget>[
        InkWell(
          onTap: () =>
              _showDialog(_kanjiDialogContent(searchResult.kanji), context),
          onDoubleTap: () => Clipboard.setData(ClipboardData(
              text: searchResult.kanji == null
                  ? searchResult.reading
                  : searchResult.kanji)),
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
                        children: List.generate(
                            glossesGroupedByPos.value.length, (i) {
                          final lang = Lang(code: senses[i].lang);
                          return TextSpan(
                              text:
                                  '${lang.countryFlag} ${senses[i].glosses} \n',
                              style: Theme.of(context).textTheme.bodyText2);
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

    return FutureBuilder<List<Kanji>>(
        future: getKanjiFromCharacters(this.widget._dbKanji!, kanjis),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data == null)
              return ListTile(title: Text('Cannot get kanji details'));
            else
              return ListView.separated(
                  shrinkWrap: true,
                  separatorBuilder: (context, index) {
                    return Divider();
                  },
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    return KanjiWidget(snapshot.data!.firstWhere(
                        (kanji) => kanji.character == kanjiReading[index]));
                  });
          } else if (snapshot.hasError) {
            return ListTile(title: Text("${snapshot.error}"));
          }

          return ListView(
            children: [
              ListTile(title: Center(child: CircularProgressIndicator()))
            ],
            shrinkWrap: true,
          );
        });
  }

  _showDialog(Widget content, BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          content: content,
          actions: <Widget>[
            TextButton(
              child: Icon(
                Icons.done,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: widget._isLoading!
            ? Center(child: CircularProgressIndicator())
            : ListView.separated(
                separatorBuilder: (context, index) {
                  return Divider();
                },
                controller: _scrollController,
                itemCount: widget._search!.searchResults.length,
                itemBuilder: (BuildContext context, int index) {
                  if (widget._search!.searchResults[index] is KanjiEntry) {
                    KanjiEntry searchResult =
                        widget._search!.searchResults[index] as KanjiEntry;
                    return _buildResultKanji(searchResult);
                  } else {
                    return _buildResultExpression(
                        widget._search!.searchResults[index]);
                  }
                }));
  }
}
