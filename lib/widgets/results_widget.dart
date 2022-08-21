import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/cubits/search_cubit.dart';
import 'package:fujiten/services/database_interface_kanji.dart';

import '../models/entry.dart';
import '../models/kanji.dart';
import '../models/search.dart';
import '../models/sense.dart';
import '../string_utils.dart' show kanaKit;
import 'kanji_list_tile.dart';

class ResultsWidget extends StatefulWidget {
  final DatabaseInterfaceKanji databaseInterfaceKanji;
  final Function onEndReached;
  final bool isLoading;
  final bool isLoadingNextPage;

  const ResultsWidget(
      this.databaseInterfaceKanji, this.onEndReached, this.isLoading, this.isLoadingNextPage,
      {Key? key})
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
    _scrollController!.addListener(scrollListener);

    _styleFieldInformation =
        const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blue);

    super.initState();
  }

  @override
  void dispose() {
    _scrollController!.dispose();
    super.dispose();
  }

  scrollListener() {
    if (_scrollController!.offset >= _scrollController!.position.maxScrollExtent &&
        !_scrollController!.position.outOfRange &&
        !widget.isLoading &&
        !widget.isLoadingNextPage) {
      widget.onEndReached();
    }
  }

  Widget _buildResultKanji(result) {
    return KanjiListTile(
        kanji: result.kanji,
        onTap: () => Clipboard.setData(ClipboardData(text: result.kanji.literal)));
  }

  Widget _buildResultExpression(searchResult) {
    var japaneseReading = Text(
      '${searchResult.reading.isNotEmpty ? searchResult.reading[0] : ''}\n${searchResult.kanji.isNotEmpty ? searchResult.kanji[0] : ''}',
      style: const TextStyle(fontSize: 20.0),
    );

    var japaneseReadingOtherForms = Text(
      '${searchResult.reading.skip(1).join(", ")} ${searchResult.kanji.skip(1).join(", ")}',
      style: const TextStyle(fontSize: 16.0),
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
                    content: _kanjiDialogContent(searchResult.kanji[0]),
                  )),
          onDoubleTap: () =>
              Clipboard.setData(ClipboardData(text: searchResult.kanji ?? searchResult.reading)),
          child: japaneseReading,
        ),
        japaneseReadingOtherForms,
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
          future: widget.databaseInterfaceKanji.getKanjiFromCharacters(kanjis),
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
                      return KanjiListTile(
                          kanji: snapshot.data!
                              .firstWhere((kanji) => kanji.literal == kanjiReading[index]));
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
    return BlocBuilder<SearchCubit, Search>(builder: (context, search) {
      late Widget child;

      if (search.isLoading && !search.isLoadingNextPage) {
        child = const CircularProgressIndicator();
      } else {
        if (search.searchResults.isEmpty && search.input.isNotEmpty) {
          child = Text("No results for '${search.input}'");
        } else {
          if (search.input.isEmpty) {
            child = const Text("Welcome to Japanese Dictionary Flutter");
          } else {
            child = ListView.separated(
                separatorBuilder: (context, index) {
                  return const Divider();
                },
                controller: _scrollController,
                itemCount: search.searchResults.length,
                itemBuilder: (BuildContext context, int index) {
                  if (search.searchResults[index] is KanjiEntry) {
                    KanjiEntry searchResult = search.searchResults[index] as KanjiEntry;
                    return _buildResultKanji(searchResult);
                  } else {
                    return _buildResultExpression(search.searchResults[index]);
                  }
                });
          }
        }
      }
      return Expanded(child: Center(child: child));
    });
  }
}
